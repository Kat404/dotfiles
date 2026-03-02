#!/bin/bash
#
# Script para instalar los dotfiles desde este repositorio a la carpeta $HOME
# creando enlaces simbólicos (symlinks).

# -e: Salir inmediatamente si un comando falla.
# -u: Tratar las variables no definidas como un error.
# -o pipefail: El código de salida de una tubería es el del último comando que falló.
set -euo pipefail

# Directorio donde se encuentra el repositorio de dotfiles (Detectado automáticamente)
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Directorio para guardar backups de los archivos que ya existan
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# --- COLORES Y ESTÉTICA ---

R='\033[0;31m'
G='\033[0;32m'
B='\033[0;34m'
C='\033[0;36m'
Y='\033[1;33m'
M='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_banner() {
    clear
    # Gradiente simulado (Azul -> Magenta)
    # ASCII Art: KAT404
    echo "          _____                    _____                _____                    _____          ";
    echo "         /\\    \\                  /\\    \\              /\\    \\                  /\\    \\         ";
    echo "        /::\\____\\                /::\\    \\            /::\\    \\                /::\\    \\        ";
    echo "       /:::/    /               /::::\\    \\           \\:::\\    \\              /::::\\    \\       ";
    echo "      /:::/    /               /::::::\\    \\           \\:::\\    \\            /::::::\\    \\      ";
    echo "     /:::/    /               /:::/\\:::\\    \\           \\:::\\    \\          /:::/\\:::\\    \\     ";
    echo "    /:::/____/               /:::/__\\:::\\    \\           \\:::\\    \\        /:::/__\\:::\\    \\    ";
    echo "   /::::\\    \\              /::::\\   \\:::\\    \\          /::::\\    \\       \\:::\\   \\:::\\    \\   ";
    echo "  /::::::\\____\\________    /::::::\\   \\:::\\    \\        /::::::\\    \\    ___\\:::\\   \\:::\\    \\  ";
    echo " /:::/\\:::::::::::\\    \\  /:::/\\:::\\   \\:::\\    \\      /:::/\\:::\\    \\  /\\   \\:::\\   \\:::\\    \\ ";
    echo "/:::/  |:::::::::::\\____\\/:::/  \\:::\\   \\:::\\____\\    /:::/  \\:::\\____\\/::\\   \\:::\\   \\:::\\____\\";
    echo "\\::/   |::|~~~|~~~~~     \\::/    \\:::\\  /:::/    /   /:::/    \\::/    /\\:::\\   \\:::\\   \\::/    /";
    echo " \\/____|::|   |           \\/____/ \\:::\\/:::/    /   /:::/    / \\/____/  \\:::\\   \\:::\\   \\/____/ ";
    echo "       |::|   |                    \\::::::/    /   /:::/    /            \\:::\\   \\:::\\    \\     ";
    echo "       |::|   |                     \\::::/    /   /:::/    /              \\:::\\   \\:::\\____\\    ";
    echo "       |::|   |                     /:::/    /    \\::/    /                \\:::\\  /:::/    /    ";
    echo "       |::|   |                    /:::/    /      \\/____/                  \\:::\\/:::/    /     ";
    echo "       |::|   |                   /:::/    /                                 \\::::::/    /      ";
    echo "       \\::|   |                  /:::/    /                                   \\::::/    /       ";
    echo "        \\:|   |                  \\::/    /                                     \\::/    /        ";
    echo "         \\|___|                   \\/____/                                       \\/____/         ";
    echo "                                                                                                "; 
    echo "      ___           ___           ___           ___                       ___       ___           ___     ";
    echo "     /\\  \\         /\\  \\         /\\  \\         /\\  \\          ___        /\\__\\     /\\  \\         /\\  \\    ";
    echo "    /::\\  \\       /::\\  \\        \\:\\  \\       /::\\  \\        /\\  \\      /:/  /    /::\\  \\       /::\\  \\   ";
    echo "   /:/\\:\\  \\     /:/\\:\\  \\        \\:\\  \\     /:/\\:\\  \\       \\:\\  \\    /:/  /    /:/\\:\\  \\     /:/\\ \\  \\  ";
    echo "  /:/  \\:\\__\\   /:/  \\:\\  \\       /::\\  \\   /::\\~\\:\\  \\      /::\\__\\  /:/  /    /::\\~\\:\\  \\   _\\:\\~\\ \\  \\ ";
    echo " /:/__/ \\:|__| /:/__/ \\:\\__\\     /:/\\:\\__\\ /:/\\:\\ \\:\\__\\  __/:/\\/__/ /:/__/    /:/\\:\\ \\:\\__\\ /\\ \\:\\ \\ \\__\\";
    echo " \\:\\  \\ /:/  / \\:\\  \\ /:/  /    /:/  \\/__/ \\/__\\:\\ \\/__/ /\\/:/  /    \\:\\  \\    \\:\\~\\:\\ \\/__/ \\:\\ \\:\\ \\/__/";
    echo "  \\:\\  /:/  /   \\:\\  /:/  /    /:/  /           \\:\\__\\   \\::/__/      \\:\\  \\    \\:\\ \\:\\__\\    \\:\\ \\:\\__\\  ";
    echo "   \\:\\/:/  /     \\:\\/:/  /     \\/__/             \\/__/    \\:\\__\\       \\:\\  \\    \\:\\ \\/__/     \\:\\/:/  /  ";
    echo "    \\::/__/       \\::/  /                                  \\/__/        \\:\\__\\    \\:\\__\\        \\::/  /   ";
    echo "     ~~            \\/__/                                                 \\/__/     \\/__/         \\/__/    "; 
}

