[![Build Status](https://travis-ci.com/dbjpanda/drupal-on-docker.svg?token=55CADUHzgmryMHLpbyAs&branch=master)](https://travis-ci.com/dbjpanda/drupal-on-docker)

Installation on development server
----------------------
Step 1 
``````
git clone https://github.com/dbjpanda/drupal-on-docker.git
```````
Step 2 (optional)
````````
Modify .env file as per your requirements
``````````````
Step 3
````````
docker-compose up -d
````````

Step 4
````````
docker exec -it php composer install
````````


Installation on production server
---------------------------
Here you need to override the default environment variables for production server. You can achieve it by below command while deploying.

````````
SITE_NAME=example.com MYSQL_USER=someone MYSQL_PASS=yoursecrets docker-compose up -d
``````````````
