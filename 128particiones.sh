#!/bin/bash

# Verificar si el usuario tiene permisos de root

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root, o tienes que tener permisos de administrador"
else
  # Verificar e instalar parted si no está presente

  if ! command -v parted >/dev/null 2>&1; then
    echo "parted no está instalado. Instalándolo..."
    apt update
    apt install parted -y
    if [ $? -ne 0 ]; then
      echo "Error al instalar parted. Verifica tu conexión o repositorios."
    fi
  else
    echo "parted ya está instalado."
  fi

  # Verificar e instalar bc si no está presente

  if ! command -v bc >/dev/null 2>&1; then
    echo "bc no está instalado. Instalándolo..."
    apt update
    apt install bc -y
    if [ $? -ne 0 ]; then
      echo "Error al instalar bc. Verifica tu conexión o repositorios."
    fi
  else
    echo "bc ya está instalado."
  fi

  # Listar discos disponibles
  echo "Estos son los discos disponibles que tienes en el sistema:"
  lsblk -d -o NAME,SIZE | grep -v "NAME" | awk '{print NR") /dev/"$1" - "$2}'
  echo ""

  # Solicitar al usuario que elija un disco
  read -p "Introduce el disco que deseas particionar: " NUM_DISCO

  # Obtener el disco seleccionado
  DISCO=$(lsblk -d -o NAME | grep -v "NAME" | sed -n "${NUM_DISCO}p" | awk '{print "/dev/"$1}')

  # Verificar si el disco existe
  if [ ! -b "$DISCO" ]; then
    echo "El disco seleccionado no es válido o no existe."
  else
    # Mostrar el disco seleccionado
    echo "Disco seleccionado: $DISCO"

    # Verificar que ambos estén instalados antes de continuar
    if command -v parted >/dev/null 2>&1 && command -v bc >/dev/null 2>&1; then
      # Advertencia al usuario
      echo "Esto eliminará todos los datos en $DISCO y emzará a particionarse, ¿ quieres continuar? (s/n)"
      read respuesta
      if [ "$respuesta" != "s" ]; then
        echo "Operación cancelada."
      else
        # Crear una nueva tabla de particiones GPT
        echo "Creando tabla GPT en $DISCO..."
        parted -s "$DISCO" mklabel gpt

        # Calcular el tamaño de cada partición automáticamente
        TAMANIO_TOTAL=$(parted -s "$DISCO" unit MB print | grep "Disk $DISCO" | awk '{print $3}' | sed 's/MB//')
        TAMANIO_PARTICION=$(echo "$TAMANIO_TOTAL / 128" | bc)

        echo "Tamaño total del disco: $TAMANIO_TOTAL MB"
        echo "Tamaño de cada partición: $TAMANIO_PARTICION MB"

        # Crear las 128 particiones
        for ((i=1; i<=128; i++))
        do
          INICIO=$(( (i-1) * TAMANIO_PARTICION ))
          FIN=$(( i * TAMANIO_PARTICION ))
  
          echo "Creando partición $i: de ${INICIO}MB a ${FIN}MB"
          parted -s "$DISCO" mkpart primary ${INICIO}MB ${FIN}MB
        done

        echo "Ya esta listo el particionado."
        parted -s "$DISCO" print

        echo "Script finalizado"
      fi
    else
      echo "No se pudo continuar."
    fi
  fi
fi
