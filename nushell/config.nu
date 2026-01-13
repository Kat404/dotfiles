# config.nu
#
# Installed by:
# version = "0.109.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
#
# ~/.config/nushell/config.nu

# Importa Plugins Core (Únicamente si se quieren usar plugins)
# const NU_PLUGIN_DIRS = [
#   ($nu.current-exe | path dirname)
#   ...$NU_PLUGIN_DIRS
# ]

# Inicializa Carapace (Necesario tener instalado Carapace)
# source $"($nu.cache-dir)/carapace.nu"

# Define a Neovim para editor de texto
$env.config = {
    buffer_editor: "nvim" 
}

# Almacenamos todo el historial de comandos con SQLite
$env.config.history = {
  file_format: sqlite
  max_size: 1_000_000
  sync_on_enter: true
  isolation: false
}

# Sourcea todos los aliases configurados
source ~/.config/nushell/aliases.nu

# Carga zoxide (Necesario tener instalado Zoxide)
source ~/.cache/zoxide/init.nu

# Evita que aparezca el banner de bienvenida al iniciar Nushell
$env.config.show_banner = false

# Inicializar Starship
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
