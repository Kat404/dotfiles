-- ~/.config/nvim/lua/config/autocmds.lua
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Este archivo es para añadir o eliminar autocommands

-- Eliminamos el grupo de autocomandos "lazyvim_wrap_spell"
-- Este es el grupo que activa el corrector ortográfico (spell)
-- y el ajuste de línea (wrap) para archivos .txt, .md, etc.
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- OPCIONAL: Si quieres mantener el ajuste de línea (wrap) pero NO el corrector (spell)
-- entonces comenta la línea de arriba (pon -- al inicio) y
-- descomenta el siguiente bloque de código:

--[[
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "markdown", "md", "txt" },
  callback = function(ev)
    vim.opt_local.wrap = true -- Mantenemos el ajuste de línea
    vim.opt_local.spell = false -- PERO desactivamos el corrector
  end,
})
--]]
