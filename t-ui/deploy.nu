#!/usr/bin/env nu
# ==============================================================================
# Script de Despliegue de T-UI Launcher para Nushell
# Sincroniza la configuración de ~/.dotfiles/t-ui/ hacia el Oppo Reno 5 Lite
# ==============================================================================

def main [
    --restart (-r) # Reiniciar T-UI automáticamente tras sincronizar
] {
    let tui_dir = ($env.HOME | path join ".dotfiles" "t-ui")
    let target_remote = "/sdcard/t-ui"
    
    print $"(ansi cyan_bold)🚀 Sincronizando configuración T-UI Nushell-Style...(ansi reset)"
    
    # 1. Comprobar presencia de adb
    if (which adb | is-empty) {
        print -e $"(ansi red_bold)Error:(ansi reset) 'adb' no está instalado en el sistema."
        print "Puedes transferir los archivos manualmente a '/storage/emulated/0/t-ui/' usando MTP, Termux o tu gestor de archivos."
        return
    }
    
    # 2. Comprobar dispositivo conectado
    let devices = (adb devices | lines | skip 1 | where ($it | str contains "\tdevice"))
    if ($devices | is-empty) {
        print -e $"(ansi yellow_bold)Advertencia:(ansi reset) No se detectó ningún dispositivo Android conectado vía ADB."
        print "Asegúrate de tener la depuración USB activa o copia la carpeta manualmente."
        return
    }
    
    # 3. Subir archivos XML y alias.txt
    let files_to_sync = [
        "behavior.xml",
        "theme.xml",
        "ui.xml",
        "suggestions.xml",
        "toolbar.xml",
        "alias.txt",
        "cmd.xml",
        "notifications.xml"
    ]
    
    for f in $files_to_sync {
        let src = ($tui_dir | path join $f)
        if ($src | path exists) {
            print $"  󰄵 Subiendo ($f)..."
            adb push $src $target_remote
        }
    }
    
    print $"\n(ansi green_bold)✔ ¡Sincronización completada con éxito!(ansi reset)"
    print "Ejecuta '(ansi cyan)restart(ansi reset)' en la terminal de T-UI para aplicar los cambios."
    
    if $restart {
        print "Reiniciando T-UI Launcher..."
        adb shell am force-stop com.andot.fork.tui
        adb shell monkey -p com.andot.fork.tui -c android.intent.category.LAUNCHER 1
    }
}
