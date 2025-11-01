# Firefox Setup

## Betterfox

- Copiar y pegar el archivo [`user.js`](user.js) en la carpeta `~/.mozilla/firefox/*.default-release/`

```zsh
cp ~/.dotfiles/firefox+uBO/user.js ~/.mozilla/firefox/*.default-release/
```

## uBlockOrigin

### Instalación

- Instalar uBlockOrigin (en caso de que no esté instalado) en la [Tienda de Extensiones de Firefox](https://addons.mozilla.org/es-ES/firefox/addon/ublock-origin/)

### Parcial (Filtros & Reglas)

- Ir a Configuración de _uBlockOrigin_
- Ir a la Sección de `Mis filtros` --> `Importar y anexar` --> Seleccionar el archivo de [`Mis filtros`](MisFiltros.txt)
- Ir a la Sección de `Mis reglas` --> `Reglas temporales: Importar desde archivo` --> Seleccionar el archivo de [`Mis reglas`](MisReglas.txt)

### Completo

- Ir a Configuración de _uBlockOrigin_
- Sección `Configuración` --> `Restaurar desde archivo` --> Seleccionar el archivo de [`Mi respaldo`](MiRespaldo.txt)