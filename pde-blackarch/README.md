# Contenedor Personal para Hacking Ético (BlackArch)

## Stack

- Herramientas modernas: eza, bat, fd, ripgrep, fzf, zoxide, starship, yazi, helix, fastfetch & zsh
- Hacking OOTB: rustscan, nmap, feroxbuster, iputils

## Uso

> Asegúrate de estar en el mismo directorio que el `Containerfile`

### Build

```bash
podman build -t pde-blackarch .
```

### Primer Uso (Persistente)

```bash
podman run -it --cap-add=NET_RAW --name hacking-lab pde-blackarch
```

### Uso Posterior

```bash
podman start -ai hacking-lab
```

### Uso atómico y temporal

```bash
podman run -it -rm --cap-add=NET_RAW --name hacking-lab pde-blackarch
```
