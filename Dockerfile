#This file is slightly modified version of https://github.com/fluxcd/gitsrv/blob/master/Dockerfile
FROM alpine:3.15

RUN apk add --no-cache openssh git curl bash gnupg unzip

RUN ssh-keygen -A

WORKDIR /git-server/

RUN mkdir /git-server/keys \
  && adduser -D -s /usr/bin/git-shell git \
  && mkdir /home/git/.ssh \
  && mkdir /home/git/git-shell-commands \
  && apk --update add tar zip unzip

ARG password
RUN sh -c "echo git:${password:-ratherchangeme} |chpasswd"

COPY config/sshd_config /etc/ssh/sshd_config
COPY config/init.sh init.sh

EXPOSE 22

CMD ["sh", "init.sh"]