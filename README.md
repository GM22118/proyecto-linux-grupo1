# Proyecto Final: Servidor Linux Automatizado con Docker (Grupo 1)

**Universidad de El Salvador** · Facultad Multidisciplinaria de Occidente
Ingeniería en Desarrollo de Software / Educación en Línea
Introducción al Software Libre · Ciclo II – 2026
Tutora: Ing. Graciela Albaluz Escalante Grijalva

## Descripción

Este proyecto implementa un servidor Linux automatizado mediante contenedores Docker. Integra administración de sistemas (usuarios, grupos y permisos), automatización con un script bash y cron, control de versiones con Git/GitHub y virtualización con Docker (Nginx, Dockerfile personalizado, redes y volúmenes).

**Entorno:** Ubuntu 26.04 LTS en una máquina virtual de VirtualBox · Docker 29.1.3

## Integrantes

| Nombre | Carnet | Fases |
|---|---|---|
| Byron Josue Gomez Monge | GM22118 | 1, 2 y 3 |
| América Medrano | MM00130 | 4, 5 y 6 |
| Javier Edgardo Vásquez Galeano | VG25001 | 7 y 8 |

## Estructura del proyecto

```
/proyecto/
├── Dockerfile
├── README.md
├── capturas/      # Evidencias del proyecto
├── datos/         # Archivos de configuración (grupo: soporte)
├── scripts/
│   └── reporte_sistema.sh
└── web/           # Sitio web (grupo: web)
    ├── favicon.ico
    └── index.html
```

## Servicios y puertos

| Contenedor | Puerto host | Descripción |
|---|---|---|
| `nginx-basico` | 8080 | Nginx oficial con `/proyecto/web/` montado como volumen |
| `servidor-personalizado` | 8081 | Imagen propia `servidor-grupo1` construida con Dockerfile |
| `nginx-red` | 8082 | Nginx conectado a la red `red-proyecto` |
| `nginx-volumen` | 8083 | Nginx con el volumen persistente `volumen-web` |

## Pasos de instalación

### Fase 1: Preparación del entorno servidor

**1.1 Administración básica del sistema**

```bash
sudo hostnamectl set-hostname servidor-grupo1

sudo adduser adminsys
sudo adduser tecnico
sudo adduser visitante

sudo groupadd soporte
sudo groupadd web

sudo usermod -aG sudo adminsys
sudo usermod -aG soporte tecnico
sudo usermod -aG web visitante

id adminsys && id tecnico && id visitante
```

**1.2 Estructura de directorios y permisos**

```bash
sudo mkdir -p /proyecto/{datos,web,scripts,capturas}
sudo chown -R adminsys:adminsys /proyecto

sudo chgrp soporte /proyecto/datos
sudo chgrp web /proyecto/web

# El bit setgid (2) hace que los archivos nuevos hereden el grupo del directorio
sudo chmod 2775 /proyecto/datos /proyecto/web
ls -l /proyecto
```

### Fase 2: Automatización y monitoreo

**2.1 Script de monitoreo**

`scripts/reporte_sistema.sh` muestra fecha y hora, nombre del host, usuarios conectados, espacio libre en disco, RAM disponible y contenedores Docker activos.

```bash
chmod +x /proyecto/scripts/reporte_sistema.sh
/proyecto/scripts/reporte_sistema.sh
```

**2.2 Automatización con cron**

```bash
sudo mkdir -p /var/log/proyecto
sudo chown adminsys:adminsys /var/log/proyecto
sudo systemctl enable --now cron

crontab -e
# Agregar la línea:
# */30 * * * * /proyecto/scripts/reporte_sistema.sh >> /var/log/proyecto/reporte_sistema.log 2>&1

crontab -l
tail -f /var/log/proyecto/reporte_sistema.log
```

### Fase 3: Control de versiones

```bash
cd /proyecto
touch datos/.gitkeep capturas/.gitkeep   # Git no guarda carpetas vacías
git init
git add .
git commit -m "Commit inicial: estructura completa del proyecto"
git remote add origin https://github.com/GM22118/proyecto-linux-grupo1.git
git push -u origin main
```

GitHub no acepta la contraseña de la cuenta para operaciones Git: se usa un **Personal Access Token** como contraseña.

### Fase 4: Docker

**4.1 Instalación y configuración**

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker adminsys
sudo usermod -aG docker tecnico
docker --version
```

**4.2 Verificación inicial**

```bash
docker run hello-world
docker ps -a
```

### Fase 5: Servidor web containerizado

**5.1 Contenedor Nginx básico**

```bash
docker run -d --name nginx-basico -p 8080:80 \
  -v /proyecto/web:/usr/share/nginx/html nginx
docker ps
```

**5.2 Verificación del servicio web**

```bash
curl http://localhost:8080
docker logs nginx-basico
```

Acceso desde el navegador: <http://localhost:8080>

### Fase 6: Docker avanzado

**6.1 Dockerfile personalizado**

```dockerfile
FROM nginx:latest
COPY web/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
cd /proyecto
docker build -t servidor-grupo1 .
docker images
```

**6.2 Contenedor con imagen personalizada**

```bash
docker run -d --name servidor-personalizado -p 8081:80 servidor-grupo1
curl http://localhost:8081
```

| Aspecto | Nginx oficial (8080) | Imagen personalizada (8081) |
|---|---|---|
| Origen del contenido | Volumen montado desde el host | Copiado dentro de la imagen |
| Cambios en `index.html` | Inmediatos | Requieren reconstruir la imagen |
| Portabilidad | Depende de la carpeta del host | Autocontenida |

### Fase 7: Redes y volúmenes Docker

**7.1 Red personalizada**

```bash
docker network create red-proyecto
docker run -d --name nginx-red --network red-proyecto -p 8082:80 nginx
docker network ls
docker network inspect red-proyecto
```

**7.2 Volúmenes persistentes**

```bash
docker volume create volumen-web
docker run -d --name nginx-volumen -p 8083:80 \
  -v volumen-web:/usr/share/nginx/html nginx
docker volume inspect volumen-web
docker inspect nginx-volumen --format '{{json .Mounts}}'
```

### Fase 8: Pruebas y verificación final

**8.1 Pruebas de conectividad**

```bash
docker run -it --rm --network red-proyecto alpine ping -c 4 nginx-red
```

**8.2 Verificación integral**

```bash
docker ps
for p in 8080 8081 8082 8083; do echo "Puerto $p:"; curl -sI http://localhost:$p | head -1; done
tail -n 30 /var/log/proyecto/reporte_sistema.log
git status
git log --oneline
```

## Comandos útiles

```bash
docker ps                     # Contenedores activos
docker logs <nombre>          # Logs de un contenedor
docker start <nombre>         # Iniciar un contenedor detenido
docker rm -f <nombre>         # Eliminar un contenedor
```

## Evidencias

Las capturas de cada fase están en el informe PDF entregado.

## Licencia

Proyecto académico desarrollado con software libre (Linux, Docker, Nginx, Git).
