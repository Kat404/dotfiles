# 🐚 T-UI Launcher Config (Nushell-Style & Catppuccin Mocha)

Configuración moderna y estructurada para [T-UI Launcher v7 (cycloarcane fork)](https://github.com/cycloarcane/TUI-ConsoleLauncher) inspirada en la sintaxis tabular de **Nushell** y estilizada con la paleta **Catppuccin Mocha**.

---

## 📸 Vista Previa de la Tabla Nushell

```
╭───┬───────────────┬──────────────────────────────╮
│ # │ component     │ value                        │
├───┼───────────────┼──────────────────────────────┤
│ 0 │  host        │ josel@reno5                  │
│ 1 │ 󰍛 memory      │ 2.61 GB / 5.48 GB (47.6%)    │
│ 2 │ 󰁹 battery     │ 83% 󱐋 (Charging)             │
│ 3 │ 󱑎 datetime    │ 22 de agosto 2026, 09:52p. m.│
│ 4 │ 󰋊 storage     │ 59.87 GB / 105.59 GB (56.7%) │
│ 5 │ 󰖩 network     │ WiFi: JHC_AP01               │
╰───┴───────────────┴──────────────────────────────╯
```

---

## 📂 Archivos del Setup

| Archivo                                  | Función Principal                                                                               |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`behavior.xml`](behavior.xml)           | Ensamblado de filas de la tabla Nushell, variables de hardware, prefijos y thresholds.          |
| [`theme.xml`](theme.xml)                 | Paleta Catppuccin Mocha completa (cada fila de la tabla tiene un color acentuado).              |
| [`ui.xml`](ui.xml)                       | Modo pantalla completa, monospace, soporte para fuente externa, tamaños de letra y visibilidad. |
| [`suggestions.xml`](suggestions.xml)     | Estilizado Catppuccin para la barra de autocompletado emergente (apps, cmd, alias).             |
| [`toolbar.xml`](toolbar.xml)             | Accesos directos inferiores táctiles con WhatsApp (#1) y YouTube (#2) prioritarios.             |
| [`alias.txt`](alias.txt)                 | Atajos rápidos para lanzar apps (`wa`, `yt`, `termux`, `ob`, `gh`, `gemini`, etc.).             |
| [`cmd.xml`](cmd.xml)                     | Comportamiento del motor de búsqueda web y navegador de archivos.                               |
| [`notifications.xml`](notifications.xml) | Formateo estético del listener de notificaciones de Android.                                    |
| [`deploy.nu`](deploy.nu)                 | Script en Nushell para sincronización automática mediante ADB (opcional).                       |

---

## 🔤 Uso de Fuentes Externas (Nerd Fonts .ttf / .otf)

T-UI permite cargar fuentes personalizadas de manera nativa sin necesidad de root:

1. **Descarga tu fuente favorita** (por ejemplo `JetBrainsMonoNerdFont-Regular.ttf` o `FiraCodeNerdFont-Regular.ttf`).
2. **Copia el archivo `.ttf` o `.otf`** dentro de la carpeta `t-ui/` de tu almacenamiento interno (`/storage/emulated/0/t-ui/font.ttf`).
3. **Aplica la fuente** desde la consola de T-UI ejecutando:

   ```bash
   config -apply font.ttf
   ```

4. **Reinicia el launcher**:

   ```bash
   restart
   ```

---

## 📲 Métodos Nativos de Instalación / Sincronización (Sin ADB)

La carpeta de configuración de T-UI en Android se ubica en la raíz del almacenamiento interno:  
📍 `/storage/emulated/0/t-ui/` (o simplemente `Almacenamiento interno > t-ui`).

Puedes transferir los archivos usando cualquiera de estas alternativas nativas:

### Método 1: Gestor de Archivos de Android (Directo en el móvil)

1. Descarga o transfiere los archivos a tu carpeta `Downloads/` en el teléfono.
2. Abre tu gestor de archivos favorito (ZArchiver, Material Files, MiXplorer, Solid Explorer o Files by Google).
3. Selecciona los archivos `.xml` y `alias.txt` y pégalos en la carpeta `t-ui/` de la memoria interna, sobrescribiendo los anteriores.
4. Abre T-UI y escribe `restart`.

### Método 2: Termux (CLI en el teléfono)

Si gestionas tus dotfiles con Git dentro de Termux:

```bash
cp -r ~/.dotfiles/t-ui/* /sdcard/t-ui/
```

Luego escribe `restart` en T-UI.

### Método 3: Conexión USB MTP (Desde Arch Linux)

1. Conecta tu Oppo Reno 5 Lite por USB a tu PC y selecciona **Transferencia de archivos (MTP)** en el teléfono.
2. En tu explorador de archivos de Linux (Thunar, Dolphin, etc.) o montado con `gvfs` / `simple-mtpfs`, abre la carpeta `t-ui` de tu dispositivo.
3. Copia y pega todos los archivos desde `~/.dotfiles/t-ui/` dentro de esa carpeta.
4. Ejecuta `restart` en T-UI.

### Método 4: LocalSend / KDE Connect

1. Envía los archivos desde tu computadora hacia el teléfono usando LocalSend o KDE Connect.
2. Muévelos desde la carpeta de recepción a `/sdcard/t-ui/`.
3. Ejecuta `restart` en T-UI.
