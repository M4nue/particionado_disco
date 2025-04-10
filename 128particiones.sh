#!/bin/bash

# Archivo donde se guarda la selección
RESULTADO="resultado.txt"

# Obtener lista de discos disponibles (ignoramos particiones tipo loop)
discos=($(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print $1}'))

# Crear opciones para el menú de dialog
menu_opciones=()
for i in "${!discos[@]}"; do
    menu_opciones+=("$i" "${discos[$i]}")
done

# Mostrar menú de selección con dialog
dialog --clear \
       --title "Selecciona un Disco" \
       --menu "Elige el disco para ver sus particiones:" 15 50 6 \
       "${menu_opciones[@]}" \
       2> "$RESULTADO"

# Cancelado
if [ $? -ne 0 ]; then
    clear
    echo "Operación cancelada."
    exit 1
fi

# Leer selección desde el archivo
indice=$(cat "$RESULTADO")
disco_seleccionado="/dev/${discos[$indice]}"

# Obtener las particiones del disco
particiones=($(lsblk -ln -o NAME "$disco_seleccionado" | grep -v "^$(basename "$disco_seleccionado")$"))

# Mostrar barra de progreso
(
total=${#particiones[@]}
for i in "${!particiones[@]}"; do
    sleep 0.2  # Simula trabajo
    porc=$(( (i + 1) * 100 / total ))
    echo "$porc"
done
) | dialog --gauge "Leyendo particiones de $disco_seleccionado..." 10 60 0

# Mostrar las particiones encontradas
dialog --msgbox "Particiones de $disco_seleccionado:\n\n$(lsblk "$disco_seleccionado")" 20 70

# Limpiar pantalla y salir
clear
