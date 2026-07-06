# Contenedor Personal para Hacking Ético (BlackArch)

## Stack

- Herramientas modernas: eza, bat, fd, ripgrep, fzf, zoxide, starship, yazi, helix, fastfetch & zsh
- Hacking OOTB: rustscan, nmap, feroxbuster, iputils

## Requisitos

- **Podman ≥ 6.0** (probado en **6.0.0**)
- Ecosistema v6 obligatorio:
  - `buildah ≥ 1.44.0`
  - `netavark ≥ 2.0.0`
  - `aardvark-dns ≥ 2.0.0`
  - `pasta`

Verifica tu entorno con:

```bash
podman info | grep -E "(version|Backend|rootlessNetworkCmd)"
```

Debe mostrar algo como:

```
  version: 6.0.0
  networkBackend: netavark
  rootlessNetworkCmd: pasta
```

> ⚠️ **¿Usas Podman 5.x?** Este README está optimizado para **6.x**. Si estás en 5.x,
> revisa esta tabla antes de continuar:
>
> | Aspecto                         | v5.x             | v6.x                           |
> | ------------------------------- | ---------------- | ------------------------------ |
> | `--network=host` en build       | **No necesario** | Recomendado                    |
> | `network_isolation` por defecto | `false`          | `true`                         |
> | `slirp4netns`                   | Soportado        | **Eliminado**                  |
> | Backend `iptables`              | Soportado        | **Eliminado** (usa `nftables`) |
> | `containers.conf` parsing       | Estable          | Reescrito                      |
> | `BoltDB`                        | Soportado        | **Eliminado** (solo `SQLite`)  |
> | `CNI`                           | Soportado        | **Eliminado** (usa `netavark`) |
>
> **Recomendación**: actualiza a Podman 6.0+. Si no puedes, los comandos de este
> README funcionan tal cual; simplemente omite `--network=host` en el build.

## Uso

> Asegúrate de estar en el mismo directorio que el `Containerfile`.

### Build

```bash
podman build --network=host -t pde-blackarch .
```

`--network=host` compensa el `network_isolation=enabled` por defecto en Podman 6.0+.
El `Containerfile` además configura DNS interno resiliente como defensa adicional.

**Alternativa sin `--network=host`**:

```bash
podman build --dns=1.1.1.1 --dns=9.9.9.9 -t pde-blackarch .
```

### Primer Uso (Persistente)

```bash
podman run -it --cap-add=NET_RAW --cap-add=NET_ADMIN --name hacking-lab pde-blackarch
```

| Capacidad   | Habilita                                  |
| ----------- | ----------------------------------------- |
| `NET_RAW`   | `nmap -sS`, `ping`, `tcpdump`, `rustscan` |
| `NET_ADMIN` | `iptables`, `arpspoof`, `ifconfig`        |

### Re-crear el contenedor persistente

Si ya existe `hacking-lab` de un uso anterior:

```bash
podman rm -f hacking-lab
podman run -it --cap-add=NET_RAW --cap-add=NET_ADMIN --name hacking-lab pde-blackarch
```

### Uso Posterior

```bash
podman start -ai hacking-lab
```

### Uso atómico y temporal

```bash
podman run -it --rm --cap-add=NET_RAW --cap-add=NET_ADMIN pde-blackarch
```

> Sin `--name`: `--rm` borra el contenedor al salir.

### Limpieza

```bash
podman rm -f hacking-lab         # borrar el contenedor persistente
podman rmi pde-blackarch         # borrar la imagen
podman system prune              # liberar espacio general
```

## Notas sobre Podman 6.0.0

Cambios relevantes que afectan a este contenedor:

- **`slirp4netns` eliminado** → usa `pasta`
- **`CNI` eliminado** → usa `netavark`
- **Backend `iptables` reemplazado por `nftables`**
- **`network_isolation` ahora habilitado por defecto** (rompe DNS en builds sin workaround)
- **`BoltDB` eliminado** → solo `SQLite`
- **Matriz de compatibilidad estricta**: `buildah 1.44.0+`, `skopeo 1.23+`, `netavark/aardvark 2.0.0+`
