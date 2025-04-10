#!/bin/bash

# Archivo donde se guarda la selección
RESULTADO="resultado.txt"

# Detectar todos los discos, incluidos loop, nvme, vdb, etc.
discos=($(lsblk -dpno NAME,TYPE | awk '$2 == "disk" {print $1}'))

# Crear opciones para el menú de dialog
menu_opciones=()
for i in "${!discos[@]}"; do
    menu_opciones+=("$i" "${discos[$i]}")
done

# Mostrar menú de selección con dialog
dialog --clear \
       --title "Selecciona un Disco" \
       --menu "Elige el disco donde se crearán 128 particiones:" 20 70 10 \
       "${menu_opciones[@]}" \
       2> "$RESULTADO"

# Cancelado
if [ $? -ne 0 ]; then
    clear
    echo "Operación cancelada."
    exit 1
fi

# Obtener el disco seleccionado desde resultado.txt
indice=$(cat "$RESULTADO")
disco="${discos[$indice]}"

# Confirmar
dialog --yesno "Se crearán 128 particiones en el disco:\n\n$disco\n\n¿Deseas continuar?\n¡Esto borrará su contenido!" 12 60
if [ $? -ne 0 ]; then
    clear
    echo "Operación cancelada por el usuario."
    exit 1
fi

# Borrar tabla de particiones existente
parted -s "$disco" mklabel gpt

# Obtener tamaño total del disco en MiB
tamanio_total=$(parted -s "$disco" unit MiB print | awk '/Disk.*size/ {gsub("MiB","",$3); print int($3)}')

# Calcular tamaño de cada partición
tamanio_particion=$((tamanio_total / 128))

# Crear particiones con barra de progreso
(
for i in $(seq 0 127); do
    inicio=$((i * tamanio_particion))
    fin=$(((i + 1) * tamanio_particion - 1))
    parted -s "$disco" mkpart primary ${inicio}MiB ${fin}MiB &>/dev/null
    porc=$(( (i + 1) * 100 / 128 ))
    echo "$porc"
    sleep 0.05  # pequeña pausa para ver la barra progresar
done
) | dialog --title "Creando particiones" --gauge "Particionando $disco..." 10 60 0

# Mensaje final
dialog --title "Proceso terminado" --msgbox "Se han creado 128 particiones en $disco exitosamente." 10 50

clear
