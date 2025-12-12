# Configuración de Zsh
# ~/.zshrc
# Encargado de cargar todo lo interactivo con la sesión del shell

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

# Inicialización de Starship
# Descomentar si se va a hacer uso de Starship
# eval "$(starship init zsh)"