# Opciones para mejorar el comportamiento de Zsh
# ~/.zshrc.d/options.zsh

# Añade automáticamente los directorios al historial (dirstack) al usar 'cd'
setopt AUTO_PUSHD

# No añade directorios duplicados a la pila de manera consecutiva
setopt PUSHD_IGNORE_DUPS

# Navega por el historial de directorios de forma silenciosa (sin imprimir la ruta)
setopt PUSHD_SILENT
