#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source /opt/dayam/config.conf

HOST=www
FQDN=$HOST.$LINODE_DOMAIN
EMAIL=admin@$LINODE_DOMAIN

LINODE_API_TOKEN="$LINODE_API_TOKEN" linode-dns \
  --domain "$LINODE_DOMAIN" \
  --name www \
  --ipv4 "$LINODE_IPV4" \
  --ipv6 "$LINODE_IPV6"

LINODE_API_TOKEN="$LINODE_API_TOKEN" linode-dns \
  --domain "$LINODE_DOMAIN" \
  --name '' \
  --ipv4 "$LINODE_IPV4" \
  --ipv6 "$LINODE_IPV6"

apt-get install -yqq certbot nginx

[ -f "/etc/letsencrypt/live/$FQDN/fullchain.pem" ] ||
  certbot certonly --nginx --email "$EMAIL" --agree-tos --no-eff-email \
    --force-renewal --domain "$FQDN" --domain "$LINODE_DOMAIN"

cat <<EOF >/etc/nginx/sites-available/www
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  listen 443 ssl;
  listen [::]:443 ssl;
  server_name $FQDN $LINODE_DOMAIN;

  include /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;

  if (\$scheme != "https") {
    return 301 https://\$host\$request_uri;
  }

  root /opt/dayam/website;
  index index.html;

  location / {
    try_files \$uri \$uri/ =404;
  }
}
EOF

rm -f /etc/nginx/sites-enabled/default
ln -sft /etc/nginx/sites-enabled/ ../sites-available/www
systemctl restart nginx
