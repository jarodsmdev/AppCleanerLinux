#!/usr/bin/env bash

set -uo pipefail

START_KB=0

have() { command -v "$1" >/dev/null 2>&1; }

ask() {
    local answer
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

pause() { read -r -p "Presiona Enter para volver al menú..." _; }

show_space() { df -hP / | awk 'NR==1 || NR==2'; }

free_kb() { df -kP / | awk 'NR==2 {print $4}'; }

begin() {
    START_KB=$(free_kb)
    echo ""
    show_space
}

finish() {
    local end_kb freed_mb
    end_kb=$(free_kb)
    freed_mb=$(( (end_kb - START_KB) / 1024 ))
    echo ""
    show_space
    if (( freed_mb > 0 )); then
        echo "Espacio liberado: ~${freed_mb} MB"
    else
        echo "No se liberó espacio medible."
    fi
    pause
}

clear_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    find "$dir" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null
}

require_sudo() {
    if ! have sudo; then
        echo "sudo no está disponible."
        return 1
    fi
    sudo -v || {
        echo "No se pudo obtener sudo."
        return 1
    }
}

system_cleanup() {
    local days="$1"

    require_sudo || return 1

    if have dnf; then
        echo ">>> Paquetes huérfanos (dnf autoremove)"
        sudo dnf autoremove -y
        echo ">>> Caché de dnf"
        sudo dnf clean all
    fi

    echo ">>> Cachés de PackageKit, dnf5daemon y catálogo"
    sudo find /var/cache/PackageKit /var/cache/swcatalog /var/cache/dnf5daemon-server \
        -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null

    if have journalctl; then
        echo ">>> Journal reducido a ${days} días"
        sudo journalctl --vacuum-time="${days}d"
    fi

    echo ">>> Coredumps del sistema"
    sudo find /var/lib/systemd/coredump -type f -delete 2>/dev/null

    echo ">>> Logs comprimidos/rotados con más de 14 días"
    sudo find /var/log -xdev -type f \( -name '*.gz' -o -name '*.old' -o -name '*.1' -o -name '*.2' \) \
        -mtime +14 -delete 2>/dev/null
}

user_safe_cleanup() {
    local cache

    for cache in thumbnails mesa_shader_cache gnome-software fontconfig tracker3; do
        clear_dir "$HOME/.cache/$cache"
    done

    echo ">>> Cachés de usuario con más de 14 días"
    find "$HOME/.cache" -xdev -mindepth 1 -maxdepth 1 -mtime +14 \
        -exec rm -rf -- {} + 2>/dev/null
}

dev_cache_cleanup() {
    if have npm; then
        echo ">>> Caché de npm"
        npm cache clean --force >/dev/null 2>&1 || true
    fi

    if have pip; then
        echo ">>> Caché de pip"
        pip cache purge >/dev/null 2>&1 || true
    fi

    if have uv; then
        echo ">>> Caché de uv"
        uv cache clean >/dev/null 2>&1 || true
    fi

    clear_dir "$HOME/.cache/pre-commit"
    clear_dir "$HOME/.cache/pypoetry"
}

flatpak_snap_cleanup() {
    if have flatpak; then
        echo ">>> Flatpak sin uso"
        flatpak uninstall --unused -y >/dev/null 2>&1 || true
        flatpak uninstall --user --unused -y >/dev/null 2>&1 || true
    fi

    if have snap; then
        echo ">>> Revisiones antiguas de snap"
        require_sudo || return 1
        sudo snap set system refresh.retain=2
        snap list --all 2>/dev/null | awk '/disabled/ {print $1, $3}' |
            while read -r name rev; do
                [[ -n "${name:-}" && -n "${rev:-}" ]] || continue
                sudo snap remove "$name" --revision="$rev" || true
            done
    fi
}

