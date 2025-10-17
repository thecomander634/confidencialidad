#!/usr/bin/bash
# Menú principal (Zenity) para la práctica de OpenSSL
# Opciones simplificadas: la 3ª reúne cifrar/descifrar (simétrico u híbrido).

APP_TITLE="Criptografía — Menú principal"

# Comprobación mínima
command -v zenity >/dev/null 2>&1 || {
  echo "Necesitas 'zenity' instalado." >&2
  exit 1
}

while true; do
  ELECCION="$(
    zenity --list \
      --title="$APP_TITLE" \
      --text="Selecciona la operación que deseas realizar:" \
      --column="ID" --column="Acción" \
      1 "Generar claves RSA" \
      2 "Visualizar clave pública" \
      3 "Cifrar/Descifrar (Simétrico u Híbrido)" \
      4 "Gestión de claves públicas (buscar/importar/exportar)" \
      0 "Salir" \
      --height=360 --width=560
  )" || exit 0  # si cierra la ventana, salir

  case "$ELECCION" in
    1)
      if [[ -x ./generar_claves.sh ]]; then ./generar_claves.sh
      else zenity --info --title="$APP_TITLE" --text="Pendiente: ./generar_claves.sh"; fi
      ;;
    2)
      if [[ -x ./ver_publica.sh ]]; then ./ver_publica.sh
      else zenity --info --title="$APP_TITLE" --text="Pendiente: ./ver_publica.sh"; fi
      ;;
    3)
      if [[ -x ./simetrico.sh ]]; then ./simetrico.sh
      else zenity --info --title="$APP_TITLE" --text="Pendiente: ./simetrico.sh"; fi
      ;;
    4)
      if [[ -x ./gestion_publicas.sh ]]; then ./gestion_publicas.sh
      else zenity --info --title="$APP_TITLE" --text="Pendiente: ./gestion_publicas.sh"; fi
      ;;
    0) exit 0 ;;
    *) zenity --error --title="$APP_TITLE" --text="Opción no válida." ;;
  esac
done