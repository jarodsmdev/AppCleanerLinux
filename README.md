<div align="center">

# 🧹 AppCleanerLinux

**Menú interactivo en Bash para liberar espacio en disco en Fedora Linux.**

[![Shell](https://img.shields.io/badge/Shell-Bash%204.1%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![OS](https://img.shields.io/badge/OS-Fedora%2044-3C6EB4?style=for-the-badge&logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-00ADD8?style=for-the-badge&logo=opensourceinitiative&logoColor=white)](https://opensource.org/license/mit)
[![Plataforma](https://img.shields.io/badge/Plataforma-Linux%20%7C%20Fedora-3C6EB4?style=for-the-badge&logo=linux&logoColor=white)](https://kernel.org/)
[![Uso](https://img.shields.io/badge/Uso-Interfaz%20CLI-555555?style=for-the-badge)](#)
[![Permisos](https://img.shields.io/badge/Permisos-Requiere%20sudo-CC5500?style=for-the-badge&logo=gnulinux&logoColor=white)](#requisitos)
[![Sin dependencias](https://img.shields.io/badge/Dependencias-0%20externas-2ECC71?style=for-the-badge&logo=standard&logoColor=white)](#requisitos)

[⬇️ Descargar](https://github.com/jarodsmdev/AppCleanerLinux/archive/refs/heads/main.zip) · [🐛 Reportar bug](https://github.com/jarodsmdev/AppCleanerLinux/issues) · [💡 Sugerir](https://github.com/jarodsmdev/AppCleanerLinux/issues/new) · [⭐ Star](https://github.com/jarodsmdev/AppCleanerLinux)

</div>

---

## 📋 Descripción

AppCleanerLinux es un script de Bash que centraliza las tareas de mantenimiento más tediosas de tu máquina Fedora en un menú interactivo. Sin dependencias externas ni instalación: lo descargas, le das permisos de ejecución y a limpiar.

Diseñado y probado específicamente sobre **Fedora**, usando su gestor de paquetes `dnf`, sus rutas de caché (`~/.cache`, `/var/tmp`, `~/.local/share/Trash`) y sus herramientas de registro (`journalctl`).

> ⚠️ **Esto no es un reemplazo de tu sistema.** Ejecuta siempre con criterio: la opción 2 es **destructiva** por diseño.

---

## ✨ Características

| | Función | Detalle |
|:-:|:--|:--|
| 🧹 | **Limpieza básica** | Cachés y logs seguros de regenerar |
| 💣 | **Limpieza completa** | Modo agresivo, sin tocar Docker volúmenes ni lockfiles |
| 📱 | **Limpieza Android Studio** | Caché de Gradle, logs, `build/` reales y snapshots de AVD |
| 📊 | **Analizador de disco** | Interfaz visual con `ncdu` |
| 🗑️ | **Limpieza de node_modules** | Borrado interactivo con `npkill` |
| 🛠️ | **Cachés de desarrollo** | npm, pnpm, yarn, bun, pip, uv, Go, Rust y Maven |
| 📦 | **Contenedores y paquetes** | Docker, Podman, Flatpak y Snap |
| 💻 | **Cachés de IDEs** | Solo cachés/logs regenerables de VS Code y JetBrains |

---

## 🚀 Instalación

```bash
git clone https://github.com/jarodsmdev/AppCleanerLinux.git
cd AppCleanerLinux
chmod +x appCleaner.sh
./appCleaner.sh
```

O directo, sin clonar:

```bash
curl -LO https://raw.githubusercontent.com/jarodsmdev/AppCleanerLinux/main/appCleaner.sh
chmod +x appCleaner.sh && ./appCleaner.sh
```

---

## 📖 Uso

Al ejecutarlo verás el menú principal:

```
==============================
   LIMPIADOR - FEDORA - JAROD
==============================

1) Limpieza básica (segura)
2) Limpieza completa (AGRESIVA)
3) Limpieza Android Studio / Gradle
4) Analizar disco con ncdu
5) Limpiar node_modules (npkill)
6) Cachés de desarrollo (npm, pip, uv, Go, Rust...)
7) Contenedores y paquetes (Docker, Podman, Flatpak, Snap)
8) Cachés de IDEs (VS Code, JetBrains)
9) Salir
```

### 1 · Limpieza básica (segura)

Libera espacio sin tocar nada que no se regenere solo:

- Elimina paquetes huérfanos (`dnf autoremove`) y limpia la caché de `dnf`
- Limpia cachés de PackageKit, dnf5 daemon y catálogo de software
- Reduce el journal a los últimos **7 días** y borra logs rotados de +14 días
- Borra coredumps del sistema
- Limpia cachés seguras (`thumbnails`, `mesa_shader_cache`, `gnome-software`, `fontconfig`, `tracker3`)
- Borra el resto de cachés de usuario con más de **14 días**
- Limpia cachés de `npm`, `pip`, `uv`, `pre-commit` y `poetry`

### 2 · Limpieza completa (agresiva)

Todo lo anterior, y además:

- Vacía la **papelera** del usuario
- Reduce los logs a **3 días**
- Borra de `/tmp` y `/var/tmp` solo lo que tenga **más de 3 días**, excluyendo sockets y directorios privados del sistema
- Purga Docker y Podman: contenedores, imágenes y build cache, **sin volúmenes**
- Elimina Flatpaks sin uso y revisiones antiguas/deshabilitadas de Snap
- Borra carpetas `.terraform`, pero **conserva `.terraform.lock.hcl`**
- Borra cachés de Python (`__pycache__`, `*.pyc`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`)
- Borra `node_modules`, excluyendo `~/.config`, `~/.local`, `~/.npm`, `~/.bun`, `~/.vscode*` y `~/snap`

> ⚠️ **Riesgos:** los `node_modules` desaparecerán de tus proyectos (habrá que reinstalar dependencias). Los volúmenes de Docker/Podman **no se tocan** en esta opción. Siempre se pide confirmación explícita (`y`) antes de ejecutar.

### 3 · Limpieza Android Studio / Gradle

- Caché de Gradle (`~/.gradle/caches`, `daemon`, `native`)
- Logs y caché de Android Studio
- Carpetas `build/` que contengan artefactos reales (`intermediates`, `outputs`, `generated` o `kotlin`), evitando directorios de código llamados `build`
- Caché de `~/.android` y snapshots de emuladores AVD (se pierde el arranque rápido)

### 4 · Analizar disco con `ncdu`

Abre un explorador visual del uso del disco en tu home. Si `ncdu` no está instalado, el script lo instala automáticamente con `dnf`.

```bash
sudo dnf install ncdu
```

### 5 · Limpiar `node_modules` con `npkill`

Ejecuta [npkill](https://github.com/rtfeldman/node-process-list) de forma interactiva: navegas con `space` para marcar y `e` para borrar. Requiere Node.js y `npx`; no los instala por ti.

```bash
sudo dnf install nodejs
```

### 6 · Cachés de desarrollo

Limpia solo cachés regenerables de las herramientas que tengas instaladas:

- `npm`, `pnpm`, `yarn` y `bun`
- `pip`, `uv`, `pre-commit` y `poetry`
- `go clean -cache` (y opcionalmente `go clean -modcache`)
- Caché de Cargo (`~/.cargo/registry/cache`, `src` y `git/checkouts`)
- Opcionalmente `~/.m2/repository` (Maven) y `~/.gradle/caches`

Las opciones caras de re-descargar se preguntan por separado.

### 7 · Contenedores y paquetes

- Docker: `system prune -a` y `builder prune -a`, sin volúmenes
- Podman: `system prune -a`, sin volúmenes
- Flatpak: runtimes y apps sin uso
- Snap: reduce las revisiones retenidas y elimina las deshabilitadas

Los volúmenes de Docker/Podman se preguntan aparte y **por defecto no se borran**, porque pueden contener bases de datos o datos persistentes.

### 8 · Cachés de IDEs

Limpia únicamente archivos que el IDE regenera solo:

- VS Code: `Cache`, `Code Cache`, `GPUCache`, `CachedData`, `CachedExtensionVSIXs`, `Dawn*Cache`, `Crashpad` y `logs`
- VS Code: `Service Worker` y `workspaceStorage` con más de 30 días
- JetBrains: cachés de `~/.cache/JetBrains` y logs de Toolbox/IDEs

No borra settings, extensiones instaladas, backups de archivos sin guardar ni datos de plugins. Si detecta un IDE abierto, avisa y pide confirmación antes de continuar.

---

## 🧰 Requisitos

| Requisito | Detalle |
|:--|:--|
| Sistema | **Fedora Linux** (usa `dnf`, `journalctl` y rutas propias de Fedora) |
| Shell | Bash 4.1 o superior |
| Privilegios | `sudo` (paquetes, journal, `/var/tmp`, coredumps y Snap) |
| Herramientas opcionales | `npm` / `npx`, `pnpm`, `yarn`, `bun`, `pip`, `uv`, `go`, `cargo`, `docker`, `podman`, `flatpak`, `snap`, `ncdu` |

**Dependencias externas del script: ninguna.** Las herramientas opcionales se detectan con `command -v` y se omiten si no están disponibles.

---

## ⚡ Ejemplos de uso

```bash
# Limpieza rápida de la caché del sistema
./appCleaner.sh   # → opción 1 → y

# Liberar espacio tras un build de Android
./appCleaner.sh   # → opción 3 → y

# Limpiar cachés de npm, pip, uv, Go o Rust
./appCleaner.sh   # → opción 6 → y

# Limpiar Docker/Podman/Flatpak/Snap
./appCleaner.sh   # → opción 7 → y

# Limpiar solo cachés y logs de VS Code/JetBrains
./appCleaner.sh   # → opción 8 → y

# Encontrar qué se está comiendo el disco
./appCleaner.sh   # → opción 4
```

Para consultar qué se va a borrar **antes** de ejecutar:

```bash
du -sh ~/.cache ~/.m2/repository ~/.gradle/caches /var/tmp 2>/dev/null
docker system df
podman system df
journalctl --disk-usage
```

---

## 🛡️ Seguridad y buenas prácticas

- El script **solo borra datos regenerables**: cachés, logs, artefactos de build y paquetes huérfanos.
- Usa `-y` en `dnf autoremove`, lo que elimina dependencias huérfanas de forma **no interactiva**: revisa la lista antes de confirmar.
- Las opciones destructivas requieren confirmación manual (`y`) — no hay ejecución automática.
- `/tmp` y `/var/tmp` no se vacían completos: solo se borra lo que tenga más de 3 días, excluyendo sockets y directorios privados del sistema.
- Docker/Podman **no borran volúmenes por defecto**. La opción 7 pregunta aparte antes de tocarlos.
- `.terraform.lock.hcl` **no se elimina**; solo se borra la carpeta regenerable `.terraform`.
- Las carpetas `build/` solo se eliminan si contienen artefactos de Gradle, para no borrar código fuente que casualmente se llame `build`.
- La limpieza de IDEs solo toca cachés, logs y `workspaceStorage` viejo; conserva settings, extensiones y backups.
- Haz una copia de seguridad o una instantánea del sistema antes de la opción 2.

---

## 🐛 Reportar problemas

¿Encontraste un bug o te falta una opción?

1. Abre un issue en [GitHub Issues](https://github.com/jarodsmdev/AppCleanerLinux/issues)
2. Incluye tu versión de Fedora (`cat /etc/fedora-release`) y qué opción falló
3. Pega la salida de error relevante

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas!

1. Haz un **fork** del repositorio
2. Crea una rama: `git checkout -b mi-mejora`
3. Prueba los cambios en tu Fedora
4. Abre un **Pull Request** describiendo qué cambiaste

Ideas fáciles para empezar: añadir soporte para `-h`/`--help`, un modo `--dry-run`, o incorporar herramientas de otros gestores de paquetes.

---

## 📄 Licencia

Distribuido bajo la licencia **MIT**. Para distribuirlo formalmente, añade un archivo `LICENSE` en la raíz del repositorio con el texto de la licencia.

---

<div align="center">

Hecho con ☕ por [Jarod Smith](https://github.com/jarodsmdev) · Fedora Linux

[![Fedora](https://img.shields.io/badge/Powered%20by-Fedora-3C6EB4?style=flat-square&logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)

</div>
