# FROM ubuntu:14.04

# RUN apt-get update && apt-get install -y \
# 		build-essential \
# 		curl \
# 		wget \
# 		tar \
# 		libssl-dev \
# 		libreadline-dev \
#     autoconf \
#     pkg-config \
#     quota \
#     sudo \
#     uidmap \
#     ulogd \
#   && \
#   apt-get clean && \
# 	rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/groff/* /usr/share/info/*


# # install libseccomp (needed for garden-runc)
# RUN \
#   wget https://github.com/seccomp/libseccomp/releases/download/v2.3.1/libseccomp-2.3.1.tar.gz && \
#   tar zxf libseccomp-2.3.1.tar.gz && \
#   cd libseccomp-2.3.1/  && \
#   ./configure && \
#   make && \
#   make install

# ENV GDN_VERSION 1.9.0
# ENV GDN_SHA256 a19e5db692f0223b29639f2a609c67461d3a5795adc91df8985e42ebd55349a7

# RUN set -x \
# 	&& curl -fSL "https://github.com/cloudfoundry/garden-runc-release/releases/download/v${GDN_VERSION}/gdn-${GDN_VERSION}" -o gdn \
# 	&& echo "${GDN_SHA256} *gdn" | sha256sum -c - \
# 	&& mv gdn /usr/bin/gdn \
# 	&& chmod a+x /usr/bin/gdn

# COPY start-garden.sh /usr/local/bin/start-garden
# RUN chmod +x /usr/local/bin/start-garden

# COPY start-bosh.sh /usr/local/bin/start-bosh
# RUN chmod +x /usr/local/bin/start-bosh

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
  git clone https://github.com/cloudfoundry/garden-runc-release.git
COPY build-gdn.sh /tmp/gdn/build-gdn.sh

RUN mkdir -p /tmp/gdn/ && \
  cd /tmp/gdn/ && \
  git clone https://github.com/cloudfoundry/bosh-deployment.git

WORKDIR /tmp/gdn
RUN ./build-gdn.sh

FROM linuxkit/alpine:9bcf61f605ef0ce36cc94d59b8eac307862de6e1 AS mirror

# https://github.com/docker/docker/blob/master/project/PACKAGERS.md#runtime-dependencies
# removed openssl as I do not think server needs it
RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --repository http://dl-3.alpinelinux.org/alpine/edge/main/ --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted --no-cache --initdb -p /out \
	alpine-baselayout \
	bash \
	btrfs-progs \
	busybox \
	ca-certificates \
	curl \
	e2fsprogs \
	e2fsprogs-extra \
	iptables \
	musl \
	findutils \
	shadow-uidmap \
	xfsprogs \
	xz
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

COPY --from=alpine /usr/bin/tar /usr/bin/init /usr/bin/runc /usr/bin/nstar /usr/bin/dadoo /usr/bin/gdn /usr/bin/
COPY --from=alpine /usr/bin/grootfs /usr/bin/tardis /usr/bin/drax /usr/bin/
COPY --from=alpine /usr/share/zoneinfo/UTC /etc/localtime
COPY --from=alpine /tmp/gdn/bosh-deployment /usr/local/bosh-deployment
COPY start-garden.sh /usr/bin/start-garden
COPY start-bosh.sh /usr/bin/start-bosh
COPY grootfs.yml /etc/grootfs.yml

