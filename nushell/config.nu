# config.nu
#
# Installed by:
# version = "0.111.0"
#
# ~/.config/nushell/config.nu

# ❯ Importa Plugins Core {
const NU_PLUGIN_DIRS = [
  ($nu.current-exe | path dirname)
  ...$NU_PLUGIN_DIRS
]
# }

# ❯ Inicializa Carapace
source $"($nu.cache-dir)/carapace.nu"

# ❯ Configuración de Entorno {
# => Define a Helix como editor de texto predeterminado
# => Aplicará íconos a cualquier contenido que salga en forma de tabla
# => Aplicará una búsqueda tipo "fuzzy" en forma de tabla en los autocompletados nativos mediante el Tab
$env.config = {
    buffer_editor: "helix"
    edit_mode: vi
    render_right_prompt_on_last_line: false
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
# }

# ❯ Almacenamos todo el historial de comandos con SQLite {
$env.config.history = {
  file_format: sqlite
  max_size: 1_000_000
  sync_on_enter: true
  isolation: false
}
# }

# ❯ Sourcea todos los aliases configurados
source ~/.config/nushell/aliases.nu

# ❯ Carga zoxide
source ~/.cache/zoxide/init.nu

# ❯ Evita que aparezca el banner de bienvenida al iniciar Nushell
$env.config.show_banner = false

# ❯ Inicializar Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
