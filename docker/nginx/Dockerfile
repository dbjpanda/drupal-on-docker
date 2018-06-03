FROM nginx:stable-alpine

# Drupal specific enviroment variables
ENV SITE_NAME=localhost \
    DRUPAL_VERSION=8 \
    MYSQL_DATABASE=drupal \
    MYSQL_USER=root \
    MYSQL_PASS=pass \
    MYSQL_HOST_NAME=mariadb \
    MYSQL_PORT=3306

COPY nginx.conf /etc/nginx
COPY conf.d /etc/nginx/conf.d
COPY entrypoint.sh /
COPY drupal /drupal

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]