#!/usr/bin/env nu

# Inicia un ejecutable de manera aislada utilizando Bubblewrap (bwrap)
def main [
    game_dir?: path  # Ruta al directorio del juego (por defecto, el directorio del script)
] {
    # Obtener la ruta absoluta del directorio del script actual si no se proporciona
    let game_path = if ($game_dir | is-empty) {
        $env.FILE_PWD | path expand
    } else {
        $game_dir | path expand
    }

    if not ($game_path | path exists) {
        error make { msg: $"El directorio del juego no existe en: ($game_path)" }
    }

    # 1. Definir directorio de persistencia para saves (~/.renpy dentro del sandbox)
    let sandbox_home = ($env.HOME | path join ".local" "share" "game_sandboxes" ($game_path | path basename))
    if not ($sandbox_home | path exists) {
        print $"(ansi green)[+] Creando directorio para partidas guardadas en: ($sandbox_home)(ansi reset)"
        mkdir $sandbox_home
    }

    # 2. Configurar variables de entorno y sockets gráficos (X11 / Wayland)
    let display = ($env.DISPLAY? | default ":0")
    let wayland_display = $env.WAYLAND_DISPLAY?
    let xdg_runtime = $env.XDG_RUNTIME_DIR
    let xauth_path = ($env.XAUTHORITY? | default ($env.HOME | path join ".Xauthority"))
    
    # 3. Detectar sockets de audio
    let pulse_socket = $"($xdg_runtime)/pulse/native"
    let pipewire_socket = $"($xdg_runtime)/pipewire-0"

    # 4. Construcción declarativa de flags para Bubblewrap
    let bwrap_flags = [
        "bwrap"
        
        # --- Aislamiento de Namespaces ---
        # NO aislamos: user (rompería ACLs de /dev/dri), pid (DRM auth), ipc (DRI3/MIT-SHM).
        "--unshare-net"
        "--unshare-uts"
        "--unshare-cgroup"
        
        # --- Sistema de Archivos Virtual (Estructura de Arch Linux) ---
        "--ro-bind" "/usr" "/usr"
        "--symlink" "usr/bin" "/bin"
        "--symlink" "usr/lib" "/lib"
        "--symlink" "usr/lib64" "/lib64"
        "--ro-bind" "/etc" "/etc"
        "--ro-bind" "/usr/share" "/usr/share"
        
        # --- Kernel y Dispositivos de Hardware ---
        "--proc" "/proc"
        "--dev" "/dev"
        "--dev-bind" "/dev/dri" "/dev/dri" # Aceleración 3D (Mesa/DRI)
        "--ro-bind" "/sys" "/sys"          # Sysfs: requerido por Mesa para enumerar GPUs
        "--tmpfs" "/tmp"                   # Directorio /tmp temporal limpio
        
        # --- Servidor Gráfico X11 ---
        "--ro-bind" "/tmp/.X11-unix" "/tmp/.X11-unix"
        
        # --- Datos del Juego y Persistencia ---
        "--ro-bind" $game_path "/game"               # Juego montado como solo lectura
        "--bind" $sandbox_home "/home/sandbox"       # Directorio de guardado (Lectura/Escritura)
        
        # --- Variables de Entorno Seguras ---
        "--setenv" "HOME" "/home/sandbox"
        "--setenv" "DISPLAY" $display
        "--setenv" "PATH" "/usr/bin:/bin"
        "--setenv" "LANG" ($env.LANG? | default "C.UTF-8")
    ]

    # 5. Integración dinámica del servidor de audio (PulseAudio o PipeWire)
    let bwrap_flags = if ($pulse_socket | path exists) {
        $bwrap_flags | append [
            "--ro-bind" $pulse_socket "/tmp/pulse-socket"
            "--setenv" "PULSE_SERVER" "unix:/tmp/pulse-socket"
        ]
    } else if ($pipewire_socket | path exists) {
        $bwrap_flags | append [
            "--ro-bind" $pipewire_socket "/tmp/pipewire-0"
            "--setenv" "PIPEWIRE_RUNTIME_DIR" "/tmp"
        ]
    } else {
        $bwrap_flags
    }

    # 5.5 Integración del Servidor Gráfico (Wayland y Xauthority para Xwayland fallback)
    let bwrap_flags = if ($wayland_display | is-not-empty) {
        let wayland_socket = ($xdg_runtime | path join $wayland_display)
        if ($wayland_socket | path exists) {
            $bwrap_flags | append [
                "--ro-bind" $wayland_socket $wayland_socket
                "--setenv" "WAYLAND_DISPLAY" $wayland_display
                "--setenv" "XDG_RUNTIME_DIR" $xdg_runtime
            ]
        } else {
            $bwrap_flags
        }
    } else {
        $bwrap_flags
    }

    let bwrap_flags = if ($xauth_path | path exists) {
        $bwrap_flags | append [
            "--ro-bind" $xauth_path "/home/sandbox/.Xauthority"
            "--setenv" "XAUTHORITY" "/home/sandbox/.Xauthority"
        ]
    } else {
        $bwrap_flags
    }

    # 6. Comando final y punto de entrada (renpy launcher)
    let run_cmd = ($bwrap_flags | append [
        "--chdir" "/game"
        "/game/XYZ.sh"
        # ¡Importante cambiar el `XYZ.sh` por el script inicializador del juego!
    ])

    # --- Verbose Outputs coloridos en Nushell ---
    print $"\n(ansi light_purple_bold)======================================================================(ansi reset)"
    print $" (ansi light_blue_bold)🛡️  INICIANDO SANDBOX CON BUBBLEWRAP [bwrap] para: ($game_path | path basename)(ansi reset)"
    print $"(ansi light_purple_bold)======================================================================(ansi reset)"

    # RED (Bloqueada)
    print $" (ansi red_bold)✗ Red:(ansi reset) (ansi red)DESACTIVADA(ansi reset) [--unshare-net activado]"

    # PERSISTENCIA Y HOME
    print $" (ansi green_bold)✓ Home Aislado [Saves]:(ansi reset) (ansi light_green)($sandbox_home)(ansi reset) -> (ansi yellow)/home/sandbox(ansi reset)"
    print $" (ansi green_bold)✓ Datos del Juego:(ansi reset) (ansi light_green)($game_path)(ansi reset) -> (ansi yellow)/game(ansi reset) (ansi red)[SOLO LECTURA](ansi reset)"

    # SISTEMA DE ARCHIVOS DEL HOST
    print $" (ansi green_bold)✓ Estructura de Sistema:(ansi reset) /usr, /bin, /lib, /lib64, /etc (ansi red)[SOLO LECTURA](ansi reset)"
    print $" (ansi green_bold)✓ Carpeta Temporal:(ansi reset) (ansi yellow)/tmp(ansi reset) montado en (ansi light_green)tmpfs(ansi reset) [Memoria volátil vacía]"

    # HARDWARE & DRI
    let gpu_status = if ("/dev/dri" | path exists) {
        $"(ansi light_green)Habilitada [Acceso a /dev/dri expuesto para renderizado OpenGL](ansi reset)"
    } else {
        $"(ansi red)No disponible [/dev/dri no encontrado](ansi reset)"
    }
    print $" (ansi green_bold)✓ GPU/Aceleración 3D:(ansi reset) ($gpu_status)"

    # AUDIO DETECTADO
    let audio_status = if ($pulse_socket | path exists) {
        $"(ansi light_green)PulseAudio detectado y expuesto [/tmp/pulse-socket](ansi reset)"
    } else if ($pipewire_socket | path exists) {
        $"(ansi light_green)PipeWire detectado y expuesto [/tmp/pipewire-0](ansi reset)"
    } else {
        $"(ansi red)Desactivado [Socket de audio no encontrado en XDG_RUNTIME_DIR](ansi reset)"
    }
    print $" (ansi green_bold)✓ Audio:(ansi reset) ($audio_status)"

    # GRÁFICOS DETECTADOS
    let wayland_socket = ($xdg_runtime | path join ($wayland_display | default ""))
    let graphics_status = if ($wayland_display | is-not-empty) and ($wayland_socket | path exists) {
        $"(ansi light_green)Wayland habilitado [($wayland_display)](ansi reset)"
    } else {
        $"(ansi light_green)X11 habilitado [($display)] [Xauthority mapeado](ansi reset)"
    }
    print $" (ansi green_bold)✓ Servidor Gráfico:(ansi reset) ($graphics_status)"

    # NAMESPACES & SEGURIDAD
    print $" (ansi green_bold)✓ Namespaces Aislados:(ansi reset) (ansi light_cyan)NET, UTS [Hostname], CGROUP(ansi reset)"
    print $"(ansi light_purple_bold)======================================================================(ansi reset)\n"

    # Ejecutar
    run-external $run_cmd.0 ...($run_cmd | skip 1)
}
