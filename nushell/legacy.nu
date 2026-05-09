# Funciones y comandos de Nushell que no uso actualmente
# Bóveda Personal Legacy

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
