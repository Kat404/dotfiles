# config.nu
#
# Installed by:
# version = "0.111.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
# ~/.config/nushell/config.nu

# Importa Plugins Core (Solo si se desea usar plugins nativos)
# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

# Inicializa Carapace (Necesario tener Carapace instalado)
# source $"($nu.cache-dir)/carapace.nu"

# Configuración de Entorno
# => Define a Helix como editor de texto predeterminado
# => Aplicará íconos a cualquier contenido que salga en forma de tabla
# => Aplicará una búsqueda tipo "fuzzy" en forma de tabla en los autocompletados mediante el Tab
$env.config = {
    buffer_editor: "helix"
    hooks: {
        display_output: {
            if ($in | describe | str contains "table") {
                table --icons
            } else {
                table
            }
        }
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }
    menus: [
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0
                max_completion_width: 50
                max_completion_height: 10
                padding: 0
                border: true
                cursor_offset: 0
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 50
                max_description_height: 10
                description_offset: 1
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
    ]
}

# Almacenamos todo el historial de comandos con SQLite 
$env.config.history = {
  file_format: sqlite
  max_size: 1_000_000
  sync_on_enter: true
  isolation: false
}

# Sourcea todos los aliases configurados
source ~/.config/nushell/aliases.nu

# Carga zoxide
source ~/.cache/zoxide/init.nu

# Evita que aparezca el banner de bienvenida al iniciar Nushell
$env.config.show_banner = false

# Inicializar Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
