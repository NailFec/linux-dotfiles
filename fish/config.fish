set -g fish_greeting ""

if status is-interactive
    # Commands to run in interactive sessions can go here
end

export PATH="$HOME/.local/bin:$PATH"
set -gx TERMCMD kitty
export EDITOR=nvim

# inits
fzf --fish | source
zoxide init --cmd cd fish | source

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME/bin"
# pnpm end

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

# fzf
# set -gx FZF_CTRL_T_COMMAND "fd --type f --hidden --follow --exclude .git"
# set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%"
# set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
# set -gx FZF_ALT_C_OPTS "--preview 'eza -T --color=always --icons {} | head -200' --preview-window=right:50%"
# set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --info=inline"
# fzf end

alias ls='eza'
alias tree='eza --tree'
alias fetch='fastfetch'
alias fetchs='fastfetch --logo none'
alias gitl="lazygit"
alias bbdown='~/bin/BBDown/BBDown -q "8K 超高清, 1080P 高码率, 1080P 高清" -e "av1,hevc,avc"'
