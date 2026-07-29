# Familiar navigation shortcuts.
alias l = ls
alias la = ls --all
alias ll = ls --all --long
alias .. = cd ..
alias ... = cd ../..

# Common Git shortcuts.
alias g = git
alias ga = git add
alias gb = git branch
alias gc = git commit
alias gd = git diff
alias gl = git log --oneline --graph --decorate
alias gp = git push
alias gpl = git pull --rebase
alias gs = git status --short --branch
alias gsw = git switch

# Familiar utility shortcuts that preserve Nushell semantics.
alias cls = clear
alias md = mkdir

# Mark SSH sessions launched from WezTerm so the remote shell can safely enable
# terminal-specific prompt features. Extra SSH options may follow the host.
def --wrapped wssh [destination: string, ...ssh_args] {
    ^ssh ...$ssh_args -t $destination "env DOTFILES_TERMINAL=wezterm bash -i"
}

{{ if eq .chezmoi.os "linux" }}
# Bypass the interactive Bash-to-Nushell login bridge when Bash is requested
# explicitly from Nushell. Forward all arguments to the native executable.
def --wrapped bash [...args] {
    with-env { DOTFILES_NO_AUTO_NU: "1" } {
        ^bash ...$args
    }
}
{{ end }}
