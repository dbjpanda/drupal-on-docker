[![Build Status](https://travis-ci.com/dbjpanda/drupal-on-docker.svg?token=55CADUHzgmryMHLpbyAs&branch=master)](https://travis-ci.com/dbjpanda/drupal-on-docker)

Setup Traefik (Recommended)
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
git clone https://github.com/dbjpanda/drupal-on-docker.git
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

Note: While installing it on production server
---------------------------
As deployment is less frequent or often done by automated setup so here you can override the default environment variables using below command instead of changing it in .env file.

````````
SITE_NAME=example.com MYSQL_USER=someone MYSQL_PASS=yoursecrets docker-compose up -d
``````````````
