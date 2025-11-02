# Configuración Personal de fish

[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](../README.md)

## Instalación

```zsh
cp -r ~/.dotfiles/fish ~/.config/fish
```

## Requisitos

- Tener ``fish`` instalado (v >= 4.0.0)
- Tener ``fisher`` instalado

## Instalar Fisher & Plugins

### Fisher

```zsh
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

### Plugins

```zsh
fisher install ilancosman/tide@v6 &&
fisher install patrickf1/fzf.fish &&
fisher install franciscolourenco/done
```
