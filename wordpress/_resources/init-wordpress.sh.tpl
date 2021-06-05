#!/bin/bash

echo "Atualizando pacotes..."
apt-get update && upgrade -y

echo "instalando curl..."
apt install curl -y


# install docker
echo "instalando docker.io..."
curl -fsSL https://get.docker.com | bash
docker --version


echo "instalando docker-compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod 777 /usr/bin/docker-compose
docker-compose version

echo "criando arquivo de docker-compose"

tee -a /opt/docker-compose.yml <<EOT
version: "3.9"

services:
  wordpress:
    image: wordpress:latest
    restart: always
    volumes:
      - wordpress:/var/www/html
    environment:
      WORDPRESS_DB_HOST: "${wordpress_url}"
      WORDPRESS_DB_USER: "${wordpress_username}"
      WORDPRESS_DB_PASSWORD: "${wordpress_password}"
      WORDPRESS_DB_NAME: "${wordpress_db}"
    ports:
      - "80:80"

volumes:
  wordpress:
EOT

cd /opt/ && docker-compose up -d