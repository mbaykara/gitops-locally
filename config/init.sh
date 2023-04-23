#!/usr/bin/env bash

#This file is slightly modified version of https://github.com/fluxcd/gitsrv/blob/master/src/start.sh
set +x
set -o errexit
set -o pipefail
set -o nounset

# If there is some public key in keys folder
# then it copies its contain in authorized_keys file
if [ "$(ls -A /git-server/keys/)" ]; then
  cd /home/git
  cat /git-server/keys/*.pub > .ssh/authorized_keys
  chown -R git:git .ssh
  chmod 700 .ssh
  chmod -R 600 .ssh/*
fi

# Set permissions
if [ "$(ls -A /git-server/repos/)" ]; then
  cd /git-server/repos
  chown -R git:git /git-server/repos
  chmod -R ug+rwX /git-server/repos
  find . -type d -exec chmod g+s '{}' +
fi

# Set seeder user name
git config --global user.email "${GIT_USER_EMAIL:-root@gitsrv.git}"
git config --global user.name "${GIT_USER_NAME:-root}"

# Init repo and seed from a tar.gz link
REPO_DIR="/git-server/repos/${REPO}"

init_repo() {
  mkdir "${REPO_DIR}"
  cd "${REPO_DIR}"
  git init --shared=true

  if [ -n "${TAR_URL-}" ]; then
    while ! curl --verbose --location --fail "${TAR_URL}" | tar xz -C "./" --strip-components=1; do
      sleep 1
    done
    echo "Flux repo cloned!!!"
    git checkout -b main
    git add .
    git commit -m "init"
    git checkout -b tmp

  fi

  cd /git-server/repos
  chown -R git:git .
  chmod -R ug+rwX .
  find . -type d -exec chmod g+s '{}' +
}
init_repo
# Link to home dir, this need to be done each time as this dir has the lifetime of the pod
ln -s "${REPO_DIR}" /home/git/

# -D flag avoids executing sshd as a daemon
/usr/sbin/sshd -D