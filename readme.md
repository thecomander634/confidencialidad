🔐 Confidencialidad con Bash + Zenity (OpenSSL)

Scripts Bash con ventanitas (Zenity) para practicar confidencialidad:

✅ Generar claves RSA (privada + pública)

✅ Cifrar/Descifrar simétrico (AES-256 con clave aleatoria)

✅ Cifrar/Descifrar híbrido (datos con AES y la clave AES protegida con RSA)

✅ Ver, buscar, importar y exportar claves públicas

No necesitas ser experto en OpenSSL. El menú te guía. 😉

# 🚀 1) Requisitos, instalación y uso
Requisitos

Ubuntu/Debian (o similar)

bash, zenity, openssl

Instalación
sudo apt update
sudo apt install -y zenity openssl

# Dar permisos a los scripts (dentro de la carpeta del proyecto)
chmod +x menu.sh simetrico.sh generar_claves.sh ver_publica.sh gestion_publicas.sh

# Crear carpeta para las claves importadas
mkdir -p keyring

Uso rápido
./menu.sh

# 🗂️ 2) Estructura del proyecto
confidencialidad/
|--- menu.sh                  # Menú principal
|--- simetrico.sh             # Submenú: cifrar/descifrar (simétrico u híbrido)
|--- generar_claves.sh        # Generar RSA (privada + pública)
|--- ver_publica.sh           # Ver una clave pública legible
|--- gestion_publicas.sh      # Buscar/Importar/Exportar públicas
|--- keyring/                 # Carpeta local para guardar públicas importadas

# 🧭 3) Cómo se usa (paso a paso)
Arrancar el menú
./menu.sh

<img width="799" height="93" alt="Captura de pantalla 2025-10-17 193049" src="https://github.com/user-attachments/assets/6e7cefd1-f359-43f5-a8df-006b85875696" />

Verás una ventana con opciones:

Generar claves RSA

Visualizar clave pública

Cifrar/Descifrar (Simétrico u Híbrido)

Gestión de claves públicas (buscar/importar/exportar)

Salir

El menú se repite tras cada acción para que no tengas que relanzar nada.

<img width="641" height="465" alt="Captura de pantalla 2025-10-17 192922" src="https://github.com/user-attachments/assets/761b9d99-dfd6-492e-ac72-f9bef1f348b1" />

# 🛠️ 4) Qué hace cada script (y por qué)
<details> <summary><b>A) <code>generar_claves.sh</code> — Generar par RSA</b></summary>

Te pide carpeta destino y tamaño (2048 o 4096 bits).
Crea:

private.pem → clave privada (guárdala bien; solo tú)

public.pem → clave pública (esta sí puedes compartir)

Comandos clave (simple):

 Genera la privada RSA con el número de bits elegido
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:<BITS> -out private.pem

 Saca la pública desde la privada
openssl rsa -in private.pem -pubout -out public.pem


2048 te vale para la práctica; 4096 es más “tocho” y tarda un pelín más.
<img width="383" height="204" alt="Captura de pantalla 2025-10-17 194050" src="https://github.com/user-attachments/assets/114d6184-df81-4af2-948a-bd2cca904527" />

</details>
<details> <summary><b>B) <code>ver_publica.sh</code> — Ver una pública “bonita”</b></summary>

Seleccionas un archivo .pem/.pub.

Si es pública, la muestra (módulo, exponente, etc.).
<img width="874" height="650" alt="Captura de pantalla 2025-10-17 194309" src="https://github.com/user-attachments/assets/0cd31579-fc87-4697-b238-c9c7ad535bf1" />

Si por error eliges una privada, te ofrece sacar su pública.
<img width="607" height="191" alt="Captura de pantalla 2025-10-17 194340" src="https://github.com/user-attachments/assets/d704d6bf-4c5e-4875-af41-9440d4bfdab2" />

Comandos:

 Leer pública en modo legible
openssl rsa -pubin -in CLAVE_PUB.pem -text -noout

 Extraer pública desde una privada
