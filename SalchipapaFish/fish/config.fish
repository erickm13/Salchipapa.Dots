if status is-interactive
    # Commands to run in interactive sessions can go here
    # Install Fisher if not installed
    if not functions -q fisher
        curl -sL https://git.io/fisher | source
        fisher install jorgebucaran/fisher
    end

end

# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    set -x PATH $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin $PATH
else if test (uname) = Darwin
    # macOS - check for Apple Silicon vs Intel
    if test -f /opt/homebrew/bin/brew
        # Apple Silicon (M1/M2/M3)
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -f /usr/local/bin/brew
        # Intel Mac
        set BREW_BIN /usr/local/bin/brew
    end
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
else
    # Linux
    set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    set -x PATH $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.config $HOME/.cargo/bin /usr/local/lib/* $PATH
end

# Only eval brew shellenv if brew is installed (not on Termux)
if test $IS_TERMUX -eq 0; and set -q BREW_BIN; and test -f $BREW_BIN
    eval ($BREW_BIN shellenv)
end

# Start tmux/zellij

if not set -q ZELLIJ
    zellij
end

# Initialize tools
command -q starship && starship init fish | source
command -q zoxide  && zoxide init fish | source
command -q atuin   && atuin init fish | source
command -q fzf     && fzf --fish | source

set -x PATH $HOME/.cargo/bin $PATH

# Carapace completions
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if not test -d ~/.config/fish/completions
    mkdir -p ~/.config/fish/completions
end

if not test -f ~/.config/fish/completions/.initialized
    if not test -d ~/.config/fish/completions
        mkdir -p ~/.config/fish/completions
    end
    carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
    touch ~/.config/fish/completions/.initialized
end

carapace _carapace | source

set -g fish_greeting ""

# Enable vi mode
fish_vi_key_bindings

# Set nvim as default editor for opencode and other tools
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons"
alias lt2="eza --tree --icons --level=2"
alias lt3="eza --tree --icons --level=3"
alias lt4="eza --tree --icons --level=4"

# Alias for files and directories
alias ld="eza -lD --icons"
alias lf="eza -la --icons -f"

# Alias order for size and date
# for Date
alias lr="eza -la --icons --sort=modified --reverse"
# for size
alias lS="eza -la --icons --sort=size --reverse"

alias fzfbat='fzf --preview="bat --theme=\"Solarized (dark)\" --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=\"Solarized (dark)\" --color=always {}")'

# Alias to git
alias gs="git status"
alias gp="git push"
alias gl="git log --oneline --graph"
alias gc="git commit -m"

# Obsidian vault sync
alias obs="git -C ~/.config/obsidian add . && git -C ~/.config/obsidian commit -m 'update notes' && git -C ~/.config/obsidian push"

# Alias for navegation
alias win="z /mnt/c/Users/Salchipapa"

# Gentleman theme (backup)
# set -l foreground F3F6F9 normal
# set -l selection 263356 normal
# set -l comment 8394A3 brblack
# set -l red CB7C94 red
# set -l orange DEBA87 orange
# set -l yellow FFE066 yellow
# set -l green B7CC85 green
# set -l purple A3B5D6 purple
# set -l cyan 7AA89F cyan
# set -l pink FF8DD7 magenta
#
# # Syntax Highlighting Colors
# set -g fish_color_normal $foreground
# set -g fish_color_command $cyan
# set -g fish_color_keyword $pink
# set -g fish_color_quote $yellow
# set -g fish_color_redirection $foreground
# set -g fish_color_end $orange
# set -g fish_color_error $red
# set -g fish_color_param $purple
# set -g fish_color_comment $comment
# set -g fish_color_selection --background=$selection
# set -g fish_color_search_match --background=$selection
# set -g fish_color_operator $green
# set -g fish_color_escape $pink
# set -g fish_color_autosuggestion $comment
#
# # Completion Pager Colors
# set -g fish_pager_color_progress $comment
# set -g fish_pager_color_prefix $cyan
# set -g fish_pager_color_completion $foreground
# set -g fish_pager_color_description $comment

# Solarized Osaka theme
set -l foreground 839395
set -l selection 073642
set -l comment 586e75
set -l red db302d
set -l orange c94c16
set -l yellow b28500
set -l green 849900
set -l blue 268bd3
set -l cyan 29a298
set -l magenta d23681

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $blue
set -g fish_color_keyword $magenta
set -g fish_color_quote $green
set -g fish_color_redirection 9eabac
set -g fish_color_end $cyan
set -g fish_color_error $red
set -g fish_color_param $foreground
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $cyan
set -g fish_color_escape $green
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $foreground
set -g fish_pager_color_prefix $blue
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment

# Fix valid path color (no underline)
set -g fish_color_valid_path $blue

# Fix WSL other-writable directories (Windows folders)
set -gx LS_COLORS "di=01;34:ow=01;34:ln=01;36:ex=01;32:*.tar=01;31:*.zip=01;31"
clear
