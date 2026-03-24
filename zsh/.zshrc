# Configuración de Zsh
# ~/.zshrc
# Encargado de cargar todo lo interactivo con la sesión del shell

# Configuraciones Personales para Antidote
zstyle ':antidote:git' site     'github.com'
zstyle ':antidote:git' protocol 'ssh'
zstyle ':antidote:git' cmd      'git'
zstyle ':antidote:bundle' use-friendly-names 'yes'

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

# Bun Completions (Necesario tener Bun instalado)
# [ -s "/home/josel/.bun/_bun" ] && source "/home/josel/.bun/_bun"

# Configuración de PATH de Bun (Necesario tener Bun instalado)
# export BUN_INSTALL="$HOME/.bun"
# export PATH="$BUN_INSTALL/bin:$PATH"

# Configuración de PATH de Cargo (Necesario tener Cargo instalado)
# export PATH="$HOME/.cargo/bin:$PATH"

# Configuración de PATH .NET (Necesario tener .NET SDK instalado)
# export DOTNET_ROOT="/usr/share/dotnet"
# export PATH="$PATH:$HOME/.dotnet/tools"

# Inicializar Zoxide
eval "$(zoxide init zsh)"

# Inicialización de Starship
eval "$(starship init zsh)"
