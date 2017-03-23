#!/bin/sh
if ! ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
    ssh-keygen -A
fi
/usr/sbin/sshd
(nohup node /service/server.js &)
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
