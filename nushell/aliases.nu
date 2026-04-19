# Aliases para Nushell
# ~/.config/nushell/aliases.nu

# =============================================
# 1.          COMANDOS DEL SISTEMA
# =============================================
# Actualización del sistema y utilidades básicas
def update [] {                                              # <-- Actualizar todo el sistema y Flatpaks
  yay; flatpak update
}
def cleanup [] {                                             # <-- Limpia paquetes huérfanos
    sudo pacman -Rns (pacman -Qtdq)
}
alias mirrors = sudo-rs reflector --latest 30 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
# ↳ Selecciona los 30 servidores https más actualizados, organizados por velocidad de descarga, reescribe en pacman.d/mirrorlist ↲
alias grubup = sudo-rs grub-mkconfig -o /boot/grub/grub.cfg  # <-- Actualiza las configuraciones del GRUB
alias fsh = fastfetch                                        # <-- Yo Angelo 
alias salir = exit                                           # <-- Sácame de aquí
alias cls = clear                                            # <-- Limpia, limpia
alias bankai = rm -r                                         # <-- Yokoso
alias Bankai = sudo-rs rm -r                                 # <-- Root Yokoso
alias sudo = sudo-rs                                         # <-- Ferris Sudo
alias sudoedit = sudo-rs -e                                  # <-- Ferris editando...

# =============================================
# 2.        NAVEGACIÓN DE DIRECTORIOS
# =============================================
# Comandos para moverse entre directorios
alias ir = cd                      # <-- Llévame a casa
# def irc [] {                     # <-- Ir al home y limpiar consola
#   clear; cd
# }
alias cds = yazi                   # <-- Me encanta yazi 
alias .. = cd ..                   # <-- Subir un nivel de directorio
alias ... = cd ../..               # <-- Subir dos niveles de directorio
alias .... = cd ../../..           # <-- Subir tres niveles de directorio
alias ..... = cd ../../../..       # <-- Subir cuatro niveles de directorio
alias ...... = cd ../../../../..   # <-- Subir cinco niveles de directorio

# =============================================
# 3.             TASKWARRIOR
# =============================================
alias t = task                     # <-- Taskwarrior!
alias tn = task next               # <-- Mostrar las tareas más próximas
alias ts = task summary            # <-- Resumen de todas las tareas
alias td = task done               # <-- Marcar una tarea como hecha
def ta [                           # <-- Crear nueva tarea de manera 'Awesome' O_<
    name: string,             # El título es lo único obligatorio
    --project (-p): string,   # Proyecto opcional
    --due (-d): string,       # Fecha opcional
    --priority (-i): string   # Prioridad opcional (i de 'importance')
] {
    # Construimos el comando base
    let command = ["add" $name]
    
    # Añadimos atributos solo si fueron proporcionados
    let command = if ($project != null) { $command | append $"project:($project)" } else { $command }
    let command = if ($due != null) { $command | append $"due:($due)" } else { $command }
    let command = if ($priority != null) { $command | append $"priority:($priority)" } else { $command }

    # Ejecutamos el comando final
    run-external $command.0 ...($command | drop 1)
}

# =============================================
# 4.             COMANDOS LS
# =============================================
# eza >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ls 
alias l = ls  # <-- Listar directorios y archivos
alias x = eza --classify=auto --color=always --group-directories-first --sort=extension -A --icons=always  # <-- Listar carpetas y archivos (contando ocultos) con eza
alias xa = eza -a -f --color=always --icons=always                                                         # <-- Listar archivos ocultos con eza
alias xl = eza -l --tree --level=2 --color=always --group-directories-first --icons=always                 # <-- Listado en tree (sin ocultos) con eza

# =============================================
# 5.     HERRAMIENTAS Y ACCESOS DIRECTOS
# =============================================
# Accesos rápidos a herramientas externas
alias icat = kitten icat  # <-- Visor rápida y nativo de imágenes usando la terminal de Kitty
alias tub = pipes-rs      # <-- Generación fantástica y atractiva de tuberías (usando Pipes-RS) en la terminal
alias lg = lazygit        # <-- Uso rápido de 'lazygit'
alias py = python3        # <-- Uso rápido de 'python3'
alias hx = helix          # <-- Uso rápido de 'helix'
def hf [] {               # <-- helix + fzf + bat = отлично
    let fzf_preview = "bat --color=always --line-range :500 --theme='Catppuccin Mocha' {}"
    
    let file = (
        fd --type f --hidden --exclude .git --exclude node_modules --exclude .cache 
        | fzf --preview $fzf_preview --preview-window="right:55%:rounded:border-sharp" --bind="ctrl-/:toggle-preview" --header="📄 Archivos (Ctrl+/ para preview)" 
        | str trim
    )

    if ($file | is-not-empty) {
        hx $file
    }
}
def --env fzd [] {        # <-- 'cd' inteligente: fzf + fd + eza
    let fzf_preview = "eza --tree --color=always --icons=always --group-directories-first --level=2 {}"
    
    let folder = (
        fd --type d --hidden --exclude .git --exclude node_modules --exclude .cache 
        | fzf --preview $fzf_preview --preview-window="right:50%:rounded" --header="📁 Carpetas" 
        | str trim
    )

    if ($folder | is-not-empty) {
        cd $folder
    }
}
alias postgrestart = sudo systemctl start postgresql # <-- Inicializar PostgreSQL
alias postgrestop = sudo systemctl stop postgresql   # <-- Detener PostgreSQL
alias mariastart = sudo systemctl start mariadb      # <-- Inicializar MariaDB
alias mariastop = sudo systemctl stop mariadb        # <-- Detener MariaDB
alias mariaenter = mariadb -u root -p                # <-- Entrar a MariaDB como root
alias mariadeventer = mariadb -u dev -p              # <-- Entrar a MariaDB como dev
alias ollamastart = sudo systemctl start ollama      # <-- Inicializar Ollama
alias ollamastop = sudo systemctl stop ollama        # <-- Detener Ollama
alias clc = ollama launch claude                     # <-- Inicializar Claude Code mediante Ollama

