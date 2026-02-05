# Aliases para la terminal
# ~/.zshrc.d/aliases.zsh

# =============================================
# 1.          COMANDOS DEL SISTEMA
# =============================================
# Actualización del sistema y utilidades básicas
alias update='yay'                                       # <-- Actualizar todo el sistema
# alias update='yay && flatpak update'                   # <-- Actualizar todo el sistema y Flatpaks
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
alias postgrestart='sudo systemctl start postgresql'          # <-- Inicializar PostgreSQL
alias postgrestop='sudo systemctl stop postgresql'            # <-- Detener PostgreSQL
alias mariastart='sudo systemctl start mariadb'               # <-- Inicializar MariaDB
alias mariastop='sudo systemctl stop mariadb'                 # <-- Detener MariaDB
alias mariaenter='mariadb -u root -p'                         # <-- Entrar a MariaDB como root
alias mariadeventer='mariadb -u dev -p'                       # <-- Entrar a MariaDB como dev

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

# =============================================
# 7.             RUST Y CARGO
# =============================================
# Aliases/shortcuts para un workflow más fluido usando Rust y Cargo

# --- Creación y Comprobación ---
alias cn='cargo new'        # <-- Crear un nuevo proyecto (binario)
alias ci='cargo init'       # <-- Crear un Cargo.toml de un src/ ya existente
alias cnl='cargo new --lib' # <-- Crear un nuevo proyecto (biblioteca)
alias cc='cargo check'      # <-- Compilar el código sin producir un ejecutable (muy rápido) 

# --- Compilación (Build) ---
alias cb='cargo build'            # <-- Compilar el proyecto (modo debug, más lento que 'check')
alias cbr='cargo build --release' # <-- Compilar el proyecto (modo release, optimizado)

# --- Ejecución (Run) ---
alias cr='cargo run'            # <-- Compilar y ejecutar (modo debug)
alias crr='cargo run --release' # <-- Compilar y ejecutar (modo release)

# --- Pruebas (Test) ---
alias ct='cargo test'            # <-- Ejecutar los tests (modo debug)
alias ctr='cargo test --release' # <-- Ejecutar los tests (modo release)

# --- Calidad y Formato ---
# alias cf='cargo fmt'                # <-- Formatear el código
# alias ccl='cargo clippy'            # <-- Ejecutar el linter (análisis de código)
# alias cclr='cargo clippy --release' # <-- Ejecutar el linter (modo release)

# --- Utilidades ---
alias cu='cargo update'       # <-- Actualizar las dependencias (Cargo.lock)
alias cdo='cargo doc'         # <-- Generar la documentación
alias cdoo='cargo doc --open' # <-- Generar y abrir la documentación

# --- Ecosistema (Rustup) ---
alias ru='rustup update' # <-- Actualizar el toolchain de Rust

# =============================================
# 8.                   V
# =============================================
# Aliases/shortcuts para un workflow más fluido usando V (vlang)

alias vpd='v -prod'         # <-- Compila V y genera el ejecutable con todas las optimizaciones posibles
alias vspd='v -stats -prod' # <-- Compila V y genera el ejecutable con todas las optimizaciones posibles junto con sus stats
alias vrun='v run'          # <-- Compila código V y enseguida ejecuta el ejecutable creado
alias vruns='v -stats run'  # <-- Compila código V y enseguida ejecuta el ejecutable creado junto con sus stats
alias vpruns='v -stats -prod run' # <-- Compila código V en modo optimización y enseguida ejecuta el ejecutable creado junto con sus stats
alias vrunc='v crun'        # <-- Realiza lo mismo que 'v run' con excepción de que solo guardará y recompilará cuando haya cambios
alias vest='v test'         # <-- Corre los 'test' que haya en los archivos y directorios seleccionados
alias vet='v vet'           # <-- Reporta construcciones de código sospechosas 
alias voc='v doc'           # <-- Genera documentación del módulo, directorio o archivo seleccionado ¡Checar opciones!
alias vatch='v watch'       # <-- Recoleta todos los '.v' necesario para compilar, si algún archivo cambia lo vuelve a recompilar
