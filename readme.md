scripts Bash con ventanitas (Zenity) para practicar confidencialidad:

Generar claves RSA (privada + pública)

Cifrar/Descifrar simétrico (AES-256 con clave aleatoria)

Cifrar/Descifrar híbrido (datos con AES y la clave AES protegida con RSA)

Ver, buscar, importar y exportar claves públicas

No necesitas ser experto en OpenSSL. El menú te guía.

1) Requisitos e instalación

En Ubuntu/Debian (o similares):

sudo apt update
sudo apt install -y zenity openssl

Dar permisos a los scripts (en la carpeta del proyecto):
chmod +x menu.sh simetrico.sh generar_claves.sh ver_publica.sh gestion_publicas.sh
crear carpeta keyring para futuras claves:
mkdir -p keyring

2) Estructura del proyecto
confidencialidad/
|--- menu.sh                  # Menú principal
|--- simetrico.sh             # Submenú: cifrar/descifrar (simétrico u híbrido)
|--- generar_claves.sh        # Generar RSA (privada + pública)
|--- ver_publica.sh           # Ver una clave pública legible
|--- gestion_publicas.sh      # Buscar/Importar/Exportar públicas
|--- keyring/                 # Carpeta local para guardar públicas importadas

3) Cómo se usa (paso a paso)
Arrancar el menú
./menu.sh


Verás una ventana con opciones:

Generar claves RSA

Visualizar clave pública

Cifrar/Descifrar (Simétrico u Híbrido)

Gestión de claves públicas (buscar/importar/exportar)

Salir

El menú se repite tras cada acción para que no tengas que relanzar nada.

4) Qué hace cada script (y por qué)
    A) generar_claves.sh — Generar par RSA

Te pide carpeta destino y tamaño (2048 o 4096 bits).

Crea:

private.pem → clave privada (guárdala bien; solo tú)

public.pem → clave pública (esta sí puedes compartir)

Comandos clave dentro del script (explicados simple):

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:<BITS> -out private.pem
→ Genera la privada RSA con el número de bits que elijas.
Si marcaste passphrase, añade -aes-256-cbc -pass pass:TU_PASS para cifrar la privada en disco.

openssl rsa -in private.pem -pubout -out public.pem
→ Saca la pública desde la privada.

Consejito: 2048 te vale para la práctica; 4096 es más “tocho” y tarda un pelín más.

    B) ver_publica.sh — Ver una pública “bonita”

Seleccionas un archivo .pem/.pub.

Si es pública, la muestra en modo legible (módulo, exponente, etc.).

Si sin querer eliges una privada, te pregunta si quiere sacar su pública (si tiene passphrase, te la pide).

Comandos clave:

openssl rsa -pubin -in CLAVE_PUB.pem -text -noout
→ -pubin le dice a OpenSSL que lo de entrada es una pública.
-text saca los datos “bonitos”; -noout evita volcar el bloque base64.

openssl rsa -in CLAVE_PRIV.pem -pubout
→ Extrae la pública desde la privada (pide pass si estaba protegida).

    C) simetrico.sh — Cifrar/Descifrar Simétrico e Híbrido

Al entrar aquí verás un submenú:

Cifrar (AES-256, clave aleatoria)

Te pide el archivo a cifrar.

Genera una clave aleatoria de 32 bytes y te deja guardarla (ej. key.bin).

Cifra el archivo a loquesea.enc.

Comandos:

openssl rand 32 > key.bin → Crea una clave aleatoria (32 bytes = 256 bits).

openssl enc -aes-256-cbc -salt -pbkdf2 -in ORIGEN -out SALIDA -pass file:key.bin

-aes-256-cbc → algoritmo simétrico (AES-256 en modo CBC).

-salt + -pbkdf2 → hace la derivación de clave más segura (evita ataques tontos).

-pass file:key.bin → usa el contenido de key.bin como contraseña.

Descifrar (AES-256)

Te pide el .enc, la key.bin y un nombre de salida.

Con eso te recupera el fichero original.

Comando:

openssl enc -d -aes-256-cbc -pbkdf2 -in CIFRADO.enc -out DESCIFRADO -pass file:key.bin

-d → descifrar.

