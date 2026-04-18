# env.nu
#
# Installed by:
# version = "0.112.2"
#
# ~/.config/nushell/env.nu

# ❯ Variables Esenciales & Editor {
$env.EDITOR = "helix"
$env.VISUAL = "helix"
# }

# ❯ Integración de Herramientas Externas (FZF & Caparace) {
# Inicialización de Carapace
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"

# Configuración Visual Global de FZF (Catppuccin Mocha)
$env.FZF_DEFAULT_OPTS = "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --border=rounded --border-label=' ◆ fzf ◆ ' --border-label-pos=3:-3:top --layout=reverse --height=45% --padding=1,3 --margin=1,2 --info=inline-right --pointer='❯ ' --marker='◆ ' --separator='─' --multi"

# Búsqueda optimizada con 'fd'
$env.FZF_DEFAULT_COMMAND = "fd --type f --color=never --hidden --exclude .git --exclude node_modules --exclude .cache"

# Zoxide + FZF (Visualización con Eza)
$env._ZO_FZF_OPTS = "--preview 'eza --tree --color=always --icons=always --group-directories-first --level=3 {2..}' --preview-window='right:50%:rounded' --header='📁 Zoxide Navegación'"
# }

# ❯ Variables de Runtime & Lenguajes {
$env.BUN_INSTALL = $"($env.HOME)/.bun"
$env.PNPM_HOME = $"($env.HOME)/.local/share/pnpm"
# }

# ❯ Gestión 'Awesome' del PATH >_< {
let binary_paths = [
    $"($env.HOME)/.cargo/bin"
    $"($env.BUN_INSTALL)/bin"
    $env.PNPM_HOME
]

$env.PATH = (
    $env.PATH 
    | split row (char esep) 
    | prepend $binary_paths 
    | uniq
)
# }
