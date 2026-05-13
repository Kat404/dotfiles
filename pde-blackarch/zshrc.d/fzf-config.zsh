# ╔═══════════════════════════════════════════════════════════════════════╗
# ║                   🔍 FZF Configuration - Catppuccin Mocha             ║
# ║                   Unix Porn Ready™ with bat & Icons                   ║
# ╚═══════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────
# 🎨 Catppuccin Mocha Theme - Main Configuration
# ─────────────────────────────────────────────────────────────────────────

export FZF_DEFAULT_OPTS='
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --border=rounded
  --border-label=" ◆ fzf ◆ "
  --border-label-pos=3:-3:top
  --layout=reverse
  --height=45%
  --padding=1,3
  --margin=1,2
  --info=inline-right
  --preview-window="right:55%:rounded:border-sharp"
  --bind=ctrl-/:toggle-preview
  --bind=ctrl-a:select-all
  --bind=ctrl-d:deselect-all
  --bind=ctrl-y:yank
  --pointer="❯ "
  --marker="◆ "
  --separator="─"
  --multi
'

# ─────────────────────────────────────────────────────────────────────────
# 📂 File Preview with Bat (Ctrl+T)
# ─────────────────────────────────────────────────────────────────────────

if command -v bat &> /dev/null; then
  export FZF_CTRL_T_OPTS="
    --preview 'bat --color=always --line-range :500 --theme=Catppuccin\ Mocha {}'
    --preview-window='right:55%:rounded'
    --bind 'ctrl-/:toggle-preview'
    --header='📄 Files Preview (Ctrl+/ to toggle)' 
  "
fi

# ─────────────────────────────────────────────────────────────────────────
# 🏠 Directory Navigation (Alt+C)
# ─────────────────────────────────────────────────────────────────────────

export FZF_ALT_C_OPTS="
  --preview 'eza --tree --color=always --group-directories-first --level=2 {}'
  --preview-window='right:50%:rounded'
  --header='📁 Navigate Directories (Ctrl+/ to toggle)'
  --bind 'ctrl-/:toggle-preview'
"

# ─────────────────────────────────────────────────────────────────────────
# 🔍 Command History (Ctrl+R)
# ─────────────────────────────────────────────────────────────────────────

export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window='right:50%:rounded:border-sharp'
  --header='🕐 Search History'
  --bind 'ctrl-/:toggle-preview'
  --info=inline-right
"

# ─────────────────────────────────────────────────────────────────────────
# 🔗 Fuzzy Completion - Fzf Integration
# ─────────────────────────────────────────────────────────────────────────

# Sourcea fzf keybindings y completions automáticamente
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# ─────────────────────────────────────────────────────────────────────────
# ⚙️ Advanced Functions & Aliases
# ─────────────────────────────────────────────────────────────────────────

# 🎯 fzf-find: Búsqueda avanzada de archivos con ripgrep
fzf-find() {
  rg --files --color=never --hidden --smart-case \
    --glob='!.git' --glob='!node_modules' --glob='!.cache' "$@" | \
  fzf --multi --preview 'bat --color=always --theme=Catppuccin\ Mocha {}'
}

# 🔎 fzf-grep: Búsqueda de contenido en archivos
fzf-grep() {
  local query="${1:-.}"
  rg --color=always --line-number "$query" | \
  fzf --ansi --multi --delimiter=':' --preview 'bat --color=always --theme=Catppuccin\ Mocha --line-range {2}:{2} {1}' \
    --preview-window='right:60%:+{2}/2'
}

# 📁 fzf-folder: Navegar carpetas de forma rápida (incluye git dirs)
fzf-folder() {
  fd --type d --hidden --exclude .git --exclude node_modules --exclude .cache | \
  fzf --multi --preview 'eza --tree --color=always --group-directories-first --level=2 {}' \
    --preview-window='right:50%:rounded'
}

# 🐙 fzf-git: Ver cambios de git interactivamente
fzf-git() {
  git -c color.status=always status --short | \
  fzf --ansi --preview 'git diff --color=always {2}' \
    --preview-window='right:60%:rounded'
}

# ─────────────────────────────────────────────────────────────────────────
# 🎨 Aliases Convenientes
# ─────────────────────────────────────────────────────────────────────────

# Editar archivo con fzf
alias fzfe='fzf-find | xargs -r $EDITOR'

# Ver contenido de archivo rápidamente
alias fzfv='fzf-find | xargs -r bat --theme=Catppuccin\ Mocha'

# Navegar y entrar a carpeta
alias fzfd='cd "$(fzf-folder)"'

# Buscar en historial y ejecutar
alias fzfh='history | fzf | sed "s/^[[:space:]]*[0-9]*[[:space:]]*//g" | sh'

# ─────────────────────────────────────────────────────────────────────────
# 🚀 Optimizaciones de Rendimiento
# ─────────────────────────────────────────────────────────────────────────

# Usar fd en lugar de find para mejor rendimiento
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden --exclude .git --exclude node_modules --exclude .cache'

# Configuración específica para Zoxide + fzf
export _ZO_FZF_OPTS="--preview 'eza --tree --color=always --group-directories-first --level=2 {}'"

# ╚═══════════════════════════════════════════════════════════════════════╝
# 🎉 FZF Ready! Your shell just got more awesome
# ╚═══════════════════════════════════════════════════════════════════════╝
