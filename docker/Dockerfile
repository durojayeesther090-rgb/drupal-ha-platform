FROM drupal:10-apache

# Drush: the command line tool used to install and manage the site
RUN composer require drush/drush --no-interaction --working-dir=/opt/drupal \
 && composer clear-cache

COPY docker/settings.php /opt/drupal/web/sites/default/settings.php
COPY docker/health.php /opt/drupal/web/health.php
COPY docker/entrypoint.sh /usr/local/bin/drupal-entrypoint.sh

RUN chmod +x /usr/local/bin/drupal-entrypoint.sh \
 && chmod 444 /opt/drupal/web/sites/default/settings.php \
 && mkdir -p /var/www/private /var/www/config/sync /opt/drupal/web/sites/default/files \
 && chown -R www-data:www-data /var/www/private /var/www/config /opt/drupal/web/sites/default/files

ENV PATH="/opt/drupal/vendor/bin:${PATH}"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD curl -fs http://localhost/health.php || exit 1

ENTRYPOINT ["drupal-entrypoint.sh"]
CMD ["apache2-foreground"]
