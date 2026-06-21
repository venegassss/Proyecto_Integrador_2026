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