container_cleanup() {
    local ask_volumes="${1:-no}"

    if have docker && docker info >/dev/null 2>&1; then
        echo ">>> Docker: contenedores, imágenes y build cache (sin volúmenes)"
        docker system prune -a -f || true
        docker builder prune -a -f || true

        if [[ "$ask_volumes" == "yes" ]] && ask "¿Borrar también volúmenes Docker NO usados? (pueden contener datos)"; then
            docker volume prune -f || true
        fi
    fi

    if have podman && podman info >/dev/null 2>&1; then
        echo ">>> Podman: contenedores, imágenes y build cache (sin volúmenes)"
        podman system prune -a -f || true

        if [[ "$ask_volumes" == "yes" ]] && ask "¿Borrar también volúmenes Podman NO usados?"; then
            podman volume prune -f || true
        fi
    fi
}

packages_cleanup() {
    flatpak_snap_cleanup
}

clean_gradle_builds() {
    echo ">>> Carpetas build de Gradle/Android (solo con artefactos)"
    find "$HOME" -xdev -type d -name build \
        -not -path "$HOME/.gradle/*" \
        -not -path "$HOME/.cache/*" \
        -not -path "$HOME/.m2/*" \
        -not -path "$HOME/.local/*" \
        -not -path "*/node_modules/*" \
        -exec sh -c 'for d in "$@"; do
            if [ -d "$d/intermediates" ] || [ -d "$d/outputs" ] || [ -d "$d/generated" ] || [ -d "$d/kotlin" ]; then
                rm -rf -- "$d"
            fi
        done' sh {} + 2>/dev/null
}

basic_cleanup() {
    echo ""
    echo ">>> LIMPIEZA BÁSICA"
    echo "Se realizará:"
    echo "- dnf autoremove + dnf clean all"
    echo "- Cachés de PackageKit/dnf5daemon/swcatalog"
    echo "- Journal reducido a 7 días y logs rotados de +14 días"
    echo "- Coredumps"
    echo "- Cachés seguras de usuario y cachés de +14 días"
    echo "- Cachés de npm, pip, uv, pre-commit y poetry"
    echo ""

    ask "¿Continuar?" || return

    begin
    system_cleanup 7
    user_safe_cleanup
    dev_cache_cleanup
    finish
}

aggressive_cleanup() {
    echo ""
    echo ">>> LIMPIEZA COMPLETA AGRESIVA"
    echo ""
    echo "Esto hará lo siguiente:"
    echo "- Todo lo de la limpieza básica (journal a 3 días)"
    echo "- Vaciar toda la caché de usuario (~/.cache)"
    echo "- Vaciar la papelera"
    echo "- Borrar /tmp y /var/tmp con más de 3 días (sin tocar sockets)"
    echo "- Borrar .terraform (conserva .terraform.lock.hcl)"
    echo "- Borrar cachés de Python (__pycache__, .pytest_cache, .mypy_cache, .ruff_cache)"
    echo "- Borrar node_modules, excluyendo herramientas globales"
    echo "- Limpiar Flatpak sin uso y revisiones viejas de Snap"
    echo "- Docker/Podman sin volúmenes"
    echo ""
    echo "⚠️  Esto elimina muchos archivos regenerables."
    echo "⚠️  Puede romper proyectos temporalmente."
    echo ""

    ask "¿ESTÁS SEGURO?" || return

    begin
    system_cleanup 3
    user_safe_cleanup
    dev_cache_cleanup

    echo ">>> Toda la caché de usuario"
    clear_dir "$HOME/.cache"

    echo ">>> Papelera"
    clear_dir "$HOME/.local/share/Trash/files"
    clear_dir "$HOME/.local/share/Trash/info"

    echo ">>> /tmp con más de 3 días"
    find /tmp -xdev -mindepth 1 -maxdepth 1 -mtime +3 \
        ! -name 'systemd-private-*' \
        ! -name 'snap-private-tmp' \
        ! -name '.X11-unix' \
        ! -name '.ICE-unix' \
        ! -name '.font-unix' \
        ! -name '.XIM-unix' \
        ! -name 'dbus-*' \
        -exec rm -rf -- {} + 2>/dev/null

    echo ">>> /var/tmp con más de 3 días"
    if require_sudo; then
        sudo find /var/tmp -xdev -mindepth 1 -maxdepth 1 -mtime +3 \
            ! -name 'systemd-private-*' \
            -exec rm -rf -- {} + 2>/dev/null
    fi

    echo ">>> Carpetas .terraform"
    find "$HOME" -xdev -type d -name .terraform -prune -exec rm -rf -- {} + 2>/dev/null

    echo ">>> Cachés de Python"
    find "$HOME" -xdev -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache \) \
        -prune -exec rm -rf -- {} + 2>/dev/null
    find "$HOME" -xdev -type f -name '*.pyc' -delete 2>/dev/null

    echo ">>> node_modules (excluyendo herramientas globales)"
    find "$HOME" -xdev -type d -name node_modules \
        -not -path "$HOME/.config/*" \
        -not -path "$HOME/.local/*" \
        -not -path "$HOME/.npm/*" \
        -not -path "$HOME/.bun/*" \
        -not -path "$HOME/.cache/*" \
        -not -path "$HOME/.vscode*/*" \
        -not -path "$HOME/snap/*" \
        -prune -exec rm -rf -- {} + 2>/dev/null

    container_cleanup no
    packages_cleanup
    finish
}

