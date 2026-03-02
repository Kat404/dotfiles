# -----------------------------------------------------------------------------
#                       CONFIGURACIÓN PRINCIPAL DE FISH
#
# Este archivo es la raíz de Fish. Su única función es buscar y ejecutar
# todos los archivos de configuración .fish que se encuentren en el directorio
# conf.d, tales como: env, functions, aliases y mucho más.
# -----------------------------------------------------------------------------

# Bucle para cargar todos los archivos .fish del directorio conf.d
# El orden se controla con los números al inicio de los nombres (00_, 10_, etc.)
for file in $__fish_config_dir/conf.d/*.fish
    source $file
end

# (Opcional) Mensaje de bienvenida con (o sin) fastfetch
# Si quieres que aparezca al iniciar la terminal, agrega 'fastfetch' (sin las comillas)
# Si prefieres SIN mensaje de bienvenida, deja como está
# function fish_greeting
# end

# Colores
set fish_color_command blue
set fish_color_param cyan
set fish_color_quote yellow
set fish_color_redirection red
set fish_color_end black

# Inicialización de Zoxide
zoxide init fish | source

# Inicialización de Carapace
carapace _carapace fish | source

# Inicialización del prompt Starship
starship init fish | source
