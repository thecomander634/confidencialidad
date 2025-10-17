#!/usr/bin/env bash
# ==========================================================
# generar_claves.sh (sin passphrase)
# - Pide carpeta de destino
# - Pide tamaño (2048 / 4096)
# - Genera private.pem y public.pem sin pedir contraseña
# ==========================================================

APP_TITLE="Criptografía — Generar claves RSA"

# Dependencias mínimas
command -v zenity >/dev/null 2>&1 || { echo "Falta 'zenity'." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { zenity --error --title="$APP_TITLE" --text="Falta 'openssl'."; exit 1; }

# 1) Carpeta de destino
DEST=$(zenity --file-selection --directory --title="$APP_TITLE - Selecciona carpeta de destino") || exit 0
[ -d "$DEST" ] || { zenity --error --title="$APP_TITLE" --text="Carpeta no válida."; exit 1; }

# 2) Tamaño de clave RSA
BITS=$(
  zenity --list \
    --title="$APP_TITLE - Tamaño de clave" \
    --text="Elige el tamaño de la clave RSA:" \
    --column="bits" 2048 4096 \
    --height=220 --width=380
) || exit 0
[ -n "$BITS" ] || { zenity --error --title="$APP_TITLE" --text="No se seleccionó tamaño de clave."; exit 1; }

# 3) Rutas de salida
PRIV="$DEST/private.pem"
PUB="$DEST/public.pem"

# 4) Generar clave PRIVADA (sin passphrase)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:"$BITS" -out "$PRIV" \
  || { zenity --error --title="$APP_TITLE" --text="Error generando la clave privada."; exit 1; }

# 5) Extraer clave PÚBLICA desde la privada
openssl rsa -in "$PRIV" -pubout -out "$PUB" \
  || { zenity --error --title="$APP_TITLE" --text="Error extrayendo la clave pública."; exit 1; }

# 6) Permisos (solo usuario)
chmod 600 "$PRIV" 2>/dev/null || true
chmod 600 "$PUB"  2>/dev/null || true

# 7) Mensaje final
zenity --info --title="$APP_TITLE" --text="Claves generadas correctamente:\n\n$PRIV\n$PUB" || true
