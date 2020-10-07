FROM ashenm/workspace

# avoid prompts
ARG DEBIAN_FRONTEND=noninteractive

# expose tcp ports
EXPOSE 3000/tcp

# install latest node
RUN sudo mkdir --parent /opt/node && \
  curl --silent --fail --show-error --location 'https://nodejs.org/dist/latest/' | \
  egrep --only-matching --max-count 1 'node-v[0-9]+\.[0-9]+\.[0-9]+-linux-x64.tar.xz' | \
  wget --quiet --base='https://nodejs.org/dist/latest/' --input-file - --output-document - | \
  sudo tar --xz --extract --strip-components 1 --file - --directory /opt/node
ENV PATH /opt/node/bin:$PATH

# install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
  sudo apt-get update && sudo -E apt-get install --yes --no-install-recommends python-dev yarn

# setup wetty
RUN sudo mkdir -p /opt/wetty && \
  curl --silent --location --show-error https://github.com/krishnasrinivas/wetty/archive/main.zip | \
    sudo bsdtar --extract --keep-old-files --file - --strip-components 1 --directory /opt/wetty && \
  sudo -H yarn --cwd /opt/wetty install && sudo -H yarn --cwd /opt/wetty build && \
  sudo -H yarn --ignore-scripts --prefer-offline --production true --cwd /opt/wetty install

# add auxiliary user
RUN sudo groupadd --gid 1001 ashenm && \
  sudo useradd --create-home --uid 1001 --gid ashenm --groups sudo ashenm --shell /bin/bash

# configure wetty
COPY --chown=root:root wetty /opt/wetty/

# spawn wetty
CMD ["sudo", "-H", "/opt/wetty/start"]
