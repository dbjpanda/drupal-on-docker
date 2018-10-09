[![Build Status](https://travis-ci.com/dbjpanda/drupal-on-docker.svg?token=55CADUHzgmryMHLpbyAs&branch=master)](https://travis-ci.com/dbjpanda/drupal-on-docker)

Setup Traefik (Ground Work)
--------------
Enable Traefik proxy server following below commands to access your services using a "Domain name" instead of "IP:port". This is an one time setup and use with all projects. This is useful for both Drupal and Non-Drupal projects. As this project is configured to work with Traefik by default so we recommend you should set up it first if you have not done it yet. If you don't want to enable Traefik, then you need to manually provide a port number to services and access them using localhost:port.
```
docker network create -d bridge traefik-network
docker run -d --network=traefik-network -p 80:80 -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name=traefik traefik:latest --api --docker
```

Installation 
------------
Step 1 
``````
git clone https://github.com/dbjpanda/drupal-on-docker.git && cd drupal-on-docker
```````
Step 2 
````````
Rename .env.example to .env and modify the variables like PROJECT_NAME etc as per your requirements
``````````````
Step 3
````````
docker-compose up -d
````````

Step 4
````````
docker exec -it PROJECT_NAME composer install
````````
Step 5  (Install drupal via drush or through the url 'DOMAIN_NAME' set in .env file)
```
docker exec -it PROJECT_NAME drush si
```


Devops workflow  ( If you want to deploy to a live server using CI/CD)
----------------
Step 1
```
git clone https://github.com/dbjpanda/drupal-on-docker.git PROJECT_NAME
```
Step 2
``````
cd PROJECT_NAME 
``````
Step 3
``````
git remote set-url origin https://your_github_project_url
``````
Step 4  ( We have created a branch 8.x-dev for you adding 3 necessary modules like config_suite, config_split, default_content_deploy and its configuration which make this workflow really easy. You can delete the branch and create your own )
``````
git checkout 8.x-dev 
``````
Step 5 ( Change the branch name as per your convenience. Default is 'dev'. If you want to change the branch name other than 'dev' then change it in travis/deploy.sh as well)
``````
git branch -m dev
``````

Step 6 (You must have root permission to execute this script)
``````
./travis/server-setup.sh
``````

Step 7 (Change travis env variables such as DEPLOY_SERVER, secure etc. according to your requirement and encrypt sensitive variables like below)
``````
travis encrypt MYSQL_USER=travis MYSQL_PASSWORD=travistest MYSQL_ROOT_PASSWORD=helloworld ADMIN_PASS=pass DOCKER_USERNAME=dbjpanda DOCKER_PASSWORD=pass
``````

Step 8
``````
Setup Travis for the repo, push your changes and your work is done as an admin or devop engineer. You sucessfully setup the project. Now its time for developers and site builders
``````
Step 9 (Ask your developers to clone the repo, checkout to 'dev', follow the installation process, code or build the site, push changes to remote dev branch. Some useful commands given below)
``````
cp .env.example .env
docker exec -it PROJECT_NAME composer install
IMPORT CONFIG: docker exec -it PROJECT_NAME drush cim --partial
IMPORT DEV CONFIG: docker exec -it PROJECT_NAME drush csim dev_config
IMPORT BLOCK CONTENT: docker exec -it PROJECT_NAME drush dcdi
CODE......................DESIGN................
EXPORT CONFIG: docker exec -it PROJECT_NAME drush csex
EXPORT CONTENT: docker exec -it PROJECT_NAME drush dcdes --skip_entity_type=node,user

``````
Step 10 ( Ask your analytics team to go to the site http://dev.example.com and check if it is ready to push to live server then execute below commands)
``````
git checkout master 
git pull origin dev 
git push origin master
``````
Note: If you faced some issue suddenly after pushing the new changes and you need to roll back to backup then ssh to your server and execute the below command
` docker start \$(docker ps -a -q --filter name=backup) `