print_step() {
    local text="$1"
    local current="$2"
    local total="$3"
    echo -e "${B}[${current}/${total}]${NC} ${Y}➜${NC} ${BOLD}${text}${NC}"
}

print_success() {
    echo -e "${G}✔ ${1}${NC}"
}

print_error() {
    echo -e "${R}✖ ${1}${NC}"
}

print_info() {
    echo -e "${C}ℹ ${1}${NC}"
}


# --- DEFINICIÓN DE ENLACES ---

declare -a COMMON_LINKS=(
    "fastfetch/config.jsonc:.config/fastfetch/config.jsonc"
    "helix/config.toml:.config/helix/config.toml"
    "helix/languages.toml:.config/helix/languages.toml"
    "helix/themes:.config/helix/themes"
    "kitty/kitty.conf:.config/kitty/kitty.conf"
    "lazygit/config.yml:.config/lazygit/config.yml"
    #"nvim:.config/nvim" # Gestionado por install_nvchad
    "pipes-rs/config.toml:.config/pipes-rs/config.toml"
    "vscode/settings.json:.config/Code/User/settings.json"
    "yazi:.config/yazi"
)

declare -a ZSH_LINKS=(
    "zsh/.zshrc:.zshrc"
    "zsh/.zshrc.d:.zshrc.d"
    "zsh/.zsh_plugins.txt:.zsh_plugins.txt"
)

declare -a FISH_LINKS=(
    "fish/config.fish:.config/fish/config.fish"
    "fish/conf.d:.config/fish/conf.d"
)

declare -a NUSHELL_LINKS=(
    "nushell/config.nu:.config/nushell/config.nu"
    "nushell/env.nu:.config/nushell/env.nu"
    "nushell/aliases.nu:.config/nushell/aliases.nu"
)

# --- FUNCIONES ---

choose_shell() {
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}🤔 ¿Qué shell deseas configurar y usar por defecto?${NC}"
    echo -e "   ${G}1)${NC} zsh ${C}(Recomendado - Antidote + Plugins)${NC}"
    echo -e "   ${G}2)${NC} fish ${C}(Rápido y amigable)${NC}"
    
    local pm=$(get_pkg_manager)
    if [[ "$pm" == "pacman" ]]; then
         echo -e "   ${G}3)${NC} nushell ${C}(Experimental - Arch Only)${NC}"
    fi

    echo -e "${B}--------------------------------------------------${NC}"
    read -r -p "$(echo -e "${M}Select: ${NC}")" shell_choice
    case $shell_choice in
        1|zsh|Zsh|ZSH)
            SHELL_TO_INSTALL="zsh"
            ;;
        2|fish|Fish|FISH)
            SHELL_TO_INSTALL="fish"
            ;;
        3|nushell|nu|NU)
            if [[ "$pm" == "pacman" ]]; then
                SHELL_TO_INSTALL="nushell"
            else
                print_error "Nushell solo está soportado en Arch Linux por ahora."
                SHELL_TO_INSTALL="zsh"
            fi
            ;;
        *)
            print_error "Opción no válida. Usando zsh por defecto."
            SHELL_TO_INSTALL="zsh"
            ;;
    esac
    print_success "Has elegido: $SHELL_TO_INSTALL"
}

choose_starship() {
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}🚀 Configuración de Starship Prompt${NC}"
    echo -e "   ${G}1)${NC} Principal (Full/Pastel) - ${C}starship/starship.toml${NC}"
    echo -e "   ${G}2)${NC} Secundario (TokyoNight/Minimal) - ${C}starship/starship_2.toml${NC}"
    
    local choice
    read -r -p "$(echo -e "${M}Select (default 1): ${NC}")" choice
    
    if [[ "$choice" == "2" ]]; then
        STARSHIP_CONFIG="starship/starship_2.toml"
        print_success "Seleccionado Starship Secundario."
    else
        STARSHIP_CONFIG="starship/starship.toml"
        print_success "Seleccionado Starship Principal."
    fi
}

install_antidote() {
    local antidote_dir="${ZDOTDIR:-$HOME}/.antidote"
    if [[ ! -d "$antidote_dir" ]]; then
        echo "📦 Instalando Antidote (Zsh Plugin Manager)..."
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
    else
        echo "✅ Antidote ya está instalado."
    fi
}

setup_zoxide_for_shell() {
    local target_shell=$1
    print_step "Configurando Zoxide para $target_shell..." "1" "1"
    
    local default_init="$HOME/.cache/zoxide/init.$target_shell"
    
    if [[ "$target_shell" == "nushell" ]]; then
        echo -e "${Y}📍 Zoxide necesita generar un archivo init.${target_shell}.${NC}"
        echo -e "   Ruta por defecto sugerida en config.nu: ${C}$default_init${NC}"
        read -r -p "   ¿Dónde deseas guardarlo? (Enter para usar default): " custom_path
        
        if [[ -n "$custom_path" ]]; then
            default_init="$custom_path"
        fi
    fi
    
    # Expandir ~ si es necesario (el shell lo hace, pero si está entre comillas...)
    # Simplemente nos aseguramos que el directorio padre exista.
    local parent_dir=$(dirname "$default_init")
    if [[ ! -d "$parent_dir" ]]; then
        echo "📂 Creando directorio: $parent_dir"
        mkdir -p "$parent_dir"
    fi
    
    if command -v zoxide &> /dev/null; then
         echo "⚡ Generando init.$target_shell en $default_init..."
         if [[ "$target_shell" == "nushell" ]]; then
             zoxide init nushell --cmd cd > "$default_init"
         elif [[ "$target_shell" == "zsh" ]]; then
             zoxide init zsh > "$default_init"
             echo -e "${C}ℹ  Si zoxide no carga, asegúrate que se importe 'source $default_init' en tu config de Zsh.${NC}"
         elif [[ "$target_shell" == "fish" ]]; then
             zoxide init fish > "$default_init"
             echo -e "${C}ℹ  Si zoxide no carga, asegúrate que se importe 'source $default_init' en tu config de Fish.${NC}"
         fi
         print_success "Zoxide configurado en $default_init"
    else
         print_error "Zoxide no encontrado. Asegúrate de que se instaló correctamente."
    fi
}

