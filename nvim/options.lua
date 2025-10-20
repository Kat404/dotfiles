-- ~/.config/nvim/lua/config/options.lua
local opt = vim.opt

-- 1. Activa el ajuste de línea (wrap)
opt.wrap = true

-- 2. Evita que se corten las palabras
opt.linebreak = true

-- 3. Mantiene la indentación de la línea original
opt.breakindent = true

-- 4. Flecha separadora
opt.showbreak = "↪ "
