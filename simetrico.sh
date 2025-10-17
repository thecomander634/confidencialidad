#!/usr/bin/env bash
# Submenú de Cifrar/Descifrar (Simétrico u Híbrido)
# Requisitos: bash, zenity, openssl

APP_TITLE="Criptografía — Cifrar/Descifrar"

command -v zenity >/dev/null 2>&1 || { echo "Falta 'zenity'." >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { zenity --error --title="$APP_TITLE" --text="Falta 'openssl'."; exit 1; }

while true; do
  OPCION="$(
    zenity --list \
      --title="$APP_TITLE" \
      --text="Elige una operación:" \
      --column="ID" --column="Acción" \
      1 "Cifrar (AES-256, clave aleatoria)" \
      2 "Descifrar (AES-256)" \
      3 "Cifrar híbrido (AES + RSA pública)" \
      4 "Descifrar híbrido (AES + RSA privada)" \
      0 "Volver" \
      --height=380 --width=640
  )" || exit 0

  case "$OPCION" in
    1)  # Cifrar simétrico AES-256
        IN=$(zenity --file-selection --title="$APP_TITLE - Selecciona archivo a cifrar") || continue
        KEY=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar clave aleatoria (32B)" --filename="$(dirname "$IN")/key.bin") || continue
        OUT=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar archivo cifrado" --filename="$(basename "$IN").enc") || continue

        openssl rand 32 > "$KEY" || { zenity --error --title="$APP_TITLE" --text="No se pudo generar la clave."; continue; }
        openssl enc -aes-256-cbc -salt -pbkdf2 -in "$IN" -out "$OUT" -pass file:"$KEY" \
          && zenity --info --title="$APP_TITLE" --text="Cifrado correcto:\n$OUT\nClave guardada en:\n$KEY" \
          || zenity --error --title="$APP_TITLE" --text="Fallo al cifrar."
        ;;
    2)  # Descifrar simétrico AES-256
        ENC=$(zenity --file-selection --title="$APP_TITLE - Selecciona archivo cifrado (.enc)") || continue
        KEY=$(zenity --file-selection --title="$APP_TITLE - Selecciona key.bin") || continue
        OUT=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar archivo descifrado" --filename="descifrado.out") || continue

        openssl enc -d -aes-256-cbc -pbkdf2 -in "$ENC" -out "$OUT" -pass file:"$KEY" \
          && zenity --info --title="$APP_TITLE" --text="Descifrado correcto:\n$OUT" \
          || zenity --error --title="$APP_TITLE" --text="Fallo al descifrar (revisa key.bin y el archivo)."
        ;;
    3)  # Cifrar híbrido (AES + RSA pública)
        IN=$(zenity --file-selection --title="$APP_TITLE - Selecciona archivo a cifrar") || continue
        PUB=$(zenity --file-selection --title="$APP_TITLE - Selecciona clave pública RSA (.pem)") || continue
        OUT_DATA=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar datos cifrados" --filename="$(basename "$IN").enc") || continue
        OUT_KEY=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar clave AES cifrada" --filename="$(basename "$IN").key.enc") || continue

        TMP=$(mktemp)
        openssl rand 32 > "$TMP" || { rm -f "$TMP"; zenity --error --title="$APP_TITLE" --text="No se pudo generar la clave AES."; continue; }
        if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$IN" -out "$OUT_DATA" -pass file:"$TMP" \
           && openssl pkeyutl -encrypt -pubin -inkey "$PUB" -in "$TMP" -out "$OUT_KEY"; then
          shred -u "$TMP"
          zenity --info --title="$APP_TITLE" --text="Cifrado híbrido correcto:\n$OUT_DATA\n$OUT_KEY"
        else
          shred -u "$TMP"
          zenity --error --title="$APP_TITLE" --text="Fallo en el cifrado híbrido (revisa la clave pública)."
        fi
        ;;
    4)  # Descifrar híbrido (AES + RSA privada)
        DATA=$(zenity --file-selection --title="$APP_TITLE - Selecciona archivo.enc") || continue
        KEYC=$(zenity --file-selection --title="$APP_TITLE - Selecciona aes.key.enc") || continue
        PRIV=$(zenity --file-selection --title="$APP_TITLE - Selecciona clave privada RSA (private.pem por defecto)") || continue
        OUT=$(zenity --file-selection --save --confirm-overwrite --title="$APP_TITLE - Guardar archivo descifrado" --filename="descifrado.out") || continue

        TMP=$(mktemp)
        if openssl pkeyutl -decrypt -inkey "$PRIV" -in "$KEYC" -out "$TMP" \
           && openssl enc -d -aes-256-cbc -pbkdf2 -in "$DATA" -out "$OUT" -pass file:"$TMP"; then
          shred -u "$TMP"
          zenity --info --title="$APP_TITLE" --text="Descifrado híbrido correcto:\n$OUT"
        else
          shred -u "$TMP"
          zenity --error --title="$APP_TITLE" --text="Fallo en el descifrado híbrido (privada incorrecta o archivos no coinciden)."
        fi
        ;;
    0) exit 0 ;;
    *) zenity --error --title="$APP_TITLE" --text="Opción no válida." ;;
  esac
done