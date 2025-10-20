# Configuración de Zsh
# ~/.zshrc
# Encargado de cargar todo lo interactivo con la sesión del shell

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lazy-load para antidote y generar el archivo estático solo cuando sea necesario
#zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
#if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
#  (
#    source /path-to-antidote/antidote.zsh
#    antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
#  )
#fi
#source ${zsh_plugins}.zsh

# Crea una configuración asombrosa de Zsh usando los plugins de antidote
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh
antidote load

# Sourcea cualquier cosa en .zshrc.d
for _rc in ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh; do
  # Ignora archivos con tilde
  if [[ $_rc:t != '~'* ]]; then
    source "$_rc"
  fi
done
unset _rc

# To customize prompt, run `p10k configure` or edit .p10k.zsh.
[[ ! -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]] || source ${ZDOTDIR:-$HOME}/.p10k.zsh
