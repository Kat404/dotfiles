# Configuración de Zsh
# ~/.zshrc
# Encargado de cargar todo lo interactivo con la sesión del shell

# Performance: compilar bundles automáticamente
zstyle ':antidote:bundle:*' zcompile 'yes'
zstyle ':antidote:static' zcompile 'yes'

# Activar nombres de carpeta legibles
zstyle ':antidote:bundle' use-friendly-names 'on'

# Bootstrap 'Awesome' de alto rendimiento {
# El archivo estático ".zsh_plugins.zsh" solo se regenera cuando cambia el ".zsh_plugins.txt"
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

# Lazy-load Antidote
fpath=(${ZDOTDIR:-~}/.antidote/functions $fpath)
autoload -Uz antidote

# Regenerar solo si el ".txt" es más nuevo que el ".zsh" compilado
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
    antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Sourcea de manera 'Awesome' todo lo anterior ^_^
source ${zsh_plugins}.zsh
# }

# Sourcea cualquier cosa en .zshrc.d
for _rc in ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh; do
  # Ignora archivos con tilde
  if [[ $_rc:t != '~'* ]]; then
    source "$_rc"
  fi
done
unset _rc

# Bun Completions
[ -s "/home/josel/.bun/_bun" ] && source "/home/josel/.bun/_bun"

# Configuración de PATH de Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Configuración de PATH de Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# Configuración de PATH .NET
export DOTNET_ROOT="/usr/share/dotnet"
export PATH="$PATH:$HOME/.dotnet/tools"

# Inicialización de Zoxide
eval "$(zoxide init zsh)"

# Inicialización de Starship
eval "$(starship init zsh)"
