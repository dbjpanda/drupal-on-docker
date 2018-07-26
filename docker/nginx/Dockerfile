FROM nginx:stable-alpine

# Drupal specific enviroment variables
ENV PROJECT_NAME=test \
    DOMAIN_NAME=localhost \
    DRUPAL_VERSION=8 \
    MYSQL_HOSTNAME=mariadb \
    MYSQL_DATABASE=drupal \
    MYSQL_USER=root \
    MYSQL_PASSWORD=pass \
    MYSQL_PORT=3306

COPY nginx.conf /etc/nginx
COPY conf.d /etc/nginx/conf.d
COPY entrypoint.sh /
COPY drupal /drupal

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
