set -g fish_greeting ""

if status is-interactive
    # Commands to run in interactive sessions can go here
end

# yazi
function yz
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end
# yazi end

export PATH="$HOME/.local/bin:$PATH"
set -gx TERMCMD kitty

# zoxide
zoxide init --cmd cd fish | source
# zoxide end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME/bin"
# pnpm end

export EDITOR=nvim

alias ls='eza'
alias tree='eza --tree'
alias fetch='fastfetch'
alias fetchs='fastfetch --logo none'
alias gitl="lazygit"
