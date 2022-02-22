# Taken from https://github.com/Homegear/Homegear-Docker/blob/master/rpi-stable/Dockerfile
#FROM homegear/homegear:nightly
FROM homegear/homegear@sha256:9a8c6f57d1413541f354dcebb58a065ed58e01c7700c46bfc39ead11ad39cb21
MAINTAINER Jan Koval

COPY ["image-data/", "/"]

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2
ENV S6_VERSION v2.2.0.3
ENV S6_CHECKSUM e49a47715f5f187928c98e6eaba41a39
ENV NVM_VERSION v0.39.0
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 16.13.1

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz /tmp
ADD https://raw.githubusercontent.com/creationix/nvm/${NVM_VERSION}/install.sh /tmp
RUN apt update \
    && apt install -y --no-install-recommends -- \
    python2.7 \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    libssl-dev \
    wget \
    && apt-get clean \
    && find /var/lib/apt/lists -mindepth 1 -delete \
    && test $(md5sum /tmp/s6-overlay-amd64.tar.gz | cut -f1 -d' ') = $S6_CHECKSUM \
    && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
    && rm -- /tmp/s6-overlay-amd64.tar.gz \
    && mv /usr/bin/with-contenv /usr/bin/with-contenvb \
    && mv /usr/bin/with-contenv-umask /usr/bin/with-contenv \
    && mkdir -p $NVM_DIR \
    && bash /tmp/install.sh \
    && rm -- /tmp/install.sh \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

RUN cd /var/lib/homegear.data/node-blue/node-red \
    && . "$NVM_DIR/nvm.sh" \
    && nvm alias default "${NODE_VERSION}" \
    && npm install --python=/usr/bin/python2.7

ENTRYPOINT ["/init"]

EXPOSE 2001 2002 2003
