# Aliases para la terminal
# ~/.zshrc.d/aliases.zsh

# =============================================
# 1.          COMANDOS DEL SISTEMA
# =============================================
# Actualización del sistema y utilidades básicas
alias update='yay && flatpak update'                     # <-- Actualizar todo el sistema y Flatpaks
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'          # <-- Limpia paquetes huérfanos
alias mirrors='sudo reflector --latest 30 --protocol https --sort rate --save /etc/pacman.d/mirrorlist' # ↴
# ↳ Selecciona los 30 servidores https más actualizados, organizados por velocidad de descarga, reescribe en pacman.d/mirrorlist ↲
alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg' # <-- Actualiza las configuraciones del GRUB
alias fsh='fastfetch'                                    # <-- Yo Angelo 
alias salir='exit'                                       # <-- Sácame de aquí
alias cls='clear'                                        # <-- Limpia, limpia
alias bankai='rm -rf'                                    # <-- Yokoso

# =============================================
# 2.        NAVEGACIÓN DE DIRECTORIOS
# =============================================
# Comandos para moverse entre directorios
alias ir='cd'                             # <-- Llévame a casa
alias irc='cd && clear'                   # <-- Ir al home y limpiar consola
alias cds='yazi'                          # <-- Me encanta yazi 
alias ..='cd ..'                          # <-- Subir un nivel de directorio
alias ...='cd ../..'                      # <-- Subir dos niveles de directorio
alias ....='cd ../../..'                  # <-- Subir tres niveles de directorio
alias .....='cd ../../../..'              # <-- Subir cuatro niveles de directorio
alias ......='cd ../../../../..'          # <-- Subir cinco niveles de directorio

# =============================================
# 3.           COMANDOS LS
# =============================================
# eza >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ls 
alias x='eza --classify=auto --color=always --group-directories-first --sort=extension -A --icons=always'  # <-- Listar archivos con eza (formato básico)
alias xa='eza -a -f --color=always --icons=always'                                                         # <-- Listar archivos incluyendo ocultos con eza
alias xl='eza -l --tree --level=2 --color=always --group-directories-first --icons=always'                 # <-- Listado de archivos en tree (sin ocultos) con eza

# =============================================
# 4.     HERRAMIENTAS Y ACCESOS DIRECTOS
# =============================================
# Accesos rápidos a herramientas externas
alias icat='kitten icat' # <-- Visor rápida y nativo de imágenes usando la terminal de Kitty
alias tub='pipes-rs'     # <-- Generación fantástica y atractiva de tuberías (usando Pipes-RS) en la terminal
alias lg='lazygit'       # <-- Uso rápido de 'lazygit'
alias py='python3'       # <-- Uso rápido de 'python3'
alias hx='helix'         # <-- Uso rápido de 'helix'

# =============================================
# 5.          MANEJO DE ARCHIVOS
# =============================================
# Comandos para manipulación de archivos
alias tarnow='tar -acvf '  # <-- Crear un archivo .tar usando comprensión automática
alias targnow='tar -czvf ' # <-- Crear un archivo .tar usando gzip como comprensión
alias ungz="gunzip"        # <-- Descomprimir archivos .gz
alias wget='wget -c '      # <-- Continuar descargas interrumpidas automáticamente
alias zipnow='7z a '       # <-- Crear un archivo .7z usando 7zip
# alias unzip='7z x'       # <-- Descomprimir .zip usando la heramienta de 7zip

# =============================================
# 6.                 GIT
# =============================================
# Aliases/shortcuts para un workflow más fluido usando git
alias gi='git init'                # <-- Inicializar un nuevo repositorio Git
alias gs='git status'              # <-- Ver el estado del repositorio
alias ga='git add'                 # <-- Añadir archivos al staging
alias gaa='git add --all'          # <-- Añadir todos los archivos al staging
alias gc='git commit -m'           # <-- Hacer commit con mensaje
alias glo='git log --oneline'      # <-- Ver historial de commits en una línea
alias glo5='git log --oneline -5'  # <-- Ver últimos 5 commits en una línea
alias gco='git checkout'           # <-- Cambiar de rama o versión
alias gbr='git branch'             # <-- Listar, crear o eliminar ramas
alias gp='git push'                # <-- Subir cambios al repositorio remoto
