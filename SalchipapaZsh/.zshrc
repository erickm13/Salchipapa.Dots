#Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi


 export NVM_DIR="$HOME/.nvm"
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion



export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="nanotech"
export PATH="$HOME/.volta/bin:$HOME/.cargo/bin:$PATH"

if [[ $- == *i* ]]; then
    # Commands to run in interactive sessions can go here
fi





alias cd="z"

#Configuraciones de zshconcd

setopt autocd
setopt correct



# Configuraciones para el historial
#HISTFILE=~/.zsh_history
#HISTSIZE=100000
#SAVEHIST=100000
#setopt share_history   # comparte entre sesiones
#setopt hist_ignore_dups
#setopt hist_ignore_space



if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    BREW_BIN="/opt/homebrew/bin"
else
    # Linux
    BREW_BIN="/home/linuxbrew/.linuxbrew/bin"
fi

# Usar la variable BREW_BIN donde se necesite

eval "$($BREW_BIN/brew shellenv)"

source $(dirname $BREW_BIN)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source $(dirname $BREW_BIN)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(dirname $BREW_BIN)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#source $(dirname $BREW_BIN)/share/powerlevel10k/powerlevel10k.zsh-theme

export PROJECT_PATHS="/home/alanbuscaglia/work"
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exlude .git"

WM_VAR="/$ZELLIJ"
# change with ZELLIJ
WM_CMD="zellij"
# change with zellij

function start_if_needed() {
    if [[ $- == *i* ]] && [[ -z "${WM_VAR#/}" ]] && [[ -t 1 ]]; then
        exec $WM_CMD
    fi
}

# alias
alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim $(fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

#plugins
plugins=(
  command-not-found
)

source $ZSH/oh-my-zsh.sh


# --- eza (reemplazo moderno de ls) ---
  # Opciones base
  alias ls="eza --no-permissions --git  --no-time --no-user --icons --group-directories-first"
  alias ll="eza -l --no-permissions -no-time --no-user --icons --group-directories-first"
  alias la="eza -la --no-permissions --no-time --no-user --icons --group-directories-first"
  alias lt="eza -lT --no-permissions --no-time --no-user --icons --group-directories-first"
  alias lt2="eza -lT --no-permissions --no-time --no-user --icons --group-directories-first --level=2"
  alias lt3="eza -lT --no-permissions --no-time --no-user --icons --group-directories-first --level=3"
  alias lt4="eza -lT --no-permissions --no-time --no-user --icons --group-directories-first --level=4"

  # Colores y tamaños legibles
  alias lS="eza -l --no-permissions --sort=size --icons"       # ordenar por tamaño
  alias lD="eza -l --no-permissions --sort=date --icons"       # ordenar por fecha
  alias lg="eza -l --no-permissions --git --icons"
  alias lf="eza -l --git --group-directories-first" #muestra info de permisos


export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Fix para Zellij en WSL: crear runtime dir si no existe
export XDG_RUNTIME_DIR="/tmp/zellij-$UID"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

start_if_needed


# Load Angular CLI autocompletion.
source <(ng completion script)
