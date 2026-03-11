# Configuración para Git

[![Volver al Inicio](https://img.shields.io/badge/-Volver_al_Inicio-6e5494?style=for-the-badge&logo=home-assistant&logoColor=white&labelColor=1a1a1a)](README.md)

## Usuario y Correo

### Usuario

```zsh
git config --global user.name "Tu Nombre"
```

### Correo

```zsh
git config --global user.email "tu.correo@example.com"
```

## Clave GPG

### Ver tus claves

```zsh
gpg --list-secret-keys --keyid-format LONG
```

Salida

```zsh
sec   rsa4096/ABCDEF1234567890 2025-01-01 [SC]
      XXXXXXXXXXXXXXXXXXXXXXXX
uid                 [ultimate] Tu Nombre <tu.correo@example.com>
ssb   rsa4096/YYYYYYYYYYYYYYYY 2025-01-01 [E]
```

### Configurar tu clave GPG a git

```zsh
git config --global user.signingkey ABCDEF1234567890
```

### Configurar git para firmar por defecto

```zsh
git config --global commit.gpgsign true
```

## Autenticación y Protocolos

### Forzar SSH globalmente (GitHub y Codeberg)
Para evitar el uso de HTTPS y tokens, redirigimos todas las peticiones al túnel SSH.

```zsh
# Para GitHub
git config --global url."git@github.com:".insteadOf "[https://github.com/](https://github.com/)"

# Para Codeberg
git config --global url."git@codeberg.org:".insteadOf "[https://codeberg.org/](https://codeberg.org/)"
```

## Configuración de Mirrors (Dual Push)

### 1. Asegurar el remoto de GitHub

```zsh
git remote set-url origin git@github.com:Kat404/repositorio-de-destino.git
```

### 2. Añadir Codeberg al flujo de push de origin

```zsh
git remote set-url --add --push origin git@codeberg.org:Kat404/repositorio-de-destino.git
```

## Editor & Sistema

### Definir Helix como editor

```zsh
git config --global core.editor "helix"
```

### Configuración de finales de línea (estándar Unix)

```zsh
git config --global core.autocrlf input
```

### Nombre de rama inicial por defecto

```zsh
git config --global init.defaultBranch main
```
