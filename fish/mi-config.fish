# -----------------------------------------------------------------------------
#                           ARCHIVO DE CARGA DE MÓDULOS
#
# Este archivo ahora se encarga de inicializar los plugins y cargar todos
# los archivos de configuración modulares desde el directorio conf.d.
# -----------------------------------------------------------------------------

# Inicialización del plugin 'done'
source $__fish_config_dir/conf.d/done.fish

# Bucle para cargar todos los archivos .fish del directorio conf.d
# El orden se controla con los números al inicio de los nombres (00_, 10_, etc.)
for file in $__fish_config_dir/conf.d/*.fish
    source $file
end

# (Opcional) Mensaje de bienvenida con (o sin) fastfetch
# Si quieres que aparezca al iniciar la terminal, agrega 'fastfetch' (sin las comillas)
# Si prefieres SIN mensaje de bienvenida, deja como está
function fish_greeting
end
