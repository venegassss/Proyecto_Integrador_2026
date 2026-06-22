# Parte 1 – Distribución Linux Personalizada con Cubic

## Base utilizada

Ubuntu 24.04.4 Desktop AMD64

## Nombre de la distribución

UIDE Linux 2026

## Modificaciones realizadas

### 1. Instalación de herramientas de desarrollo y administración

Se instalaron los siguientes programas:

* Neovim
* Git
* Htop
* Curl

**Justificación:** Estas herramientas facilitan tareas de programación, administración de sistemas y monitoreo de recursos y son faciles de descargar.

### 2. Modificación del software de navegación

Se eliminó Firefox y se instaló Chromium como alternativa basada en el motor Chromium.

**Justificación:** Ofrecer una alternativa de navegación diferente a la configuración predeterminada del sistema.

### 3. Personalización persistente mediante /etc/skel

Se creó el archivo:

bienvenida.txt

para que aparezca automáticamente en los nuevos usuarios creados a partir de la instalación.

**Justificación:** Demostrar una personalización persistente aplicada a todos los usuarios del sistema.

## Verificación

La ISO fue probada en VirtualBox.

Resultados:

* La ISO arranca correctamente.
* El archivo bienvenida.txt aparece después de la instalación.
* Los programas instalados se encuentran disponibles y funcionales.

## Checksum SHA256

57c63eb468882b286ea6c2459642452af85acd9e3000f03decb49acb106ab0a2d

## Evidencias

Las capturas de pantalla se encuentran en la carpeta Capturas .

## ISO

https://drive.google.com/file/d/19fOBPkfh9H9PmdcxBtM9WdSrzjgSK6zT/view?usp=sharing

# Parte 2 — Kernel de 64 bits

## Integrantes
- Henry Quijia
- Isaak Romero
- Cristofer Venegas

## Descripción
Kernel de 64 bits construido desde cero usando NASM, GCC cross-compiler y GRUB.
Arranca en QEMU mediante un ISO generado con grub-mkrescue.

## Estructura del proyecto
parte2/
├── Dockerfile           < entorno de compilación reproducible
├── Makefile             < targets: all, clean
├── linker.ld            < script del linker
├── grub/
    └── grub.cfg         < configuración de GRUB
├── screenshots/         < capturas de evidencia
└── src/
    ├── header.asm       < Multiboot2 header (Episodio 1)
    ├── main.asm         < verificaciones + paginación + GDT (Episodio 2)
    ├── long_mode.asm    < salto a 64 bits (Episodio 2)
    └── kernel.c         < función print_str en C (Episodio 2)

## Requisitos
- Docker
- QEMU (qemu-system-x86_64)

## Instrucción de build en una línea
docker build -t kernel-builder . && docker run --rm -v $(pwd):/kernel kernel-builder make all

## Pasos completos

### 1. Construir la imagen Docker
docker build -t kernel-builder .

### 2. Compilar el kernel
docker run --rm -v $(pwd):/kernel kernel-builder make all

### 3. Ejecutar en QEMU
qemu-system-x86_64 -cdrom kernel.iso -boot d -m 512M

## Episodio 1 — Multiboot2 + OK en QEMU
- Se crea el header Multiboot2 en header.asm con el magic number 0xe85250d6
- El kernel arranca en modo protegido de 32 bits
- Escribe directamente en la memoria VGA 0xB8000 para imprimir OK
- GRUB reconoce el kernel y lo carga correctamente

## Episodio 2 — Kernel 64 bits completo
- Verifica magic number de Multiboot2 en registro EAX
- Verifica soporte de CPUID en la CPU
- Verifica soporte de long mode de 64 bits
- Configura tablas de paginación identity-map primer GB con huge pages de 2MB
- Construye GDT de 64 bits
- Salta a long mode con far jump
- Llama a kernel_main en C que imprime mensaje personalizado del grupo

# Parte 3 — Laboratorio Black Hat Bash y Técnica de Hacking

## 3.A — Laboratorio desplegado

### Entorno
- VM: Debian 12 (bookworm), VirtualBox
- Docker + Docker Compose instalados desde el repositorio oficial de Docker

