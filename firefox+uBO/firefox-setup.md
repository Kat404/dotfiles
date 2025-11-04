# Firefox Setup

[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](../README.md)

## Betterfox

- Copiar y pegar el archivo [`user.js`](user.js) en la carpeta `~/.mozilla/firefox/*.default-release/`

```zsh
cp ~/.dotfiles/firefox+uBO/user.js ~/.mozilla/firefox/*.default-release/user.js
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

### Extras (Renewed Tab)

- Instalar Renewed Tab en la [Tienda de Extensiones de Firefox](https://addons.mozilla.org/es-MX/firefox/addon/renewed-tab/)
- Permitir que la extensión se ejecute por encima de Firefox (New Tab nativa)
- Lápiz --> Ajustes --> Importar/Exportar --> *Importar* (usar el archivo [.json](renewedtab.json))