install_pipes_rs() {
    if ! command -v pipes-rs &> /dev/null; then
        # Check especial para Arch: si estamos aquí y es Arch, quizás falló el install full o no se eligió.
        # Intentamos AUR primero si tenemos yay.
        if command -v yay &> /dev/null; then
            echo "📦 Instalando pipes-rs via AUR (yay)..."
            yay -S --needed --noconfirm pipes-rs
            return
        fi

        if command -v cargo &> /dev/null; then
            echo "📦 Instalando pipes-rs via cargo..."
            cargo install --git https://github.com/lhvy/pipes-rs
        else
            echo "⚠️  [ADVERTENCIA] 'cargo' no encontrado. No se puede instalar 'pipes-rs'."
            echo "   Instala Rust primero (ver rust-setup.md)."
        fi
    else
        echo "✅ pipes-rs ya está instalado."
    fi
}

install_betterfox() {
    print_step "Configurando Betterfox (user.js)..." "1" "1"
    local mozilla_dir="$HOME/.mozilla/firefox"
    local betterfox_url="https://raw.githubusercontent.com/Kat404/dotfiles/refs/heads/main/firefox%2BuBO/user.js"
    
    if [[ ! -d "$mozilla_dir" ]]; then
        print_info "No se encontró directorio de Firefox. Ejecuta Firefox una vez para crear el perfil."
        return
    fi
    
    # Buscar perfiles
    # Prioridad: *.default-release > *.default > cualquiera
    local target_profile=""
    
    # Intentar encontrar default-release
    local found_release=$(find "$mozilla_dir" -maxdepth 1 -type d -name "*.default-release" | head -n 1)
    if [[ -n "$found_release" ]]; then
        target_profile="$found_release"
    else
        # Intentar default
        local found_default=$(find "$mozilla_dir" -maxdepth 1 -type d -name "*.default" | head -n 1)
        if [[ -n "$found_default" ]]; then
             target_profile="$found_default"
        fi
    fi
    
    if [[ -z "$target_profile" ]]; then
        print_error "No se pudo detectar un perfil de Firefox válido automáticamente."
        print_info "Por favor, revisa la configuración o inicia Firefox primero."
    else
        echo -e "${C}Perfil detectado:${NC} $(basename "$target_profile")"
        
        # Asegurar curl
        if ! command -v curl &> /dev/null; then
            echo -e "${C}ℹ  Curl no encontrado. Instalando para descargar Betterfox...${NC}"
            install_pkg curl
        fi
        
        echo -ne "${Y}⬇️  Descargando Betterfox desde GitHub... ${NC}"
        if curl -sL "$betterfox_url" -o "$target_profile/user.js"; then
            echo -e "${G}OK${NC}"
            print_success "Betterfox aplicado correctamente."
        else
            echo -e "${R}Fallo${NC}"
            print_error "Error al descargar el user.js de Betterfox."
        fi
    fi
}

