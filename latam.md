[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](README.md)

# Paso esencial (con o sin GNOME)

### Ver todos los layouts disponibles

```zsh
localectl list-x11-keymap-layouts
```

### Cambiar al layout 'latam'

```zsh
sudo localectl set-x11-keymap latam
```

## Cambio de teclado 'es' --> 'latam' (GNOME)

### Comando

```zsh
gsettings get org.gnome.desktop.input-sources sources
```

### Salida esperada

```zsh
[('xkb', 'es')]
```

## Solución

### Paso 1

```zsh
gsettings set org.gnome.desktop.input-sources show-all-sources true
```

### Paso 2

```zsh
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'latam')]"
```
