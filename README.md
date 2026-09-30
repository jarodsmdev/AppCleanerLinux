<div align="center">

# 🧹 AppCleanerLinux

**Menú interactivo en Bash para liberar espacio en disco en Fedora Linux.**

[![Shell](https://img.shields.io/badge/Shell-Bash-4.1%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![OS](https://img.shields.io/badge/OS-Fedora-51-3C6EB4?style=for-the-badge&logo=fedora&logoColor=white)](https://fedoraproject.org/)
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
| 🧹 | **Limpieza básica** | Segura y reversible en su mayoría |
| 💣 | **Limpieza completa** | Modo agresivo, borra todo lo regenerable |
| 📱 | **Limpieza Android Studio** | Caché de Gradle, logs y carpetas `build/` |
| 📊 | **Analizador de disco** | Interfaz visual con `ncdu` |
| 🗑️ | **Limpieza de node_modules** | Borrado interactivo con `npkill` |

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
3) Limpieza Android Studio
4) Analizar disco con ncdu
5) Limpiar node_modules (npkill)
6) Salir
```

### 1 · Limpieza básica (segura)

Libera espacio sin tocar nada que no se regenere solo:

- Elimina paquetes huérfanos (`dnf autoremove`)
- Vacía la caché de `dnf` (`dnf clean all`)
- Limpia `~/.cache` y las miniaturas del sistema
- Reduce los logs del journal a los últimos **7 días**
- Limpia la caché de `npm`

### 2 · Limpieza completa (agresiva)

Todo lo anterior, y además:

- Vacía la **papelera** del usuario
- Reduce los logs a **3 días**
- Borra `/tmp` y `/var/tmp`
- Purga Docker: imágenes, contenedores y **volúmenes** no usados
- Elimina Flatpaks sin uso (`flatpak uninstall --unused`)
- Borra todas las carpetas `.terraform` y `.terraform.lock.hcl`
- Borra todas las carpetas `node_modules` del home
- Borra cachés de Python (`__pycache__`, `*.pyc`)

> ⚠️ **Riesgos:** los `node_modules` y carpetas `build/` desaparecerán de todos tus proyectos (habrá que reinstalar dependencias) y se eliminarán los volúmenes de Docker no usados. Siempre se pide confirmación explícita (`y`) antes de ejecutar.

### 3 · Limpieza Android Studio

- Caché de Gradle (`~/.gradle/caches`, `daemon`, `native`)
- Logs y caché de Android Studio
- Carpetas `build/` de todos tus proyectos

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

---

## 🧰 Requisitos

| Requisito | Detalle |
|:--|:--|
| Sistema | **Fedora Linux** (usa `dnf`, `journalctl` y rutas propias de Fedora) |
| Shell | Bash 4.1 o superior |
| Privilegios | `sudo` (se solicitará al borrar paquetes, logs y `/tmp`) |
| Herramientas opcionales | `npm` / `npx`, `docker`, `flatpak`, `ncdu` |

**Dependencias externas del script: ninguna.** Las herramientas opcionales se detectan con `command -v` y se omiten si no están disponibles.

---

## ⚡ Ejemplos de uso

```bash
# Limpieza rápida de la caché del sistema
./appCleaner.sh   # → opción 1 → y

# Liberar espacio tras un build de Android
./appCleaner.sh   # → opción 3 → y

# Encontrar qué se está comiendo el disco
./appCleaner.sh   # → opción 4
```

Para consultar qué se va a borrar **antes** de ejecutar:

```bash
du -sh ~/.cache /var/tmp 2>/dev/null
docker system df
journalctl --disk-usage
```

---

## 🛡️ Seguridad y buenas prácticas

- El script **solo borra datos regenerables**: cachés, logs, artefactos de build y paquetes huérfanos.
- Usa `-y` en `dnf autoremove`, lo que elimina dependencias huérfanas de forma **no interactiva**: revisa la lista antes de confirmar.
- Las opciones destructivas requieren confirmación manual (`y`) — no hay ejecución automática.
- Docker se purga con `-a`, que elimina imágenes no usadas por contenedores activos, y `docker volume prune` **borra volúmenes sin usar**. Si usas volúmenes para datos persistentes, considera la opción 1.
- Haz una copia de seguridad o una instantánea del sistema antes de la opción 2.
- Algunas rutas (`~/.local/share/Trash`, `~/.cache/Google`) son específicas de GNOME y del tema de escritorio.

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
