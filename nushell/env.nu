# env.nu
#
# Installed by:
# version = "0.109.1"
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
#
# ~/.config/nushell/env.nu

# Define a Neovim para una integración total del sistema Nushell con él
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Configuración de Bun 
$env.BUN_INSTALL = $"($env.HOME)/.bun"
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.BUN_INSTALL)/bin")

# Configuración de Nim 
$env.PATH = ($env.PATH | split row (char esep) | prepend "/home/josel/.nimble/bin")