install_nvchad() {
    print_step "Configurando Neovim (NvChad)..." "1" "1"
    
    # Check de versión (Requiere >= 0.11.0)
    if ! command -v nvim &> /dev/null; then
        print_error "Neovim no está instalado. Saltando configuración NvChad."
        return
    fi
    
    local nvim_version=$(nvim --version | head -n 1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//')
    # Comparación básica de semver (asumimos formato X.Y.Z)
    local major=$(echo "$nvim_version" | cut -d. -f1)
    local minor=$(echo "$nvim_version" | cut -d. -f2)
    
    echo -e "   Versión detectada: ${C}v$nvim_version${NC}"
    
    if [[ "$major" -lt 0 || ("$major" -eq 0 && "$minor" -lt 11) ]]; then
        print_error "NvChad requiere Neovim >= 0.11.0. Tienes v$nvim_version."
        print_info "Saltando configuración NvChad."
        return
    fi
    
    # Directorios
    local nvim_config="$HOME/.config/nvim"
    local nvim_share="$HOME/.local/share/nvim"
    local nvim_state="$HOME/.local/state/nvim"
    local nvim_cache="$HOME/.cache/nvim"
    
    # Backup si existe
    if [[ -d "$nvim_config" ]]; then
        # Verificar si ya es NvChad para no sobreescribir repetidamente si se corre el script varias veces
        # (Opcional, pero por ahora hacemos backup siempre para asegurar limpieza)
        echo -e "${Y}⚠️  Moviendo configuración existente de Neovim a backup...${NC}"
        mv "$nvim_config" "$BACKUP_DIR/nvim_backup_$(date +%s)"
        
        # Limpiar cache/share para evitar conflictos de plugins antiguos
        rm -rf "$nvim_share" "$nvim_state" "$nvim_cache"
    fi
    
    echo "📦 Clonando NvChad Starter..."
    git clone https://github.com/NvChad/starter "$nvim_config"
    
    # Quitar git history
    rm -rf "$nvim_config/.git"
    
    # Copiar options.lua custom
    local custom_options="$DOTFILES_DIR/nvim/options.lua"
    if [[ -f "$custom_options" ]]; then
        echo "📄 Copiando options.lua personalizado..."
        cp "$custom_options" "$nvim_config/lua/options.lua"
    else
        print_error "No se encontró $custom_options"
    fi
    
    print_success "NvChad instalado. Ejecuta 'nvim' para instalar plugins."
}

install_maple_font() {
    print_step "Instalando fuente Maple Mono NF..." "1" "1"
    
    echo -e "${Y}🖥️  ¿Tu monitor tiene una resolución MAYOR a 1080p (2K/4K)?${NC}"
    echo -e "   (Esto determinará qué versión de la fuente se instala)"
    read -r -p "   (s/n): " res_opt
    
    local file_name="MapleMono-NF.zip"
    if [[ "$res_opt" =~ ^[sS]$ ]]; then
        file_name="MapleMono-NF-unhinted.zip"
        print_info "Seleccionada versión Unhinted (High DPI)."
    else
        print_info "Seleccionada versión Standard (<=1080p)."
    fi
    
    local url="https://github.com/subframe7536/maple-font/releases/latest/download/$file_name"
    local fonts_dir="$HOME/.fonts"
    local temp_dir=$(mktemp -d)
    
    mkdir -p "$fonts_dir"
    
    echo "⬇️  Descargando $file_name..."
    # Asegurar curl
    if ! command -v curl &> /dev/null; then install_pkg curl; fi
    
    if curl -sL "$url" -o "$temp_dir/$file_name"; then
        echo "📦 Descomprimiendo en $fonts_dir..."
        
        # Intentar usar unzip o 7z
        if command -v unzip &> /dev/null; then
            unzip -o -q "$temp_dir/$file_name" -d "$fonts_dir"
        elif command -v 7z &> /dev/null; then
            # 7z suele venir con el paquete '7zip' o 'p7zip' que instalamos
            7z x -y -o"$fonts_dir" "$temp_dir/$file_name" > /dev/null
        else
            echo -e "${C}ℹ  Intentando instalar unzip para descomprimir...${NC}"
            install_pkg unzip
            unzip -o -q "$temp_dir/$file_name" -d "$fonts_dir"
        fi
        
        echo "🔄 Actualizando caché de fuentes..."
        fc-cache -f "$fonts_dir"
        
        print_success "Maple Mono NF instalada."
        echo -e "${C}ℹ  Recuerda configurar tu terminal/IDE para usar 'Maple Mono NF'.${NC}"
    else
        print_error "Error al descargar la fuente desde $url"
        rm -rf "$temp_dir"
        return 1
    fi
    rm -rf "$temp_dir"
}

get_pkg_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v brew &> /dev/null; then
        echo "brew"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

install_pkg() {
    local pm=$(get_pkg_manager)

    echo -ne "${Y}📦 Instalando $* con $pm... ${NC}"
    
    # Nota: Usamos "$@" para permitir múltiples paquetes.
    # set +e permite capturar el fallo si 'install_pkg' se usa en un 'if'.
    case $pm in
        pacman)
            if sudo pacman -S --noconfirm --needed "$@" &> /dev/null; then
                echo -e "${G}OK${NC}"
            else
                # Fallback verbose si falla el silencio
                echo -e "${R}Falló en modo silencioso, reintentando con salida...${NC}"
                sudo pacman -S --noconfirm --needed "$@"
            fi
            ;;
        apt)
            if sudo apt-get update -qq && sudo apt-get install -y "$@" &> /dev/null; then
                echo -e "${G}OK${NC}"
            else
                echo -e "${R}Fallo${NC}"
                return 1
            fi
            ;;
        dnf)
            if sudo dnf install -y "$@" &> /dev/null; then
                echo -e "${G}OK${NC}"
            else
                echo -e "${R}Fallo${NC}"
                return 1
            fi
            ;;
        brew)
            if brew install "$@" &> /dev/null; then
                echo -e "${G}OK${NC}"
            else
                echo -e "${R}Fallo${NC}"
                return 1
            fi
            ;;
        zypper)
            if sudo zypper install -y --no-recommends "$@" &> /dev/null; then
                echo -e "${G}OK${NC}"
            else
                echo -e "${R}Fallo${NC}"
                return 1
            fi
            ;;
        *)
            print_error "Gestor de paquetes no soportado: $pm"
            return 1
            ;;
    esac
}

install_common_dependencies() {
    echo "📦 Instalando dependencias comunes (ffmpeg, 7zip, jq, fzf...)..."
    local pm=$(get_pkg_manager)
    local pkgs=()
    
    case $pm in
        apt)
            # Nombres específicos para Debian/Ubuntu
            pkgs=(ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick unclutter helix build-essential libssl-dev pkg-config)
            ;;
        pacman)
            # Nombres específicos para Arch
            pkgs=(ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick unclutter helix base-devel)
            ;;
        dnf)
            # Nombres para Fedora
            pkgs=(ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide ImageMagick unclutter helix)
            ;;
        brew)
            # Nombres para macOS
            pkgs=(ffmpeg sevenzip jq poppler fd ripgrep fzf zoxide imagemagick unclutter helix)
            ;;
        zypper)
            # Nombres para openSUSE (Leap/Tumbleweed)
            pkgs=(ffmpeg p7zip jq poppler-tools fd ripgrep fzf zoxide ImageMagick unclutter helix gcc gcc-c++ make libopenssl-devel)
            ;;
        *)
            echo "⚠️  No se pueden instalar dependencias comunes automáticamente en $pm."
            return
            ;;
    esac

    for pkg in "${pkgs[@]}"; do
        if ! install_pkg "$pkg"; then
            echo -e "${Y}⚠️  Sugerencia: El paquete '${pkg}' no se encontró o falló. Te sugiero una instalación nativa (compilando desde fuente u obteniendo el binario oficial).${NC}"
        fi
    done
}

