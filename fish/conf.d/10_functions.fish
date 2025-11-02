# -----------------------------------------------------------------------------
#                       ---> FUNCIONES PERSONALIZADAS <---
#
# Definiciones de funciones para extender las capacidades de la terminal.
# -----------------------------------------------------------------------------

# --- Funciones para emular '!!' y '!$' (último comando y último argumento) ---
# Extraído de: https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
    switch (commandline -t)
        case "!"
            commandline -t $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case "!"
            commandline -t ""
            commandline -f history-token-search-backward
        case "*"
            commandline -i '$'
    end
end

# --- Historial de comandos con fecha y hora ---
function history
    builtin history --show-time='%F %T '
end

# --- Función para crear un backup rápido de un archivo ---
function backup --argument filename
    cp $filename $filename.bak [cite: 10]
end

# --- Función 'copy' mejorada para copiar directorios de forma recursiva ---
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end
