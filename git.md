# Configuración para git

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