install_yazi() {
    if command -v yazi &> /dev/null; then
        echo "✅ yazi ya está instalado."
        return
    fi

    echo "📦 Buscando yazi en repositorios oficiales..."
    
    # Intentamos instalar desde el gestor de paquetes.
    # Usamos ( ... ) o set +e para evitar que el script muera si falla.
    if install_pkg yazi; then
        echo "✅ yazi instalado desde repositorios."
    else
        echo "⚠️  yazi no encontrado en repositorios (o falló la instalación)."
        echo "🛠️  Construyendo yazi desde source (Cargo)..."
        
        if command -v cargo &> /dev/null; then
            # Dependencias de build para yazi (aseguradas en install_common_dependencies si es posible)
            # Clonar y construir
            local build_dir=$(mktemp -d)
            echo "📂 Directorio temporal: $build_dir"
            
            git clone https://github.com/sxyazi/yazi.git "$build_dir/yazi"
            pushd "$build_dir/yazi"
            
            cargo build --release --locked
            
            echo "📦 Moviendo binarios a /usr/local/bin..."
            sudo mv target/release/yazi target/release/ya /usr/local/bin/
            
            popd
            rm -rf "$build_dir"
            echo "✅ yazi compilado e instalado exitosamente."
        else
            echo "❌ Error: Cargo no está instalado. No se puede compilar yazi."
            echo "   Asegúrate de que Rust/Cargo se instaló correctamente en el paso anterior."
        fi
    fi
}


install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "📦 Instalando yay-bin (AUR Helper)..."
        # Asegurar base-devel y git
        sudo pacman -S --needed --noconfirm git base-devel
        
        local temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$temp_dir/yay-bin"
        pushd "$temp_dir/yay-bin"
        makepkg -si --noconfirm
        popd
        rm -rf "$temp_dir"
        echo "✅ Yay instalado."
    else
        echo "✅ Yay ya está instalado."
    fi
}

install_arch_full() {
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}🐲 Detectado Arch Linux.${NC}"
    echo -e "   Se ha encontrado una configuración recomendada ('fresh-install.md')."
    echo -e "   Esto optimizará Pacman, instalará Yay, paquetería completa, tu IDE y más."
    echo -e "${B}--------------------------------------------------${NC}"
    read -r -p "$(echo -e "${Y}¿Deseas proceder con la 'Instalación Completa de Arch'? (s/n): ${NC}")" arch_choice
    
    if [[ "$arch_choice" =~ ^[sS]$ ]]; then
        
        # --- 0. Pacman Tweaks (fresh-install.md) ---
        print_step "Optimizando Pacman..." "1" "5"
        if [[ -f "/etc/pacman.conf" ]]; then
            # Habilitar Color (si está comentado o no existe, nos aseguramos que esté activo)
            # Simplemente descomentamos
            sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
            
            # Habilitar VerbosePkgLists
            sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
            
            # ILoveCandy (Debajo de color)
            if ! grep -q "ILoveCandy" /etc/pacman.conf; then
                sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
            fi
            
            # ParallelDownloads
            if grep -q "#ParallelDownloads" /etc/pacman.conf; then
                sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
            elif grep -q "ParallelDownloads" /etc/pacman.conf; then
                # Si ya está activo pero con otro número, lo cambiamos a 10
                sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
            fi
            
            print_success "Pacman optimizado (Candy + ParallelDownloads)."
        fi
        
        install_yay
        
        # --- Construcción de listas de paquetes ---
        
        local pacman_pkgs=(
            "noto-fonts-emoji" "firefox" "kitty" "${SHELL_TO_INSTALL}" "nodejs" "gufw" 
            "ttf-jetbrains-mono-nerd" "ttf-ubuntu-font-family" "yazi" "ffmpeg" 
            "7zip" "jq" "poppler" "fd" "ripgrep" "fzf" "zoxide" "resvg" "unclutter"
            "imagemagick" "libayatana-appindicator" "keepassxc" "signal-desktop" 
            "proton-vpn-gtk-app" "neovim" "helix" "lazygit" "less" "reflector" 
            "pacman-contrib" "starship" "fastfetch" "eza" "bat"
            "cmatrix" "cava" "libreoffice-fresh" "libreoffice-fresh-es"
            "xdg-user-dirs" "asciiquarium"
        ) 

        
        local yay_pkgs=("carapace-bin")
        
        # 2. Detección Inteligente / Excepciones (L34-L39)
        
        # Desktop Environment Integration
        if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
            echo "   desktop: GNOME detectado -> Agregando integración."
            pacman_pkgs+=("gnome-keyring" "gnome-shell-extension-appindicator")
        elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"XFCE"* || "${XDG_CURRENT_DESKTOP:-}" == *"Cinnamon"* ]]; then
            echo "   desktop: XFCE/Cinnamon detectado -> Agregando gnome-keyring."
            pacman_pkgs+=("gnome-keyring")
        else
            echo "   desktop: Otro/Desconocido -> Saltando integraciones específicas de DE."
        fi
        
        # Clipboard (Wayland vs X11)
        if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
            echo "   session: Wayland -> Agregando wl-clipboard."
            pacman_pkgs+=("wl-clipboard")
        else
            echo "   session: X11 (o desconocido) -> Agregando xclip."
            pacman_pkgs+=("xclip")
        fi
        
        # 3. Selección Interactiva
        
        # IDE
        echo ""
        echo "🖥️  Elige tu IDE favorito:"
        echo "   1) Visual Studio Code (bin)"
        echo "   2) Windsurf"
        echo "   3) Antigravity"
        echo "   4) VSCodium (bin)"
        echo "   5) Ninguno"
        read -r -p "Opción: " ide_opt
        case $ide_opt in
            1) yay_pkgs+=("visual-studio-code-bin");;
            2) yay_pkgs+=("windsurf");;
            3) yay_pkgs+=("antigravity");;
            4) 
                yay_pkgs+=("vscodium-bin")
                echo ""
                echo "🏪 ¿Deseas activar el Marketplace Oficial de VSCode en VSCodium?"
                echo "   (Instala 'vscodium-bin-marketplace')"
                read -r -p "   (s/n): " vscodium_mk_opt
                if [[ "$vscodium_mk_opt" =~ ^[sS]$ ]]; then
                    yay_pkgs+=("vscodium-bin-marketplace")
                fi
                ;;
            *) echo "   Sin IDE específico seleccionado.";;
        esac
        
        # Browser Flavor (Phoenix vs Stock Firefox)
        # Firefox ya está en base, pero Phoenix es extra
        echo ""
        echo "🔥 ¿Deseas instalar Phoenix Arch (versión custom de Firefox)?"
        echo "   (Se instalará junto a Firefox base)"
        read -r -p "   (s/n): " phoenix_opt
        if [[ "$phoenix_opt" =~ ^[sS]$ ]]; then
            yay_pkgs+=("phoenix-arch")
            # Phoenix y Betterfox son mutuamente excluyentes
            betterfox_opt="n"
        else
            # Solo ofrecemos Betterfox si NO se eligió Phoenix
            # Betterfox (user.js)
            echo ""
            echo "🦊 ¿Deseas aplicar Betterfox (user.js) a tu perfil de Firefox?"
            echo "   (Optimización de privacidad, seguridad y velocidad)"
            read -r -p "   (s/n): " betterfox_opt
        fi

        # Cryptomator (Opcional)
        echo ""
        echo "🔒 ¿Deseas instalar Cryptomator (Cifrado de archivos)?"
        read -r -p "   (s/n): " crypto_opt
        if [[ "$crypto_opt" =~ ^[sS]$ ]]; then
            yay_pkgs+=("cryptomator")
        fi
        
        # --- Instalación ---
        
        echo "📦 Instalando paquetes oficiales (Pacman)..."
        sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
        
        echo "📦 Instalando paquetes de AUR (Yay)..."
        yay -S --needed --noconfirm "${yay_pkgs[@]}"
        
        # Betterfox Execution
        if [[ "$betterfox_opt" =~ ^[sS]$ ]]; then
             install_betterfox
        fi
        
        return 0 # Éxito, instaló todo
    else
        return 1 # El usuario rechazó la full install
    fi
}

