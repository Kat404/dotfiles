# env.nu
#
# Installed by:
# version = "0.110.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.
# ~/.config/nushell/env.nu

# Inicializa Carapace desde el source (Necesario tener Carapace instalado)
# $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional
# mkdir $"($nu.cache-dir)"
# carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

# Define a Helix para una integración total del sistema Nushell con él
$env.EDITOR = "helix"
$env.VISUAL = "helix"

# Configuración de binarios de Cargo
$env.PATH = (
    $env.PATH 
    | split row (char esep) 
    | prepend $"($env.HOME)/.cargo/bin"
)

# Configuración de Bun (Necesario tener instalado Bun)
# $env.BUN_INSTALL = $"($env.HOME)/.bun"
# $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.BUN_INSTALL)/bin")

# Configuración de Nim (Necesario tener instalado Nim)
# $env.PATH = ($env.PATH | split row (char esep) | prepend "/home/josel/.nimble/bin")
