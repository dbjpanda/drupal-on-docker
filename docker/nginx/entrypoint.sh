#!/bin/sh

set -e

mkdir -p /etc/nginx/sites-enabled
cp /etc/nginx/conf.d/drupal-"$DRUPAL_VERSION".conf /etc/nginx/sites-enabled/"$SITE_NAME"
sed -i "s% domain_name% $SITE_NAME%" /etc/nginx/sites-enabled/"$SITE_NAME"
sed -i "s% public_html_root% /var/www/$SITE_NAME/web%" /etc/nginx/sites-enabled/"$SITE_NAME"
sed -i "s% site_name_php% "$SITE_NAME".php%" /etc/nginx/sites-enabled/"$SITE_NAME"

mkdir -p /var/www/"$SITE_NAME"
cp -a /drupal/"$DRUPAL_VERSION".x/. /var/www/"$SITE_NAME"/ 2>/dev/null || :

cat >/var/www/"$SITE_NAME"/.env << EOF
MYSQL_DATABASE=$MYSQL_DATABASE
MYSQL_USER=$MYSQL_USER
MYSQL_PASS=$MYSQL_PASS
MYSQL_HOST_NAME=$MYSQL_HOST_NAME
MYSQL_PORT=$MYSQL_PORT
EOF
exec "$@"