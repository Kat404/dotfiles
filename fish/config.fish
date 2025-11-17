# -----------------------------------------------------------------------------
#                       CONFIGURACIÓN PRINCIPAL DE FISH
#
# Este archivo es el punto de entrada. Su única función es buscar y ejecutar
# todos los archivos de configuración .fish que se encuentren en el directorio
# conf.d y functions.
# -----------------------------------------------------------------------------

# Carga la configuración personal
source $__fish_config_dir/mi-config.fish

# Colores
set fish_color_command blue
set fish_color_param cyan
set fish_color_quote yellow
set fish_color_redirection red
set fish_color_end black

# Inicialización del prompt Starship
starship init fish | source
