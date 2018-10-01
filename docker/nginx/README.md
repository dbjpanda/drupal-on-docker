conf.d (directory)
-------
This directory contains all the site spiecific configuration of nginx 

nginx.conf (file)
-------
This file defines the global configuration of nginx

drupal
--------
This directory contains two sub trees called 8.x for Drupal 8 and 7.x for Drupal 7. These sub trees have different composer.json templates for different version of Drupal and are added to our project as git subtree of https://github.com/drupal-composer/drupal-project .
To update those subtree to their latest commit execute below commands
```
git remote add -f drupal-project https://github.com/drupal-composer/drupal-project.git
git subtree pull --prefix=docker/nginx/drupal/8.x drupal-project 8.x --squash
git subtree pull --prefix=docker/nginx/drupal/7.x drupal-project 7.x  --squash
```