# =============================================
# 6.          MANEJO DE ARCHIVOS
# =============================================
# Comandos para manipulación de archivos
alias tarnow = tar -acvf   # <-- Crear un archivo .tar usando comprensión automática
alias untar = tar -xf      # <-- Descomprimir un .tar 
alias targnow = tar -czvf  # <-- Crear un archivo .tar usando gzip como comprensión
alias ungz = gunzip        # <-- Descomprimir archivos .gz
alias wget = wget -c       # <-- Continuar descargas interrumpidas automáticamente
alias zipnow = 7z a        # <-- Crear un archivo .7z usando 7zip

# =============================================
# 7.                 GIT
# =============================================
# Aliases/shortcuts para un workflow más fluido usando git
alias gi = git init                # <-- Inicializar un nuevo repositorio Git
alias gs = git status              # <-- Ver el estado del repositorio
alias gsx = gstat                  # <-- Git Status organizado por Nu
alias ga = git add                 # <-- Añadir archivos al staging
alias gaa = git add --all          # <-- Añadir todos los archivos al staging
alias gc = git commit -m           # <-- Hacer commit con mensaje
alias glo = git log --oneline      # <-- Ver historial de commits en una línea
alias glo5 = git log --oneline -5  # <-- Ver últimos 5 commits en una línea
alias gco = git checkout           # <-- Cambiar de rama o versión
alias gbr = git branch             # <-- Listar, crear o eliminar ramas
alias gp = git push                # <-- Subir cambios al repositorio remoto
def gcl [] {                       # <-- Configuración de Git en forma tabular
  git config --list | lines | split column '=' key value
}
def g-dual [user: string, repo: string] {   # <-- Configuración Dual Push para GitHub & Codeberg
    let gh = $"git@github.com:($user)/($repo).git"
    let cb = $"ssh://git@codeberg.org/($user)/($repo).git"

    git remote set-url origin $gh
    git remote set-url --add --push origin $gh
    git remote set-url --add --push origin $cb
    
    print "✅ Configuración dual completada:"
    git remote -v
}

# =============================================
# 8.             RUST Y CARGO
# =============================================
# Aliases/shortcuts para un workflow más fluido usando Rust & Cargo

# --- Creación y Comprobación ---
alias cn = cargo new        # <-- Crear un nuevo proyecto (binario)
alias ci = cargo init       # <-- Crear un Cargo.toml de un src/ ya existente
alias cnl = cargo new --lib # <-- Crear un nuevo proyecto (biblioteca)
alias cc = cargo check      # <-- Compilar el código sin producir un ejecutable (muy rápido) 

# --- Gestión de Dependencias ---
alias cad = cargo add     # <-- Añadir un nuevo paquete o dependencia al proyecto dentro del Cargo.toml 
alias crm = cargo remove  # <-- Eliminar un paquete o dependencia del proyecto dentro del Cargo.toml
alias ctree = cargo tree  # <-- Visualizar en forma de tree todos los paquetes, dependencias y subdependencias

# --- Compilación (Build) ---
alias cb = cargo build            # <-- Compilar el proyecto (modo debug, más lento que 'check')
alias cbr = cargo build --release # <-- Compilar el proyecto (modo release, optimizado)

# --- Ejecución (Run) ---
alias cr = cargo run            # <-- Compilar y ejecutar (modo debug)
alias crr = cargo run --release # <-- Compilar y ejecutar (modo release)

# --- Pruebas (Test) ---
alias ct = cargo test            # <-- Ejecutar los tests (modo debug)
alias ctr = cargo test --release # <-- Ejecutar los tests (modo release)

# --- Calidad y Formato ---
# alias cf = cargo fmt                # <-- Formatear el código
# alias ccl = cargo clippy            # <-- Ejecutar el linter (análisis de código)
# alias cclr = cargo clippy --release # <-- Ejecutar el linter (modo release)

# --- Utilidades ---
alias cu = cargo update       # <-- Actualizar las dependencias (Cargo.lock)
alias cclean = cargo clean    # <-- Limpiar la carpeta target/, limpiar espacio y compilaciones
alias cdo = cargo doc         # <-- Generar la documentación
alias cdoo = cargo doc --open # <-- Generar y abrir la documentación

# --- Ecosistema (Rustup) ---
alias ru = rustup update # <-- Actualizar el toolchain de Rust
