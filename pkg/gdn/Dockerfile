FROM linuxkit/alpine:9bcf61f605ef0ce36cc94d59b8eac307862de6e1 as alpine
RUN \
  apk add \
  bash \
  btrfs-progs-dev \
  gcc \
  git \
  go \
  libc-dev \
  libseccomp-dev \
  linux-headers \
  make \
  tzdata \
  tar \
  && true

RUN mkdir -p /tmp/gdn/ && \
  cd /tmp/gdn/ && \
  git clone https://github.com/cloudfoundry/bosh-deployment.git

FROM linuxkit/alpine:9bcf61f605ef0ce36cc94d59b8eac307862de6e1 AS mirror

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --repository http://dl-3.alpinelinux.org/alpine/edge/main/ --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted --no-cache --initdb -p /out \
	alpine-baselayout \
	bash \
	btrfs-progs \
	busybox \
	ca-certificates \
	coreutils \
	curl \
	e2fsprogs \
	e2fsprogs-extra \
	findutils \
	iptables \
	libseccomp \
	musl \
	ruby \
	ruby-json \
	shadow-uidmap \
	sudo \
	util-linux \
	xz

RUN apk --no-cache add ca-certificates curl && \
  curl -L -o /tmp/glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && \
  apk add --allow-untrusted -p /out /tmp/glibc.apk

RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
ENTRYPOINT []
WORKDIR /

COPY --from=mirror /out/ /

ENV BOSH_SHA256 81673e467a90a22a1365a5981c137b48eee10db8ed2af6adb67191ce35d12c73

RUN set -x \
	&& curl -fSL "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.26-linux-amd64" -o bosh \
	&& echo "${BOSH_SHA256} *bosh" | sha256sum -c - \
	&& mv bosh /usr/bin/bosh \
	&& chmod a+x /usr/bin/bosh

COPY --from=alpine /usr/share/zoneinfo/UTC /etc/localtime
COPY --from=alpine /tmp/gdn/bosh-deployment /usr/local/bosh-deployment

ENV GROOTFS_VERSION 0.21.0
ENV DRAX_SHA256 6f935e69bdab2b903aaa7b6acda5e815ee6f56ca94ed0becbf02a79d6d29c333
ENV TARDIS_SHA256 897499eb0d38e16d24d7b076ab3ce5562dbcec501376995a15cc9ab0876e39f3
ENV GROOTFS_SHA256 2e0fa1d3942d11ed79620141ec52e8861eaf92033339e60f4efdc2b3df7f0375
ENV GDN_VERSION 1.9.0
ENV GDN_SHA256 a19e5db692f0223b29639f2a609c67461d3a5795adc91df8985e42ebd55349a7

RUN set -x \
	&& curl -fSL "https://github.com/cloudfoundry/grootfs/releases/download/v${GROOTFS_VERSION}/drax-${GROOTFS_VERSION}" -o drax \
	&& echo "${DRAX_SHA256} *drax" | sha256sum -c - \
	&& mv drax /usr/bin/drax \
	&& chmod a+x /usr/bin/drax \
	&& curl -fSL "https://github.com/cloudfoundry/grootfs/releases/download/v${GROOTFS_VERSION}/tardis-${GROOTFS_VERSION}" -o tardis \
	&& echo "${TARDIS_SHA256} *tardis" | sha256sum -c - \
	&& mv tardis /usr/bin/tardis \
	&& chmod a+x /usr/bin/tardis \
	&& curl -fSL "https://github.com/cloudfoundry/grootfs/releases/download/v${GROOTFS_VERSION}/grootfs-${GROOTFS_VERSION}" -o grootfs \
	&& echo "${GROOTFS_SHA256} *grootfs" | sha256sum -c - \
	&& mv grootfs /usr/bin/grootfs \
	&& chmod a+x /usr/bin/grootfs \
	&& curl -fSL "https://github.com/cloudfoundry/garden-runc-release/releases/download/v${GDN_VERSION}/gdn-${GDN_VERSION}" -o gdn \
	&& echo "${GDN_SHA256} *gdn" | sha256sum -c - \
	&& mv gdn /usr/bin/gdn \
	&& chmod a+x /usr/bin/gdn

COPY start-garden.sh /usr/bin/start-garden
COPY start-bosh.sh /usr/bin/start-bosh
COPY grootfs.yml /etc/grootfs.yml
COPY grootfs-unprivileged.yml /etc/grootfs-unprivileged.yml
COPY local-cpi-release.yml /usr/local/local-cpi-release.yml

# COPY linuxbin/bosh /usr/local/bin/bosh
# RUN set -x \
# 	&& chmod a+x /usr/local/bin/bosh
