#!/usr/bin/env bash

set -xe

ssh -o StrictHostKeyChecking=no "${DEPLOY_USER}"@"${SERVER_IP}" << EOF
echo "#################################################################################################################"

    if [ \$(docker network ls | grep -c traefik-network) == 0 ]; then
        echo "Creating traefik network"
        docker network create -d bridge traefik-network
    fi

    if [ \$(docker ps | grep -c traefik) == 0 ]; then
        echo "Creating traefik container"
        docker run -d --network=traefik-network -p 80:80 -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name=traefik traefik:latest --api --docker
    fi

    EXISTING_MASTER_PROJECT=\$(ls | grep 'master' | grep -v 'backup')
    EXISTING_DEV_PROJECT=\$(ls | grep 'dev')

    if [ ${TRAVIS_BRANCH} == 'dev' ]; then
        if [ ! -d ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-* ]; then
            git clone -b ${TRAVIS_BRANCH} --single-branch git@github.com:${TRAVIS_REPO_SLUG}.git ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-$RANDOM
            cd ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-*
            git checkout ${TRAVIS_COMMIT::8}
            cp .env.example .env
            PROJECT_NAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} DOMAIN_NAME=${DEV_DOMAIN} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} docker-compose up -d
          else
            cd ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-*
            git pull origin ${TRAVIS_BRANCH}
            git checkout ${TRAVIS_COMMIT::8}
            PROJECT_NAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} DOMAIN_NAME=${DEV_DOMAIN} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} docker-compose up -d
        fi

        docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} composer install --no-dev --no-progress --optimize-autoloader --no-interaction --no-ansi
        docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush si --account-pass=${ADMIN_PASS} --yes;

        if [ \$(docker exec \${EXISTING_MASTER_PROJECT} drush status bootstrap 2> /dev/null | grep -c Successful) == 1 ]; then
            docker exec -i \${EXISTING_MASTER_PROJECT} drush sql-dump --result-file=../dump.sql
            sudo mv ../${TRAVIS_REPO_SLUG#*/}-master-*/code/drupal/dump.sql ./code/drupal
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush sql-cli < ./code/drupal/dump.sql
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush -y cim
          else
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush cim --partial
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush -y csim live_config
        fi

        docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush -y dcdi
        docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush updb
        docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH} drush cr
    fi

    if [ ${TRAVIS_BRANCH} == 'master' ]; then
        if [ ! -d ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-* ]; then
            git clone -b ${TRAVIS_BRANCH} --single-branch git@github.com:${TRAVIS_REPO_SLUG}.git ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8}
            cd ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8}
            cp .env.example .env
            PROJECT_NAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} DOMAIN_NAME=${PRO_DOMAIN} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} docker-compose up -d
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} composer install --no-dev --no-progress --optimize-autoloader --no-interaction --no-ansi
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush si --account-pass=${ADMIN_PASS} --yes;
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush cim --partial
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush -y csim live_config
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush -y dcdi
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush updb
            docker exec -i ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} drush cr

          else
            if [ -d backup-${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-* ]; then
                echo "Removing previous backup"
                docker rm -f -v \$(docker ps -a -q --filter name=backup)
                sudo rm -rf backup-${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-*
            fi

            mv \${EXISTING_MASTER_PROJECT} backup-\${EXISTING_MASTER_PROJECT}
            mv \${EXISTING_DEV_PROJECT} ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8}

            cd ${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8}
            PROJECT_NAME=${TRAVIS_REPO_SLUG#*/}-${TRAVIS_BRANCH}-${TRAVIS_COMMIT::8} DOMAIN_NAME=${PRO_DOMAIN} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} docker-compose -p \${EXISTING_DEV_PROJECT} up -d
            cd ..

            ACTIVE_MASTER_PROJECT_NAME=\$(docker inspect  --format "{{ index .Config.Labels \"com.docker.compose.project\"}}" \${EXISTING_MASTER_PROJECT})
            cd backup-\${EXISTING_MASTER_PROJECT}
            PROJECT_NAME=backup-\${EXISTING_MASTER_PROJECT} DOMAIN_NAME=${PRO_DOMAIN} MYSQL_USER=${MYSQL_USER} MYSQL_PASSWORD=${MYSQL_PASSWORD} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} docker-compose -p \${ACTIVE_MASTER_PROJECT_NAME} up --no-start
            rm .env
        fi
    fi

echo "#################################################################################################################"
EOF
