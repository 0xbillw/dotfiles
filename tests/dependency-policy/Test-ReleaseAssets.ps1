[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$PolicyJsonPath,
    [string]$FixturePath,
    [string]$Scenario = 'matching',
    [string]$BaseRef
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }

function Fail-Asset([string]$Class, [string]$Message) { throw "Release asset validation failed [$Class]: $Message" }

if ($BaseRef -and -not $FixturePath -and -not $PolicyJsonPath) {
    & git -C $RepositoryRoot rev-parse --verify $BaseRef *> $null
    if ($LASTEXITCODE -ne 0) { Fail-Asset 'comparison-base' "Revision '$BaseRef' was not found." }
    $changed = @(& git -C $RepositoryRoot diff --name-only "$BaseRef...HEAD" -- .chezmoidata/dependencies.yaml)
    if ($LASTEXITCODE -ne 0) { Fail-Asset 'comparison-base' "Could not compare '$BaseRef...HEAD'." }
    if ($changed.Count -eq 0) {
        Write-Host 'Release asset verification skipped: dependency manifest is unchanged.'
        exit 0
    }
}

$fixture = $null
$targets = @()
if ($FixturePath) {
    $fixtureDocument = Get-Content -LiteralPath $FixturePath -Raw | ConvertFrom-Json
    $fixture = $fixtureDocument.scenarios.$Scenario
    if (-not $fixture) { Fail-Asset 'fixture-invalid' "Unknown fixture scenario '$Scenario'." }
    $targets = @($fixture.targets)
}
else {
    $json = if ($PolicyJsonPath) { Get-Content -LiteralPath $PolicyJsonPath -Raw } else {
        $chezmoi = if ($env:CHEZMOI) { $env:CHEZMOI } else { (Get-Command chezmoi -ErrorAction Stop).Source }
        $rendered = & $chezmoi -S $RepositoryRoot execute-template '{{ .dependencyPolicy | toJson }}'
        if ($LASTEXITCODE -ne 0) { Fail-Asset 'policy-render' 'chezmoi could not render dependencyPolicy.' }
        $rendered
    }
    $policy = $json | ConvertFrom-Json
    foreach ($property in $policy.dependencies.PSObject.Properties) {
        foreach ($targetProperty in $property.Value.targets.PSObject.Properties) {
            if ($targetProperty.Value.strategy -eq 'official-artifact') {
                $targets += [pscustomobject]@{
                    dependency = $property.Name
                    target = $targetProperty.Name
                    url = $targetProperty.Value.url
                    sha256 = $targetProperty.Value.sha256
                }
            }
        }
    }
}

$releaseCache = @{}
$urlDigest = @{}
foreach ($target in $targets) {
    $match = [regex]::Match([string]$target.url, '^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$')
    if (-not $match.Success) { Fail-Asset 'unsupported-host' "$($target.dependency)/$($target.target): $($target.url)" }
    $owner = $match.Groups[1].Value
    $repository = $match.Groups[2].Value
    $tag = [uri]::UnescapeDataString($match.Groups[3].Value)
    $key = "$owner/$repository@$tag"

    if ($urlDigest.ContainsKey([string]$target.url) -and $urlDigest[[string]$target.url] -ne [string]$target.sha256) {
        Fail-Asset 'duplicate-url-conflict' "$($target.url) has multiple declared digests."
    }
    $urlDigest[[string]$target.url] = [string]$target.sha256

    if (-not $releaseCache.ContainsKey($key)) {
        if ($fixture) {
            if (@($fixture.unavailable) -contains $key) { Fail-Asset 'upstream-unavailable' "$key could not be retrieved." }
            $releaseCache[$key] = @($fixture.releases.$key)
        }
        else {
            $endpoint = "https://api.github.com/repos/$owner/$repository/releases/tags/$([uri]::EscapeDataString($tag))"
            try {
                $release = Invoke-RestMethod -Uri $endpoint -Headers @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'dotfiles-dependency-policy' }
                $releaseCache[$key] = @($release.assets)
            }
            catch { Fail-Asset 'upstream-unavailable' "${key}: $($_.Exception.Message)" }
        }
    }

    $asset = @($releaseCache[$key] | Where-Object { $_.browser_download_url -eq $target.url }) | Select-Object -First 1
    if (-not $asset) { Fail-Asset 'asset-missing' "$($target.dependency)/$($target.target): $($target.url)" }
    $published = [string]$asset.digest
    $declaredHash = ([string]$target.sha256).ToLowerInvariant()
    if ($published.StartsWith('sha256:')) {
        $publishedHash = $published.Substring(7).ToLowerInvariant()
    }
    elseif ($fixture) {
        Fail-Asset 'digest-unavailable' "$($target.url) has no fixture SHA-256 digest."
    }
    else {
        $temporary = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-release-asset-' + [guid]::NewGuid().ToString('N'))
        try {
            Invoke-WebRequest -Uri $target.url -OutFile $temporary -Headers @{ 'User-Agent' = 'dotfiles-dependency-policy' }
            $publishedHash = (Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        catch { Fail-Asset 'asset-download' "$($target.url): $($_.Exception.Message)" }
        finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
    }
    if ($publishedHash -ne $declaredHash) {
        Fail-Asset 'digest-mismatch' "$($target.dependency)/$($target.target): declared=$declaredHash published=$publishedHash url=$($target.url)"
    }
}

Write-Host "Release asset metadata valid: $($targets.Count) targets, $($releaseCache.Count) upstream releases."
