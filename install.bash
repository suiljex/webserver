#!/usr/bin/env bash

[ "$EUID" -ne 0 ] && echo "Please run as root" && exit 1

SCRIPT_NAME=$0
SCRIPT_FULL_PATH=$(dirname "$0")

PACKAGES_APT="nginx python3 python3-pip openssl"
PACKAGES_PIP="certbot"

CMD_INSTALL_APT="apt-get update && apt-get install -y "
CMD_INSTALL_PIP="pip3 install --upgrade --upgrade-strategy=only-if-needed "
CMD_MKDIR="mkdir -p "
CMD_CP="cp "
CMD_RM="rm -rf  "

if [ -f "/etc/debian_version" ]
then
  eval ${CMD_INSTALL_APT} ${PACKAGES_APT}
  eval ${CMD_INSTALL_PIP} ${PACKAGES_PIP}
else
  echo "It looks like you are using a non-Debian based distribution."
  echo "Install \"nginx\" and \"certbot\" mannualy"
fi

eval ${CMD_RM} "/etc/nginx/sites-enabled/default"

eval ${CMD_MKDIR} "/var/www/letsencrypt"
eval ${CMD_MKDIR} "/etc/letsencrypt"
eval ${CMD_MKDIR} "/etc/letsencrypt/renewal-hooks/custom"
eval ${CMD_MKDIR} "/etc/nginx/conf.d"

eval ${CMD_CP} "${SCRIPT_FULL_PATH}/certctl"            "/usr/bin/certctl"
eval ${CMD_CP} "${SCRIPT_FULL_PATH}/nginx_conf.d/*"     "/etc/nginx/conf.d/"
eval ${CMD_CP} "${SCRIPT_FULL_PATH}/renewal-hooks/*"    "/etc/letsencrypt/renewal-hooks/custom/"

if [ "$(ps --no-headers -o comm 1)" == "systemd" ]
then
  eval ${CMD_CP} "${SCRIPT_FULL_PATH}/systemd-services/*" "/etc/systemd/system/"
  /usr/bin/systemctl daemon-reload
  /usr/bin/systemctl enable certbot-renewal.timer

  /usr/bin/systemctl start nginx.service
  /usr/bin/systemctl enable nginx.service
  /usr/bin/systemctl reload nginx.service
else
  echo "It looks like you are using a distro without systemd "
  echo "Install certificate auto-renewal manually "
fi

chown root "/usr/bin/certctl"
chgrp root "/usr/bin/certctl"
chmod 755  "/usr/bin/certctl"
