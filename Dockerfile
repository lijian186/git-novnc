FROM yuzhenpin/docker-novnc-xterm
RUN apk update && apk add --no-cache git nodejs openssh
ADD . /service
ADD ./start.sh /
ADD .git-credentials /root/
WORKDIR /service
RUN git config --global credential.helper store &&\
    git config --global http.sslVerify false &&\
    git config --global url.http://gitlab-xhproject.xlab.si/.insteadOf ssh://git@gitlab-xhproject.xlab.si:16022/ &&\
    git config --global push.default simple &&\
    git config --global color.diff false
RUN npm install
RUN git config --global --unset url.http://gitlab-xhproject.xlab.si/.insteadOf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV SERVICE_NAME=mt-webcommit
ENV SERVICE_TAGS=microtool,mt,webcommit,nodejs
RUN chmod +x /start.sh
#CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
ENTRYPOINT ["/start.sh"]
WORKDIR /workspace
