set -g fish_greeting ""

if status is-interactive
    # Commands to run in interactive sessions can go here
end

function yz
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

alias ls='eza'
alias tree='eza --tree'
alias fetch='fastfetch'
alias fetchs='fastfetch --logo none'

export PATH="$HOME/.local/bin:$PATH"
set -gx TERMCMD kitty
