# config.nu
#
# Installed by:
# version = "0.112.2"
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

# ❯ Función para obtener y formatear las tareas pendientes mediante Taskwarrior
# Retorna siempre una tabla o null — nunca una string
def get_task_table [] {
    let raw_tasks = (task status:pending export | from json)

    if ($raw_tasks | is-empty) {
        return null
    }

    $raw_tasks
    | select id? description? project? priority? due?
    | default "None" priority
    | upsert priority {
        match $in {
            "H" => $"(ansi red_bold)High(ansi reset)",
            "M" => $"(ansi yellow)Mid(ansi reset)",
            "L" => $"(ansi green)Low(ansi reset)",
            _   => "None"
        }
    }
    | upsert due {
        if $in == null { "---" } else { $in | into datetime | format date "%d-%m-%Y" }
    }
}

# El saludo y el Resumen
let total_pending = (task status:pending count | into int)

let ferris_art = [
    "       _~^~^~_",
    '   \) /  o o  \ (/',
    "     '_   -   _'",
    "     / '-----' \\"
] | str join "\n"

let mascot = $"(ansi light_red)($ferris_art)(ansi reset)"

print $mascot
print $"(ansi light_blue_bold)¡Hola de nuevo, José Luis!(ansi reset)"
print $"(ansi white)Actualmente tienes (ansi yellow_bold)($total_pending)(ansi white) tareas en tu TODOist:(ansi reset)"
print ""

# Ahora get_task_table retorna null o tabla — manejamos cada caso explícitamente
let tasks = get_task_table
if $tasks == null {
    print $"(ansi green_italic)No hay tareas pendientes. ¡Buen trabajo!(ansi reset)"
} else {
    # print es necesario en config.nu — las expresiones no se auto-imprimen al ser sourced
    print ($tasks | table --expand)
}
print ""
