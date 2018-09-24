#!/usr/bin/env bash

docker network create -d bridge traefik-network
docker run -d --network=traefik-network -p 80:80 -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name=traefik traefik:latest --api --docker
cp .env.example .env
docker-compose up -d
docker exec -it test composer install
docker exec -it test drush si --yes

if [ $(docker exec test drush status bootstrap | grep -c Successful) == 1 ]; then
   echo $grn Drupal has been sucessfully built and tested. $white
else
   echo $red Drupal build failed $white
fi