Cifrar híbrido (AES + RSA pública)

Cifra los datos con AES (igual que el punto 1), pero la clave AES no se guarda en claro:

Se cifra esa clave AES con la RSA pública y se guarda aparte (dos ficheros de salida):

datos.enc → datos cifrados con AES

aes.key.enc → la clave AES cifrada con RSA pública

Comandos:

openssl rand 32 > aes.tmp → clave AES temporal

openssl enc -aes-256-cbc -salt -pbkdf2 -in ORIGEN -out datos.enc -pass file:aes.tmp

openssl pkeyutl -encrypt -pubin -inkey public.pem -in aes.tmp -out aes.key.enc
→ pkeyutl -encrypt con la pública cifra la clave AES.

Por defecto es padding PKCS#1 v1.5 (suficiente para la práctica).
Si tu profe pide OAEP, sería:
-pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256

Descifrar híbrido (AES + RSA privada)

Al revés:

Descifras aes.key.enc con tu privada RSA para recuperar la clave AES

Con esa clave ya puedes descifrar datos.enc.

Comandos:

openssl pkeyutl -decrypt -inkey private.pem -in aes.key.enc -out aes.tmp
→ Con la privada, recuperas la clave AES original.

openssl enc -d -aes-256-cbc -pbkdf2 -in datos.enc -out RECUPERADO -pass file:aes.tmp
→ Descifra los datos. (El script borra el tmp al terminar.)

Resumen mental del híbrido:
“Archivo grande” → AES (rápido)
“Clave AES” → RSA (segura para compartirla con el destinatario)

    D) gestion_publicas.sh — Buscar/Importar/Exportar

Buscar: eliges un directorio y escanea ficheros que parezcan públicas: *.pem, *.pub, *_public.pem.
(No busca por todo / para no tardar la vida; tú eliges la carpeta.)

Importar: seleccionas una pública y se copia a ./keyring/ (ajustando permisos a 600).

Exportar: lista lo que hay en keyring/ y copias una pública a otra ruta.

Comando clave de búsqueda:

find DIRECTORIO -type f \( -name "*.pem" -o -name "*.pub" -o -name "*_public.pem" \)

5) Ejemplos rápidos (para probar que todo va)

Generar claves
./generar_claves.sh → elige carpeta y 2048 bits → tendrás private.pem y public.pem.

Cifrado simétrico
./simetrico.sh → opción “Cifrar (AES-256)” → te genera key.bin y archivo.enc.

Descifrado simétrico
./simetrico.sh → “Descifrar (AES-256)” → usa key.bin y archivo.enc → recuperas el original.

Híbrido
./simetrico.sh → “Cifrar híbrido” → te da datos.enc + aes.key.enc.
En otra máquina (que tenga la privada que corresponde a tu public.pem) → “Descifrar híbrido”.

Ver pública
./ver_publica.sh → selecciona public.pem → verás info legible.

Gestión públicas
./gestion_publicas.sh → busca/importa/exporta.

6) Dónde mirar los archivos generados

RSA: private.pem (secreta), public.pem (compartible)

Simétrico: key.bin (secreta), loque-sea.enc

Híbrido: data.enc (o similar) + aes.key.enc

Keyring: públicas importadas en ./keyring/

NO subas private.pem ni key.bin a nubes, repos públicos, etc.

7) Errores típicos y cómo arreglarlos

“zenity: command not found” → sudo apt install -y zenity

“openssl: command not found” → sudo apt install -y openssl

“bad decrypt” al descifrar AES → Clave equivocada o .enc no corresponde con esa key.bin.

No abre una pública en ver_publica.sh → puede que seleccionaste una privada; dile “sí” a extraer pública; si está protegida, mete la pass.

No puede descifrar híbrido → Asegúrate de usar la privada que corresponde a la pública usada para cifrar, y que aes.key.enc y data.enc son pareja.

8) Consejos de seguridad (mínimos)

Mantén permisos de claves: chmod 600 private.pem key.bin

Borra temporales sensibles cuando acabes (el script ya “shredea” lo crítico en híbrido, pero si haces pruebas, limpia).

Si vas a entregar la práctica: comprime la carpeta sin incluir private.pem ni key.bin si no te lo piden expresamente.

