# Fresh Install

[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](README.md)

## Pacman Tweaks

```zsh
sudo vim /etc/pacman.conf
```

- Descomentar:
  - #`Color`
  - #`VerbosePkgLists`

- Modificar:
  - Agregar `ILoveCandy` debajo de `Color`
  - Cambiar `#ParallelDownloads = 5` por `ParallelDownloads = 10`

- Guardar y salir:
  - `Shift + wq`

## Instalar Yay (Bin)

```zsh
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si
```

## Instalar Paquetes

```zsh
sudo pacman -S --needed gnome-keyring gnome-shell-extension-appindicator noto-fonts-emoji firefox kitty zsh nodejs gufw ttf-jetbrains-mono-nerd ttf-ubuntu-font-family yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick libayatana-appindicator keepassxc signal-desktop proton-vpn-gtk-app neovim lazygit less reflector pacman-contrib starship && yay -S cryptomator windsurf phoenix-arch
```

- Elimina `gnome-keyring` si ya tienes un agente de autenticación
- Elimina `gnome-shell-extension-appindicator` si no usas GNOME
