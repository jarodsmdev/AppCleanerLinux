#!/bin/bash

while true; do

clear

echo "=============================="
echo "   LIMPIADOR - FEDORA - JAROD "
echo "=============================="
echo ""
echo "1) Limpieza básica (segura)"
echo "2) Limpieza completa (AGRESIVA)"
echo "3) Limpieza Android Studio"
echo "4) Analizar disco con ncdu"
echo "5) Limpiar node_modules (npkill)"
echo "6) Salir"
echo ""

read -p "Selecciona una opción: " opcion

case $opcion in

  1)
    echo ""
    echo ">>> LIMPIEZA BÁSICA"
    echo "Se realizará:"
    echo "- Eliminar paquetes innecesarios (dnf autoremove)"
    echo "- Limpiar cache de dnf"
    echo "- Limpiar ~/.cache"
    echo "- Limpiar thumbnails"
    echo "- Limpiar logs antiguos (7 días)"
    echo ""

    read -p "¿Continuar? (y/n): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && continue

    echo ">>> Eliminando paquetes innecesarios..."
    sudo dnf autoremove -y

    echo ">>> Limpiando cache de dnf..."
    sudo dnf clean all

    echo ">>> Limpiando cache de usuario..."
    rm -rf ~/.cache/*

    echo ">>> Limpiando thumbnails..."
    rm -rf ~/.cache/thumbnails/*

    echo ">>> Limpiando logs antiguos..."
    sudo journalctl --vacuum-time=7d

    echo ">>> Limpieza básica completada."
    read -p "Presiona Enter para volver al menú..."
    ;;

  2)
    echo ""
    echo ">>> LIMPIEZA COMPLETA AGRESIVA"
    echo ""
    echo "Esto hará lo siguiente:"
    echo "- Limpiar sistema (dnf)"
    echo "- Borrar TODAS las caches (~/.cache)"
    echo "- Vaciar papelera"
    echo "- Limpiar logs (3 días)"
    echo "- Borrar /tmp y /var/tmp"
    echo "- Limpiar Docker (TODO: imágenes, contenedores, volúmenes)"
    echo "- Limpiar Flatpak no usado"
    echo "- BORRAR todos los .terraform"
    echo "- BORRAR todos los node_modules"
    echo "- BORRAR caches Python (__pycache__, *.pyc)"
    echo ""
    echo "⚠️  Esto eliminará MUCHOS archivos regenerables."
    echo "⚠️  Puede romper proyectos temporalmente."
    echo ""

    read -p "¿ESTÁS SEGURO? (y/n): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && continue

    echo ">>> Limpiando sistema (dnf)..."
    sudo dnf autoremove -y
    sudo dnf clean all

    echo ">>> Limpiando cache de usuario..."
    rm -rf ~/.cache/*

    echo ">>> Vaciando papelera..."
    rm -rf ~/.local/share/Trash/*

    echo ">>> Limpiando logs..."
    sudo journalctl --vacuum-time=3d

    echo ">>> Limpiando /tmp..."
    sudo rm -rf /tmp/*

    echo ">>> Limpiando /var/tmp..."
    sudo rm -rf /var/tmp/*

    echo ">>> Limpiando Docker..."
    docker system prune -a -f 2>/dev/null || sudo docker system prune -a -f
    docker volume prune -f 2>/dev/null || sudo docker volume prune -f

    echo ">>> Limpiando Flatpak..."
    if command -v flatpak &> /dev/null; then
        flatpak uninstall --unused -y
    fi

    echo ">>> Eliminando carpetas .terraform..."
    find ~ -type d -name ".terraform" -prune -exec rm -rf {} + 2>/dev/null

    echo ">>> Eliminando archivos .terraform.lock.hcl..."
    find ~ -type f -name ".terraform.lock.hcl" -delete 2>/dev/null

    echo ">>> Eliminando caches Python (__pycache__, *.pyc)..."
    find ~ -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null
    find ~ -type f -name "*.pyc" -delete 2>/dev/null

    echo ">>> Eliminando TODOS los node_modules..."
    find ~ -type d -name "node_modules" -prune -exec rm -rf {} + 2>/dev/null

    echo ">>> LIMPIEZA COMPLETA TERMINADA"
    read -p "Presiona Enter para volver al menú..."
    ;;

  3)
    echo ""
    echo ">>> LIMPIEZA ANDROID STUDIO"
    echo "Se eliminará:"
    echo "- Caché de Gradle"
    echo "- Logs de Android Studio"
    echo "- Carpetas build de proyectos"
    echo ""

    read -p "¿Continuar? (y/n): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && continue

    echo ">>> Limpiando Gradle..."
    rm -rf ~/.gradle/caches/
    rm -rf ~/.gradle/daemon/
    rm -rf ~/.gradle/native/

    echo ">>> Limpiando logs Android Studio..."
    rm -rf ~/.cache/Google/AndroidStudio*
    rm -rf ~/.local/share/Google/AndroidStudio*/log/

    echo ">>> Eliminando carpetas build..."
    find ~ -type d -name "build" -exec rm -rf {} + 2>/dev/null

    echo ">>> Android Studio limpio."
    read -p "Presiona Enter para volver al menú..."
    ;;

  4)
    echo ""
    echo ">>> Analizando disco con ncdu..."

    if command -v ncdu &> /dev/null; then
        ncdu ~
    else
        echo ">>> ncdu no está instalado. Instalando..."
        sudo dnf install -y ncdu
        ncdu ~
    fi

    read -p "Presiona Enter para volver al menú..."
    ;;

  5)
    echo ""
    echo ">>> Ejecutando npkill (node_modules)..."
    echo "Podrás seleccionar qué borrar interactivamente."
    echo ""

    if command -v npx &> /dev/null; then
        npx --yes npkill
    else
        echo ">>> npx no disponible. Instala Node.js."
    fi

    read -p "Presiona Enter para volver al menú..."
    ;;

  6)
    echo "Saliendo..."
    exit 0
    ;;

  *)
    echo "Opción inválida"
    read -p "Presiona Enter para continuar..."
    ;;
esac

done