check_and_install_software() {
    local target_shell=$1
    local pm=$(get_pkg_manager)

    # Lógica especial para Arch Linux
    if [[ "$pm" == "pacman" ]]; then
        if install_arch_full; then
            # Si se ejecutó la instalación full, ya tenemos casi todo.
            # Solo verificamos rustup si no estaba en la lista (no estaba explícitamente, pero fresh-install dice 'antigravity' o 'windsurf' que pueden usarlo)
            # fresh-install NO lista rustup en el comando pacman, pero rust-setup.md sí.
            # Verificamos rustup por si acaso.
            if ! command -v rustup &> /dev/null; then
                 install_pkg rustup
            fi
            
            # Configurar Rust (Necesario para pipes-rs aunque sea por AUR muchas veces o para yazi source)
            if command -v rustup &> /dev/null; then
                 if ! rustup toolchain list | grep -q "stable"; then
                     echo "⚙️  Configurando Rust (rustup default stable)..."
                     rustup default stable
                     if [[ -f "$HOME/.cargo/env" ]]; then source "$HOME/.cargo/env"; fi
                 fi
            fi

            # Instalar pipes-rs desde AUR si estamos en Arch Full Install
            echo "📦 Instalando pipes-rs desde AUR..."
            if command -v yay &> /dev/null; then
                 yay -S --needed --noconfirm pipes-rs
            fi
            
            return # Salimos, ya hicimos el trabajo pesado de Arch
        fi
        # Si el usuario dijo "No", continuamos con la lógica normal abajo...
    fi

    # --- Lógica Normal (No Arch o Arch rechazada) ---
    echo "🔍 Verificando software necesario (Instalación Estándar)..."

    # LibreOffice (Opcional fuera de Arch Full)
    if ! command -v libreoffice &> /dev/null && ! command -v soffice &> /dev/null; then
        echo ""
        echo "📊 ¿Deseas instalar LibreOffice?"
        read -r -p "   (s/n): " lo_opt
        if [[ "$lo_opt" =~ ^[sS]$ ]]; then
            case $pm in
                pacman) install_pkg libreoffice-fresh libreoffice-fresh-es ;;
                apt)    install_pkg libreoffice libreoffice-l10n-es ;;
                dnf)    install_pkg libreoffice libreoffice-langpack-es ;;
                *)      install_pkg libreoffice ;;
            esac
        fi
    fi
    
    # Lista base + shell seleccionada
    local tools=("kitty" "lazygit" "nvim:neovim" "hx:helix" "fastfetch" "rustup" "$target_shell")

    for tool_spec in "${tools[@]}"; do
        IFS=":" read -r cmd pkg <<< "$tool_spec"
        if [[ -z "$pkg" ]]; then pkg="$cmd"; fi

        if ! command -v "$cmd" &> /dev/null; then
             # Pasamos solo el nombre del paquete
             if ! install_pkg "$pkg"; then
                 echo -e "${Y}⚠️  Sugerencia: El paquete '${pkg}' no está disponible o falló en tu gestor. Considera realizar una instalación nativa (desde código fuente o binario oficial).${NC}"
             fi
        else
             echo "✅ $cmd ya está instalado."
        fi
    done
    
    # Starship (Gestión especial para fallback)
    if ! command -v starship &> /dev/null; then
        if ! install_pkg starship; then
            print_error "No se pudo instalar Starship automáticamente con tu gestor de paquetes."
            print_info "Se aplicará la configuración (.toml), pero necesitarás instalar 'starship' manualmente para ver el prompt."
        fi
    else
        echo "✅ starship ya está instalado."
    fi
    
    # Configuración específica de Rust
    if command -v rustup &> /dev/null; then
         # Verificar si hay toolchain instalado, si no, instalar default stable
         if ! rustup toolchain list | grep -q "stable"; then
             echo "⚙️  Configurando Rust (rustup default stable)..."
             rustup default stable
             
             # Cargar el entorno de cargo para que esté disponible inmediatamente
             if [[ -f "$HOME/.cargo/env" ]]; then
                 source "$HOME/.cargo/env"
             fi
         fi
    fi

    # Instalación de dependencias comunes (ffmpeg, etc.)
    install_common_dependencies
    
    # Instalación de Yazi (Repo o Cargo)
    install_yazi
}

