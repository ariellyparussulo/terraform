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
  db:
    image: postgres:alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: always
    environment:
      POSTGRES_DB: giropops
      POSTGRES_USER: ${postgres_username}
      POSTGRES_PASSWORD: ${postgres_password}
    ports:
      - "5432:5432"

volumes:
  db_data: {}
EOT

cd /opt/ && docker-compose up -d