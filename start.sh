#!/bin/sh
(nohup node /service/server.js &)
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