android_cleanup() {
    echo ""
    echo ">>> LIMPIEZA ANDROID STUDIO / GRADLE"
    echo "Se eliminará:"
    echo "- Caché de Gradle (~/.gradle/caches, daemon, native)"
    echo "- Caché y logs de Android Studio"
    echo "- Carpetas build de Gradle/Android que contengan artefactos"
    echo "- Caché de ~/.android y snapshots de emuladores"
    echo ""

    ask "¿Continuar?" || return

    begin

    echo ">>> Caché de Gradle"
    rm -rf "$HOME/.gradle/caches" "$HOME/.gradle/daemon" "$HOME/.gradle/native"

    echo ">>> Caché y logs de Android Studio"
    find "$HOME/.cache" -maxdepth 3 -type d -path '*/Google/AndroidStudio*' \
        -prune -exec rm -rf -- {} + 2>/dev/null
    find "$HOME/.local/share/Google" -maxdepth 1 -type d -name 'AndroidStudio*' \
        -exec sh -c 'rm -rf -- "$1/log"' sh {} \; 2>/dev/null

    clean_gradle_builds

    echo ">>> Caché de Android y snapshots de AVD"
    clear_dir "$HOME/.android/cache"
    find "$HOME/.android/avd" -maxdepth 2 -type d -name snapshots \
        -prune -exec rm -rf -- {} + 2>/dev/null

    finish
}

dev_caches_menu() {
    echo ""
    echo ">>> CACHÉS DE DESARROLLO"
    echo "Se limpiarán cachés regenerables de las herramientas instaladas."
    echo ""

    ask "¿Continuar?" || return

    begin

    dev_cache_cleanup

    if have pnpm; then
        echo ">>> Caché de pnpm"
        pnpm store prune >/dev/null 2>&1 || true
    fi

    if have yarn; then
        echo ">>> Caché de yarn"
        yarn cache clean --all >/dev/null 2>&1 || yarn cache clean >/dev/null 2>&1 || true
    fi

    if [[ -d "$HOME/.bun/install/cache" ]]; then
        echo ">>> Caché de bun"
        rm -rf "$HOME/.bun/install/cache"
    fi

    if have go; then
        echo ">>> Caché de compilación de Go"
        go clean -cache >/dev/null 2>&1 || true
    fi

    if [[ -d "$HOME/.cargo/registry" || -d "$HOME/.cargo/git" ]]; then
        if pgrep -x cargo >/dev/null 2>&1; then
            echo ">>> Cargo está en ejecución; se omite su caché"
        else
            echo ">>> Caché de Cargo"
            rm -rf "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/src" "$HOME/.cargo/git/checkouts"
        fi
    fi

    if ask "¿Borrar también el module cache de Go? (se re-descarga)"; then
        have go && go clean -modcache >/dev/null 2>&1 || true
    fi

    if ask "¿Borrar también ~/.m2/repository de Maven? (se re-descarga)"; then
        rm -rf "$HOME/.m2/repository"
    fi

    if ask "¿Borrar también cachés de Gradle (~/.gradle/caches)? (se re-descarga)"; then
        rm -rf "$HOME/.gradle/caches" "$HOME/.gradle/daemon" "$HOME/.gradle/native"
    fi

    finish
}

