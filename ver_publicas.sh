#!/usr/bin/env bash
# ==========================================================
# ver_publica.sh
# Muestra una clave pública RSA en formato legible.
# - Pides un fichero (.pem / .pub)
# - Intentas leerlo como clave pública:
#     openssl rsa -pubin -in FILE -text -noout
#   ( -pubin = el input es una CLAVE PÚBLICA )
# - Si no es pública, se intenta como PRIVADA para extraer su pública:
#     openssl rsa -in FILE -pubout  (con pass si hace falta)
#   y se muestra el resultado.
# ==========================================================

APP_TITLE="Criptografía — Ver clave pública"

# Comprobaciones mínimas
command -v zenity >/dev/null 2>&1 || { echo "Falta 'zenity'." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { zenity --error --title="$APP_TITLE" --text="Falta 'openssl'."; exit 1; }

# 1) Seleccionar fichero que el usuario cree que es la pública
FILE=$(zenity --file-selection --title="$APP_TITLE - Selecciona clave pública (.pem/.pub)") || exit 0

# 2) Intento directo: tratarlo como PÚBLICA
#    -text     -> imprime campos de la clave (modulus, exponent, etc.)
#    -noout    -> no imprimir codificación base64, solo info legible
OUT_PUBLIC=$(openssl rsa -pubin -in "$FILE" -text -noout 2>&1) && {
  zenity --text-info --title="$APP_TITLE - Contenido legible (pública)" \
         --width=760 --height=520 --filename=<(echo "$OUT_PUBLIC")
  exit 0
}

# 3) Si falla, puede que el usuario haya elegido una PRIVADA
if zenity --question --title="$APP_TITLE" \
          --text="No parece una clave PÚBLICA.\n\n¿Intentar leerla como PRIVADA y mostrar su clave pública derivada?"; then

  # 3a) Primero intentamos sin passphrase (por si no está protegida)
  PUB_TMP=$(mktemp)
  if openssl rsa -in "$FILE" -pubout -out "$PUB_TMP" 2>/dev/null; then
    zenity --text-info --title="$APP_TITLE - Pública derivada de la privada" \
           --width=760 --height=520 --filename="$PUB_TMP"
    shred -u "$PUB_TMP"
    exit 0
  fi

  # 3b) Si falla, probablemente necesita passphrase: la pedimos
  PASS=$(zenity --password --title="$APP_TITLE - Introduce passphrase de la clave privada") || { shred -u "$PUB_TMP"; exit 0; }

  if openssl rsa -in "$FILE" -passin pass:"$PASS" -pubout -out "$PUB_TMP" 2>/dev/null; then
    zenity --text-info --title="$APP_TITLE - Pública derivada (con passphrase)" \
           --width=760 --height=520 --filename="$PUB_TMP"
    shred -u "$PUB_TMP"
    exit 0
  else
    shred -u "$PUB_TMP"
    zenity --error --title="$APP_TITLE" --text="No se pudo extraer la clave pública.\nPassphrase incorrecta o fichero inválido."
    exit 1
  fi
else
  # El usuario no quiso intentar como privada
  zenity --error --title="$APP_TITLE" --text="Operación cancelada o fichero no válido."
  exit 1
fi