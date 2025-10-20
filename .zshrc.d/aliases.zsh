# Aliases para la terminal
# ~/.zshrc.d/aliases.zsh

# =============================================
# 1.          COMANDOS DEL SISTEMA
# =============================================
# Actualización del sistema y utilidades básicas
alias update='yay'                              # <-- Actualizar todo el sistema
alias cleanup='sudo pacman -Rns (pacman -Qtdq)' # <-- Limpia paquetes huérfanos
alias mirrors='sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist' # ↴
# ↳ Selecciona los 20 servidores https más actualizados, organizados por velocidad de descarga, reescribe en pacman.d/mirrorlist ↲
alias fsh='fastfetch'                           # <-- Yo Angelo 
alias salir='exit'                              # <-- Sácame de aquí
alias cls='clear'                               # <-- Limpia, limpia 

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
alias l='eza --classify=auto --color=always --group-directories-first --sort=extension -A --icons'  # <-- Listar archivos con eza (formato básico)
alias la='eza -a --color=always --group-directories-first --icons'                                  # <-- Listar archivos incluyendo ocultos con eza
alias ll='eza -l --color=always --group-directories-first --icons'                                  # <-- Listado detallado con eza
alias l.="eza -a | grep -e '^\.'"                                                                   # <-- Mostrar solo archivos ocultos con eza

# =============================================
# 4.     HERRAMIENTAS Y ACCESOS DIRECTOS
# =============================================
# Accesos rápidos a herramientas externas
alias icat='kitten icat' # <-- Visor rápida y nativo de imágenes usando la terminal de Kitty
alias tub='pipes-rs'     # <-- Generación fantástica y atractiva de tuberías (usando Pipes-RS) en la terminal
alias lg='lazygit'       # <-- Uso 'lazy' de git

# =============================================
# 5.          MANEJO DE ARCHIVOS
# =============================================
# Comandos para manipulación de archivos
alias untar='tar -xf'    # <-- Descomprimir .tar's 
alias tarnow='tar -acf ' # <-- Crear archivo .tar comprimido
alias ungz="gunzip -k"   # <-- Descomprimir archivos .gz manteniendo el original
alias wget='wget -c '    # <-- Continuar descargas interrumpidas automáticamente

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
alias cnl='cargo new --lib' # <-- Crear un nuevo proyecto (biblioteca)
alias cc='cargo check'      # <-- Comprobar el código (rápido, sin compilar)

# --- Compilación (Build) ---
alias cb='cargo build'            # <-- Compilar el proyecto (modo debug)
alias cbr='cargo build --release' # <-- Compilar el proyecto (modo release, optimizado)

# --- Ejecución (Run) ---
alias cr='cargo run'            # <-- Compilar y ejecutar (modo debug)
alias crr='cargo run --release' # <-- Compilar y ejecutar (modo release)

# --- Pruebas (Test) ---
alias ct='cargo test'            # <-- Ejecutar los tests (modo debug)
alias ctr='cargo test --release' # <-- Ejecutar los tests (modo release)

# --- Calidad y Formato ---
alias cf='cargo fmt'                # <-- Formatear el código
alias ccl='cargo clippy'            # <-- Ejecutar el linter (análisis de código)
alias cclr='cargo clippy --release' # <-- Ejecutar el linter (modo release)

# --- Utilidades ---
alias cu='cargo update'       # <-- Actualizar las dependencias (Cargo.lock)
alias cdo='cargo doc'         # <-- Generar la documentación
alias cdoo='cargo doc --open' # <-- Generar y abrir la documentación

# --- Ecosistema (Rustup) ---
alias ru='rustup update' # <-- Actualizar el toolchain de Rust