containers_menu() {
    echo ""
    echo ">>> CONTENEDORES Y PAQUETES"
    echo "- Docker: contenedores, imágenes y build cache (sin volúmenes)"
    echo "- Podman: contenedores, imágenes y build cache (sin volúmenes)"
    echo "- Flatpak: runtimes sin uso"
    echo "- Snap: revisiones antiguas/deshabilitadas"
    echo ""

    ask "¿Continuar?" || return

    begin
    container_cleanup yes
    packages_cleanup
    finish
}

ide_cleanup() {
    local process running=0

    for process in code code-insiders idea idea64 pycharm pycharm64 webstorm webstorm64; do
        if pgrep -x "$process" >/dev/null 2>&1; then
            echo ">>> $process está en ejecución"
            running=1
        fi
    done

    if (( running )); then
        echo ""
        echo "Se recomienda cerrar los IDEs antes de limpiar sus cachés."
        ask "¿Continuar igualmente?" || return
    fi

    echo ""
    echo ">>> CACHÉS DE IDES"
    echo "- VS Code: Cache, Code Cache, GPUCache, CachedData, CachedExtensionVSIXs"
    echo "- VS Code: logs, crash reports, Service Worker y workspaceStorage de +30 días"
    echo "- JetBrains: cachés (~/.cache/JetBrains) y logs de Toolbox/IDEs"
    echo ""
    echo "No se tocan settings, extensiones, backups ni datos de plugins."
    echo ""

    ask "¿Continuar?" || return

    begin

    for cache in Cache 'Code Cache' GPUCache CachedData CachedExtensionVSIXs DawnGraphiteCache DawnWebGPUCache CachedProfilesData Crashpad; do
        clear_dir "$HOME/.config/Code/$cache"
    done
    clear_dir "$HOME/.config/Code/logs"

    find "$HOME/.config/Code/Service Worker" -maxdepth 2 -type d \
        \( -name CacheStorage -o -name ScriptCache \) \
        -prune -exec rm -rf -- {} + 2>/dev/null

    find "$HOME/.config/Code/User/workspaceStorage" -mindepth 1 -maxdepth 1 -type d -mtime +30 \
        -exec rm -rf -- {} + 2>/dev/null

    clear_dir "$HOME/.cache/JetBrains"

    for dir in "$HOME"/.local/share/JetBrains/*/log; do
        [[ -d "$dir" ]] && clear_dir "$dir"
    done
    clear_dir "$HOME/.local/share/JetBrains/Toolbox/logs"

    finish
}

analyze_disk() {
    echo ""
    echo ">>> ANALIZANDO DISCO CON NCDU"

    if have ncdu; then
        ncdu "$HOME"
    else
        if ask "ncdu no está instalado. ¿Instalarlo con dnf?"; then
            require_sudo || return
            sudo dnf install -y ncdu && ncdu "$HOME"
        fi
    fi

    pause
}

node_modules_menu() {
    echo ""
    echo ">>> LIMPIANDO NODE_MODULES CON NPKILL"
    echo "Podrás seleccionar qué borrar interactivamente."
    echo ""

    if have npx; then
        npx --yes npkill
    else
        echo "npx no disponible. Instala Node.js."
    fi

    pause
}

while true; do
    clear

    echo "=============================="
    echo "   LIMPIADOR - FEDORA - JAROD "
    echo "=============================="
    echo ""
    echo "1) Limpieza básica (segura)"
    echo "2) Limpieza completa (AGRESIVA)"
    echo "3) Limpieza Android Studio / Gradle"
    echo "4) Analizar disco con ncdu"
    echo "5) Limpiar node_modules (npkill)"
    echo "6) Cachés de desarrollo (npm, pip, uv, Go, Rust...)"
    echo "7) Contenedores y paquetes (Docker, Podman, Flatpak, Snap)"
    echo "8) Cachés de IDEs (VS Code, JetBrains)"
    echo "9) Salir"
    echo ""

    read -r -p "Selecciona una opción: " opcion

    case $opcion in
        1) basic_cleanup ;;
        2) aggressive_cleanup ;;
        3) android_cleanup ;;
        4) analyze_disk ;;
        5) node_modules_menu ;;
        6) dev_caches_menu ;;
        7) containers_menu ;;
        8) ide_cleanup ;;
        9) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