openssl rsa -in CLAVE_PRIV.pem -pubout

</details>
<details> <summary><b>C) <code>simetrico.sh</code> — Cifrar/Descifrar Simétrico e Híbrido</b></summary>
1) Cifrar (AES-256, clave aleatoria)

Eliges archivo → genera key.bin (32 bytes) → crea archivo.enc.

openssl rand 32 > key.bin
openssl enc -aes-256-cbc -salt -pbkdf2 -in ORIGEN -out SALIDA -pass file:key.bin
 -aes-256-cbc (AES)
 -salt + -pbkdf2 endurecen la derivación de clave
 -pass file:key.bin usa el contenido de key.bin como “password”

# 2) Descifrar (AES-256)
openssl enc -d -aes-256-cbc -pbkdf2 -in CIFRADO.enc -out DESCIFRADO -pass file:key.bin
 -d = descifrar

# 3) Cifrar híbrido (AES + RSA pública)

Cifra datos con AES → data.enc

Cifra la clave AES con pública RSA → aes.key.enc
<img width="462" height="203" alt="image" src="https://github.com/user-attachments/assets/dec9c97d-4076-4616-9671-40e60d835708" />

openssl rand 32 > aes.tmp
openssl enc -aes-256-cbc -salt -pbkdf2 -in ORIGEN -out data.enc -pass file:aes.tmp
openssl pkeyutl -encrypt -pubin -inkey public.pem -in aes.tmp -out aes.key.enc
# (por defecto PKCS#1 v1.5; si piden OAEP, añade:
#  -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256)

# 4) Descifrar híbrido (AES + RSA privada)

Recupera clave AES con privada → descifra data.enc.

openssl pkeyutl -decrypt -inkey private.pem -in aes.key.enc -out aes.tmp
openssl enc -d -aes-256-cbc -pbkdf2 -in data.enc -out RECUPERADO -pass file:aes.tmp
 (el script borra aes.tmp al terminar)


Resumen mental del híbrido:
“Archivo grande” → AES (rápido)
“Clave AES” → RSA (seguro para compartirla)

</details>
<details> <summary><b>D) <code>gestion_publicas.sh</code> — Buscar/Importar/Exportar</b></summary>

Buscar: escanea una carpeta en busca de *.pem, *.pub, *_public.pem.

Importar: copia una pública a ./keyring/ (permiso 600).

Exportar: saca una pública desde keyring/ a otra ruta.

find DIRECTORIO -type f \( -name "*.pem" -o -name "*.pub" -o -name "*_public.pem" \)

</details>
# 5) Ejemplos rápidos (para probar que todo va)

Generar claves

./generar_claves.sh   # elige carpeta y 2048 bits → private.pem + public.pem


Cifrado simétrico

./simetrico.sh        # “Cifrar (AES-256)” → key.bin + archivo.enc


Descifrado simétrico

./simetrico.sh        # “Descifrar (AES-256)” → usa key.bin + archivo.enc


Híbrido

./simetrico.sh        # “Cifrar híbrido” → data.enc + aes.key.enc
## En el receptor: “Descifrar híbrido” con su private.pem


Ver pública

./ver_publica.sh      # selecciona public.pem


Gestión públicas

./gestion_publicas.sh # busca/importa/exporta

# 🧠 6) Breve explicación del cifrado híbrido

El cifrado híbrido combina simétrico y asimétrico para aprovechar lo mejor de cada uno:

AES (simétrico) cifra el archivo usando una clave aleatoria (rápido y eficiente).

RSA (asimétrico) protege esa clave AES cifrándola con la clave pública del destinatario.

Entregas dos ficheros:

data.enc: datos cifrados con AES

aes.key.enc: clave AES cifrada con la pública RSA

El destinatario usa su clave privada para descifrar aes.key.enc y recuperar la clave AES, con la que descifra data.enc.

Ventajas: rápido para archivos grandes (AES), seguro al distribuir la clave (RSA), patrón estándar (PGP, TLS, etc.).
