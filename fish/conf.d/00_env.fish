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

# Configuración del plugin 'done' para notificaciones
# Duración mínima de un comando para notificar (10 segundos) 
set -U __done_min_cmd_duration 10000
# Nivel de urgencia de la notificación (bajo) 
set -U __done_notification_urgency_level low
