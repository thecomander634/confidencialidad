#!/usr/bin/env bash
# ==========================================================
# gestion_publicas.sh
# Gestión simple de claves públicas:
#   1) Buscar claves públicas por directorio
#   2) Importar una clave pública al "keyring" local
#   3) Exportar una clave pública desde el "keyring" a otra ruta
#
# Notas rápidas:
#  - El "keyring" es una carpeta local (./keyring) donde guardamos públicas.
#  - Para buscar usamos `find` con patrones típicos: *.pem, *.pub, *_public.pem
#  - Ajustamos permisos con `chmod 600` (solo el usuario) por limpieza.
# ==========================================================

APP_TITLE="Criptografía — Gestión de claves públicas"
KEYRING="./keyring"

# Comprobaciones mínimas
command -v zenity >/dev/null 2>&1 || { echo "Falta 'zenity'." >&2; exit 1; }
mkdir -p "$KEYRING" 2>/dev/null || true

while true; do
  OPCION="$(
    zenity --list \
      --title="$APP_TITLE" \
      --text="Elige una opción:" \
      --column="ID" --column="Acción" \
      1 "Buscar claves públicas en un directorio" \
      2 "Importar clave pública al keyring" \
      3 "Exportar clave pública del keyring" \
      0 "Volver" \
      --height=320 --width=620
  )" || exit 0

  case "$OPCION" in
    1)
      # --- Buscar claves públicas ---
      # Explicación: `find DIR -type f \( -name "*.pem" -o -name "*.pub" -o -name "*_public.pem" \)`
      # Busca ficheros que suelen ser claves públicas. Evitamos escanear todo el sistema: pedimos una carpeta.
      DIR=$(zenity --file-selection --directory --title="$APP_TITLE - Selecciona carpeta a escanear") || continue
      [ -d "$DIR" ] || { zenity --error --title="$APP_TITLE" --text="Carpeta no válida."; continue; }

      # Hacemos la búsqueda y mostramos resultados en una ventana de texto
      TMP=$(mktemp)
      # 2>/dev/null para silenciar permisos denegados
      find "$DIR" -type f \( -name "*.pem" -o -name "*.pub" -o -name "*_public.pem" \) 2>/dev/null > "$TMP"

      if [[ ! -s "$TMP" ]]; then
        echo "Sin resultados." > "$TMP"
      fi

      zenity --text-info --title="$APP_TITLE - Resultados de búsqueda" \
             --width=760 --height=520 --filename="$TMP"
      rm -f "$TMP"
      ;;

    2)
      # --- Importar clave pública ---
      # Copiamos la clave seleccionada al keyring y ajustamos permisos.
      FILE=$(zenity --file-selection --title="$APP_TITLE - Selecciona clave pública a importar") || continue
      BASENAME=$(basename "$FILE")
      if cp -f "$FILE" "$KEYRING/$BASENAME"; then
        chmod 600 "$KEYRING/$BASENAME" 2>/dev/null || true
        zenity --info --title="$APP_TITLE" --text="Clave importada en:\n$KEYRING/$BASENAME"
      else
        zenity --error --title="$APP_TITLE" --text="No se pudo importar la clave (revisa permisos/ruta)."
      fi
      ;;

    3)
      # --- Exportar clave pública ---
      # Listamos lo que haya en el keyring y dejamos escoger una clave para copiarla a otra carpeta.
      # `ls -1` genera una lista simple de ficheros; si está vacío, avisamos.
      MAPA=$(mktemp)
      ls -1 "$KEYRING" > "$MAPA" 2>/dev/null || true
      if [[ ! -s "$MAPA" ]]; then
        rm -f "$MAPA"
        zenity --error --title="$APP_TITLE" --text="No hay claves en $KEYRING para exportar."
        continue
      fi

      SEL=$(zenity --list --title="$APP_TITLE - Selecciona clave a exportar" \
                   --text="Claves en $KEYRING:" --column="Clave pública" \
                   $(cat "$MAPA") --height=360 --width=600) || { rm -f "$MAPA"; continue; }
      rm -f "$MAPA"

      DEST=$(zenity --file-selection --directory --title="$APP_TITLE - Selecciona carpeta destino") || continue
      if cp -f "$KEYRING/$SEL" "$DEST/"; then
        zenity --info --title="$APP_TITLE" --text="Exportada a:\n$DEST/$SEL"
      else
        zenity --error --title="$APP_TITLE" --text="No se pudo exportar la clave (revisa permisos/ruta)."
      fi
      ;;

    0) exit 0 ;;
    *) zenity --error --title="$APP_TITLE" --text="Opción no válida." ;;
  esac
done