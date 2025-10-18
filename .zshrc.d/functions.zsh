# Funciones personalizadas para Zsh.
# ~/.zshrc.d/functions.zsh
# El propósito de estas funciones es dar una experiencia similar a algo más 'fish-like', simulando el 'prevd' y el 'nextd' de fish.

# Navega al directorio anterior en el historial (dirstack) de forma silenciosa.
function irq {
  cd -1 > /dev/null
}

# Navega al directorio siguiente en el historial (dirstack) de forma silenciosa.
function ira {
  cd +1 > /dev/null
}
