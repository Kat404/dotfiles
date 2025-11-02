# -----------------------------------------------------------------------------
#                ---> ATAJOS DE TECLADO (KEY BINDINGS) <---
#
# Asigna funciones a combinaciones de teclas.
# -----------------------------------------------------------------------------

# Asigna las funciones de 'bang-bang' a las teclas '!' y '$'
# Se ajusta automáticamente si usas el modo Vi o Emacs.
if [ "$fish_key_bindings" = fish_vi_key_bindings ]
    bind -Minsert ! __history_previous_command
    bind -Minsert '$' __history_previous_command_arguments
else
    bind ! __history_previous_command
    bind '$' __history_previous_command_arguments
end