### Pasos realizados
1. Instalación de Docker y Docker Compose
2. Clonado del repositorio: `git clone https://github.com/dolevf/Black-Hat-Bash.git`
3. Construcción manual de la imagen base (`lab_base`) debido a un problema de orden de build con BuildKit
4. Despliegue del laboratorio: `sudo make deploy`
5. Verificación: `sudo make test` → "Lab is up."

### Arquitectura del laboratorio
| Máquina | Red(es) | IP(s) | Hostname |
|---|---|---|---|
| p-web-01 | Pública | 172.16.10.10 | p-web-01.acme-infinity-servers.com |
| p-web-02 | Pública + Corporativa | 172.16.10.12 / 10.1.0.11 | - |
| p-ftp-01 | Pública | 172.16.10.11 | - |
| p-jumpbox-01 | Pública + Corporativa | 172.16.10.13 / 10.1.0.12 | - |
| c-backup-01 | Corporativa | 10.1.0.15 | - |
| c-db-01 | Corporativa | 10.1.0.16 | - |
| c-db-02 | Corporativa | 10.1.0.14 | - |
| c-redis-01 | Corporativa | 10.1.0.13 | - |

**Nota de seguridad:** `p-web-02` y `p-jumpbox-01` tienen interfaces en ambas redes (pública y corporativa), lo que las convierte en puntos potenciales de pivote para movimiento lateral si fueran comprometidas desde la red pública.

### Redes
- `br_public`: 172.16.10.0/24 (bridge host: 172.16.10.1)
- `br_corporate`: 10.1.0.0/24 (bridge host: 10.1.0.1)

Verificado con: `ip addr | grep "br_"` → confirma `br_public` en `172.16.10.1/24` y `br_corporate` en `10.1.0.1/24`.

### Evidencia
- `capturas/make_deploy.png`
- `capturas/make_test.png`
- `capturas/docker_ps.png`
- `capturas/ip_addr.png`
- `capturas/docker_exec.png`

---

## 3.B — Técnica de hacking

### Técnica 1: Escaneo de puertos (Nmap)

**Comando:** `nmap -sV -sC 172.16.10.10 -oN scan_web01.txt`

**Resultado:** Solo el puerto 8081/TCP abierto, fingerprint de Werkzeug/3.0.1 Python/3.12.3 (servidor de desarrollo Flask).

**Qué hace:** Escanea puertos abiertos y, con `-sV`, intenta identificar el servicio y su versión exacta analizando las respuestas del servicio.

**Por qué funciona:** Los servicios responden con banners o comportamientos característicos que Nmap compara contra su base de firmas para deducir software y versión.

### Técnica 2: Fingerprinting web (WhatWeb)

**Comando:** `whatweb -v http://172.16.10.10:8081`

**Resultado:** Confirma HTML5, Werkzeug 3.0.1, Python 3.12.3.

**Qué hace:** Analiza cabeceras HTTP, metadatos del HTML y patrones conocidos para identificar tecnologías, frameworks y servidores.

**Por qué funciona:** Las aplicaciones web dejan huellas (cabeceras como `Server:`, estructura del HTML) que WhatWeb compara contra firmas conocidas en su base de datos.

**Interpretación:** Confirmamos que p-web-01 corre una aplicación Flask sobre el servidor de desarrollo Werkzeug 3.0.1 con Python 3.12.3. Esto es relevante porque Werkzeug está diseñado para desarrollo, no producción: carece de las protecciones de un servidor WSGI real (como Gunicorn detrás de un proxy), y si el modo debug estuviera activo, podría exponer un depurador interactivo con riesgo de ejecución remota de código. No se explotó esta condición — el alcance del ejercicio fue de reconocimiento, identificando la superficie de ataque y tecnología expuesta.

### Evidencia
- `capturas/nmap_scan.png`
- `capturas/whatweb.png`
- `evidencia/scan_web01.txt`

---

## Cómo reproducir esta parte
1. Instalar Docker (ver comandos en la sección de instalación arriba)
2. Clonar: `git clone https://github.com/dolevf/Black-Hat-Bash.git && cd Black-Hat-Bash/lab`
3. Construir la base manualmente: `docker build -f machines/Dockerfile-base -t lab_base .`
4. Desplegar: `sudo make deploy`
5. Verificar: `sudo make test`
6. Instalar herramientas: `sudo apt-get install -y nmap whatweb`
7. Ejecutar técnicas contra 172.16.10.10

## Diagrama de red
![Diagrama de red](capturas/red_diagrama.png)
