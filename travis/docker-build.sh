#!/usr/bin/env bash

red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
white=$'\e[0m'

# Check if any chnages has been made inside "docker" directory
if [ git diff HEAD^ --exit-code --name-only docker ]; then
    echo $red No chnages inside docker directory $white
else
    echo $red Above files have been chnaged inside docker directory. $white
 
    # Building imgaes from docker files
    docker build -t "$DOCKER_USERNAME"/"${TRAVIS_REPO_SLUG#*/}"-nginx ./docker/nginx
    docker build -t "$DOCKER_USERNAME"/"${TRAVIS_REPO_SLUG#*/}"-php ./docker/php
    docker build -t "$DOCKER_USERNAME"/"${TRAVIS_REPO_SLUG#*/}"-mariadb ./docker/mariadb

    # Integration check of newly built images
    docker network create -d bridge traefik-network
    docker run -d --network=traefik-network -p 80:80 -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name=traefik traefik:latest --api --docker
    cp .env.example .env
    docker-compose up -d
    docker exec -it test composer install
    docker exec -it test drush si --yes
 
    # Push images to Docker Hub
    if [ $(docker exec test drush status bootstrap | grep -c Successful) == 1 ]; then
        echo $grn Drupal has been sucessfully installed. Images are ready to be pushed to Docker Hub $white
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
        docker push "$DOCKER_USERNAME"/drupal-on-docker-nginx
        docker push "$DOCKER_USERNAME"/drupal-on-docker-php
        docker push "$DOCKER_USERNAME"/drupal-on-docker-mariadb

        # Clean up
        docker rm -f $(docker ps -a -q)
        docker system prune -f
        sudo rm -rf ./code/drupal
    else
        echo $red Docker build failed and images are not ready to push to dockerhub $white
        exit 1
    fi
fi