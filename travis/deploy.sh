#!/usr/bin/env bash

# Prepare Env variables 
PROJECT_NAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}
MYSQL_HOSTNAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}.mariadb
if [ ${TRAVIS_BRANCH} == master ]; then 
SERVER=${MASTER_SERVER}
DOMAIN_NAME=${MASTER_DOMAIN}
MYSQL_HOSTNAME=${PROJECT_NAME}.mariadb
MYSQL_USER=${MASTER_MYSQL_USER} 
MYSQL_PASSWORD=${MASTER_MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=${MASTER_MYSQL_ROOT_PASSWORD}
ADMIN_PASS=${MASTER_ADMIN_PASS}
fi
if [ ${TRAVIS_BRANCH} == dev ]; then 
SERVER=${DEV_SERVER} 
DOMAIN_NAME=${DEV_DOMAIN}
MYSQL_HOSTNAME=${PROJECT_NAME}.mariadb
MYSQL_USER=${DEV_MYSQL_USER}
MYSQL_PASSWORD=${DEV_MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=${DEV_MYSQL_ROOT_PASSWORD}
ADMIN_PASS=${DEV_ADMIN_PASS}
fi


ssh -o StrictHostKeyChecking=no "${DEPLOY_USER}"@"${SERVER}" << EOF

# Functions Definition
drupal_install(){
    if [ \$(docker network ls | grep -c traefik-network) == 0 ]; then
        echo "Creating traefik network";
        docker network create -d bridge traefik-network;
    fi
    if [ \$(docker ps | grep -c traefik) == 0 ]; then
        echo "Creating traefik container";
        docker run -d --network=traefik-network -p 80:80 -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name=traefik traefik:latest --api --docker;
    fi
    if [ ! -e .env ]; then 
    cp .env.example .env; 
    fi
    PROJECT_NAME=${PROJECT_NAME} DOMAIN_NAME=${DOMAIN_NAME} MYSQL_HOSTNAME=${MYSQL_HOSTNAME} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} docker-compose up -d;
    docker exec -i ${PROJECT_NAME} composer install --no-dev --no-progress --optimize-autoloader --no-interaction --no-ansi;
    docker exec -i ${PROJECT_NAME} drush si --account-pass=${ADMIN_PASS} --yes;
}




if [ ! -d "${PROJECT_NAME}" ]; then
    git clone -b ${TRAVIS_BRANCH} --single-branch git@github.com:${TRAVIS_REPO_SLUG}.git ${PROJECT_NAME};
    cd ${PROJECT_NAME};
    drupal_install;
else
    cd ${PROJECT_NAME};
    git pull origin ${TRAVIS_BRANCH};
    if [ \$(docker exec ${PROJECT_NAME} drush status bootstrap | grep -c Successful) == 0 ]; then
        echo "Previous Drupal has been corrupted. Install a fresh Drupal again";
        docker rm -f \$(docker ps -a -q)
        docker system prune -f
        cd ..
        sudo rm -rf ${PROJECT_NAME}
        git clone -b ${TRAVIS_BRANCH} --single-branch git@github.com:${TRAVIS_REPO_SLUG}.git ${PROJECT_NAME};
        cd ${PROJECT_NAME};
        drupal_install;
    fi
    PROJECT_NAME=${PROJECT_NAME} DOMAIN_NAME=${DOMAIN_NAME} MYSQL_HOSTNAME=${MYSQL_HOSTNAME} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} docker-compose up -d;
    docker exec -i ${PROJECT_NAME} composer install --no-dev --no-progress --optimize-autoloader --no-interaction --no-ansi;
    docker exec -i ${PROJECT_NAME} drush cim;
    docker exec -i ${PROJECT_NAME} drush cr;
fi


EOF