apply_security_hardening() {
    print_step "Verificando compatibilidad de hardening..." "1" "1"
    
    # 1. Verificar Systemd (pid 1 suele ser systemd o init simlink)
    if [[ ! -d "/run/systemd/system" ]]; then
        print_info "Systemd no detectado. Saltando hardening de kernel (requiere systemd-sysctl)."
        return
    fi
    
    echo -e "${B}--------------------------------------------------${NC}"
    echo -e "${Y}🛡️  HARDENING DEL KERNEL (SEGURIDAD)${NC}"
    echo -e "   Se pueden aplicar configuraciones de sysctl para mejorar la seguridad."
    echo -e "   Fuente: ${C}github.com/Kat404/linux_security.conf${NC}"
    echo -e "${B}--------------------------------------------------${NC}"
    
    read -r -p "$(echo -e "${Y}¿Deseas descargar y aplicar estas protecciones? (s/n): ${NC}")" secure_opt
    if [[ "$secure_opt" =~ ^[sS]$ ]]; then
        print_step "Aplicando hardening..." "1" "2"
        
        local sysctl_url="https://raw.githubusercontent.com/Kat404/linux_security.conf/refs/heads/main/99-linux-security-es.conf"
        local sysctl_dest="/etc/sysctl.d/99-linux-security.conf"
        
        echo -ne "${Y}⬇️  Descargando configuración... ${NC}"
        
        # Asegurar que curl esté instalado
        if ! command -v curl &> /dev/null; then
            echo -e "${C}ℹ  Curl no encontrado. Instalando...${NC}"
            install_pkg curl
        fi

        if sudo curl -sL "$sysctl_url" -o "$sysctl_dest"; then
            echo -e "${G}OK${NC}"
            
            echo -ne "${Y}🔒 Aplicando reglas de kernel... ${NC}"
            if sudo sysctl --system &> /dev/null; then
                 echo -e "${G}OK${NC}"
                 print_success "Hardening aplicado correctamente."
            else
                 print_error "Error al aplicar 'sysctl --system'. Revisa $sysctl_dest"
            fi
        else
            print_error "Error al descargar la configuración."
        fi
    else
        print_info "Saltando hardening."
    fi
}

setup_unclutter_shortcut() {
    print_step "Configurando atajo de teclado para Unclutter..." "1" "1"
    
    local cmd="sh -c \"pkill -x unclutter && notify-send 'Mouse: Visible' || (unclutter --idle 0.5 --jitter 15 --ignore-scrolling & notify-send 'Mouse: Auto-Ocultar')\""
    # Nota: Usamos <Ctrl><Super>question para intentar machear '¿' en layout español, o el keycode correspondiente.
    # En XFCE suele ser legible como <Primary><Super>question o similar.
    
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"XFCE"* ]]; then
        # XFCE4
        # Requiere xfconf-query
        if command -v xfconf-query &> /dev/null; then
            echo -e "${C}Configurando para XFCE...${NC}"
            # Intentamos establecer el atajo. La sintaxis de teclas puede variar.
            # <Primary> es Ctrl en Xfce. <Super> es Windows.
            xfconf-query --create --channel xfce4-keyboard-shortcuts --property "/commands/custom/<Primary><Super>question" --type string --set "$cmd"
            print_success "Atajo configurado en XFCE (Ctrl + Super + ¿)"
        else
            print_error "xfconf-query no encontrado."
        fi

    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* || "${XDG_CURRENT_DESKTOP:-}" == *"Cinnamon"* ]]; then
        # GNOME / Cinnamon
        # Configurar esto por script es complejo y propenso a romper índices array.
        # Imprimimos instrucciones claras.
        echo -e "${Y}⚠️  Para GNOME/Cinnamon, configuración manual recomendada:${NC}"
        echo -e "   1. Abre Configuración > Teclado > Atajos."
        echo -e "   2. Crea un atajo personalizado:"
        echo -e "      Nombre: Toggle Mouse"
        echo -e "      Comando: ${BOLD}$cmd${NC}"
        echo -e "      Atajo: Ctrl + Super + ¿"

    elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
        # KDE Plasma
        echo -e "${Y}⚠️  Para KDE Plasma:${NC}"
        echo -e "   1. Abre Configuración del Sistema > Atajos > Atajos Personalizados."
        echo -e "   2. Crea un nuevo atajo global."
        echo -e "      Acción/Comando: ${BOLD}$cmd${NC}"
        echo -e "      Tecla: Ctrl + Meta + ¿"
        
    else
        echo -e "${C}ℹ  Entorno no reconocido automáticamente para atajos ($XDG_CURRENT_DESKTOP).${NC}"
        echo -e "   Comando a configurar: ${BOLD}$cmd${NC}"
    fi
}

