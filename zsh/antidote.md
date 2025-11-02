# Configuración Personal para Zsh

[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](../README.md)

## Instalación de Antidote (Plugin Manager)

```zsh
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
```

## Aplicación de la configuración

```zsh
cp -r ~/.dotfiles/zsh/.zshrc.d/ ~/.zshrc.d/
```

```zsh
cp ~/.dotfiles/zsh/.zsh_plugins.txt ~/.zsh_plugins.txt
```

```zsh
cp ~/.dotfiles/zsh/.zshrc ~/.zshrc
```
