#!/bin/bash
# Levanta los 4 servicios del proyecto desde la carpeta donde se clonó el repositorio
set -e
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
cd "$RAIZ"

echo "== Limpiando contenedores anteriores =="
docker rm -f nginx-basico servidor-personalizado nginx-red nginx-volumen 2>/dev/null || true

echo "== 1/4 Nginx básico (8080) =="
docker run -d --name nginx-basico -p 8080:80 -v "$RAIZ/web":/usr/share/nginx/html nginx

echo "== 2/4 Imagen personalizada (8081) =="
docker build -t servidor-grupo1 .
docker run -d --name servidor-personalizado -p 8081:80 servidor-grupo1

echo "== 3/4 Red personalizada (8082) =="
docker network inspect red-proyecto >/dev/null 2>&1 || docker network create red-proyecto
docker run -d --name nginx-red --network red-proyecto -p 8082:80 nginx

echo "== 4/4 Volumen persistente (8083) =="
docker volume inspect volumen-web >/dev/null 2>&1 || docker volume create volumen-web
docker run -d --name nginx-volumen -p 8083:80 -v volumen-web:/usr/share/nginx/html nginx
docker exec nginx-volumen sh -c 'echo "<h1>Volumen persistente - Grupo 1</h1>" > /usr/share/nginx/html/index.html'

echo "== Servicios activos =="
docker ps
if command -v curl >/dev/null; then
  for p in 8080 8081 8082 8083; do echo -n "Puerto $p: "; curl -sI http://localhost:$p | head -1; done
fi