# --- INICIO DEL SCRIPT ---

echo "🚀 Iniciando instalación de dotfiles..."
print_banner
choose_shell
choose_starship

echo "Repositiorio de dotfiles: $DOTFILES_DIR"
echo "--------------------------------------------------"

echo "🔧 Verificando dependencias..."
check_and_install_software "$SHELL_TO_INSTALL"

# Añadir configuración de Starship elegida
COMMON_LINKS+=("$STARSHIP_CONFIG:.config/starship.toml")

# Configuración condicional según el shell
declare -a FILES_TO_LINK
if [[ "$SHELL_TO_INSTALL" == "zsh" ]]; then
    install_antidote
    FILES_TO_LINK=("${COMMON_LINKS[@]}" "${ZSH_LINKS[@]}")
elif [[ "$SHELL_TO_INSTALL" == "nushell" ]]; then
    FILES_TO_LINK=("${COMMON_LINKS[@]}" "${NUSHELL_LINKS[@]}")
else
    FILES_TO_LINK=("${COMMON_LINKS[@]}" "${FISH_LINKS[@]}")
fi

# Zoxide setup se debe generar para independientemente del shell que seleccione el usuario.
# Lo haremos aquí para mantener la estructura original, antes del linking final de archivos.
setup_zoxide_for_shell "$SHELL_TO_INSTALL"

install_pipes_rs
echo "--------------------------------------------------"

for link_pair in "${FILES_TO_LINK[@]}"; do
    IFS=":" read -r source_rel dest_rel <<< "$link_pair"

    source_abs="$DOTFILES_DIR/$source_rel"
    dest_abs="$HOME/$dest_rel"

    # 1. Comprobar que el archivo de origen existe en el repositorio.
    if [[ ! -e "$source_abs" ]]; then
        echo "⚠️  [SALTANDO] Archivo de origen no encontrado: $source_abs"
        continue
    fi

    # Si el destino ya es un enlace simbólico apuntando al origen correcto, no hacer nada.
    if [[ -L "$dest_abs" && "$(readlink "$dest_abs")" == "$source_abs" ]]; then
        echo "✅  [ENLAZADO] $dest_abs"
        continue
    fi

    # Si el archivo de destino ya existe (y no es el enlace correcto), moverlo a backup.
    if [[ -e "$dest_abs" ]]; then
        # Solo crear el directorio de backup si es necesario
        if [[ ! -d "$BACKUP_DIR" ]]; then
            echo "📦 Creando directorio de backup en: $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
        fi
        echo "🛡️  [BACKUP] Moviendo archivo existente: $dest_abs"
        # Mover al directorio de backup, creando la estructura de carpetas si es necesario
        mkdir -p "$(dirname "$BACKUP_DIR/$dest_rel")"
        mv "$dest_abs" "$BACKUP_DIR/$dest_rel"
    fi

    # Crear el directorio padre del destino si no existe
    mkdir -p "$(dirname "$dest_abs")"

    # Crear el enlace simbólico.
    echo "🔗  [ENLAZANDO] $dest_abs -> $source_abs"
    ln -s "$source_abs" "$dest_abs"

done

echo -e "${B}--------------------------------------------------${NC}"
install_nvchad

echo -e "${B}--------------------------------------------------${NC}"
install_maple_font

echo -e "${B}--------------------------------------------------${NC}"
apply_security_hardening

echo -e "${B}--------------------------------------------------${NC}"
setup_unclutter_shortcut

echo -e "${B}--------------------------------------------------${NC}"
echo -e "${Y}🔄 Configurando shell por defecto...${NC}"

path_to_shell=$(which "$SHELL_TO_INSTALL")
if [[ "$SHELL" != "$path_to_shell" ]]; then
    echo "Cambiendo shell por defecto a $path_to_shell"
    # Usar sudo solo si es necesario, pero chsh suele pedir password por su cuenta o no requerirlo para el propio usuario
    # Dependiendo de la config de PAM. Lo ejecutamos directamente.
    chsh -s "$path_to_shell" || echo "⚠️  No se pudo cambiar el shell automáticamente. Puedes hacerlo manualmente con: chsh -s $path_to_shell"
    echo "✅ Shell cambiado. Reinicia tu sesión para ver los cambios."
else
    echo "✅ Tu shell ya es $SHELL_TO_INSTALL."
fi

echo "--------------------------------------------------"
echo "🎉 ¡Instalación completada!"
echo "Se han creado los enlaces simbólicos y configurado el entorno."
echo "Si tenías archivos de configuración previos, se han guardado en $BACKUP_DIR"
