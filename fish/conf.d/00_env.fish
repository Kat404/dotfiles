# -----------------------------------------------------------------------------
#                   ---> VARIABLES DE ENTORNO Y PATH <---
#
# Aquí se definen variables de entorno y se añaden directorios al PATH del
# sistema para que Fish pueda encontrar los ejecutables.
# -----------------------------------------------------------------------------

# Mejora la visualización de las páginas del manual con 'bat'
set -x MANROFFOPT -c
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Carga configuraciones compatibles desde .fish_profile si existe 
if test -f ~/.fish_profile
    source ~/.fish_profile
end

# Añade el directorio local de binarios al PATH si existe 
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Añadimos todos nuestro ENV Personal según nuestras herramientas & utilidades
set -gx EDITOR helix
set -gx VISUAL helix
set -gx BUN_INSTALL "$HOME/.bun"
set -gx DOTNET_ROOT "/usr/share/dotnet"
set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

# Añadimos a nuestro PATH todos nuestro lenguajes, package manager & utilidades faltantes
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$BUN_INSTALL/bin"
fish_add_path "$HOME/.dotnet/tools"
