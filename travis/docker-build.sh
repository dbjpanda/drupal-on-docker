#!/usr/bin/env bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'

# Check if any chnages has been made inside "docker" directory
if git diff HEAD^ --exit-code --name-only docker
then
echo $red No chnages inside docker directory $white 
else
echo $red Above files have been chnaged inside docker directory. $white 
# Building imgaes from docker files 
docker build -t "$DOCKER_USERNAME"/drupal-on-docker-nginx ./docker/nginx
docker build -t "$DOCKER_USERNAME"/drupal-on-docker-php ./docker/php
docker build -t "$DOCKER_USERNAME"/drupal-on-docker-mariadb ./docker/mariadb
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
# Pushing images to docker hub registry
docker push "$DOCKER_USERNAME"/drupal-on-docker-nginx
docker push "$DOCKER_USERNAME"/drupal-on-docker-php
docker push "$DOCKER_USERNAME"/drupal-on-docker-mariadb
fi
