FROM linuxkit/alpine:9bcf61f605ef0ce36cc94d59b8eac307862de6e1 AS mirror

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --repository http://dl-3.alpinelinux.org/alpine/edge/main/ --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted --no-cache --initdb -p /out \
	alpine-baselayout \
	bash \
	btrfs-progs \
	busybox \
	ca-certificates \
	coreutils \
	curl \
	e2fsprogs \
	e2fsprogs-extra \
	file \
	findutils \
	git \
	jq \
	iptables \
	libseccomp \
	musl \
	ruby \
	ruby-json \
	shadow-uidmap \
	strace \
	sudo \
	util-linux \
	xfsprogs \
	xz


RUN apk --no-cache add ca-certificates curl && \
  curl -L -o /tmp/glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && \
  apk add --allow-untrusted -p /out /tmp/glibc.apk

RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
ENTRYPOINT []
WORKDIR /

COPY --from=mirror /out/ /

ENV BOSH_SHA256 8b4c003731e1287e414e88134658b35b59c2df48c89f360a707361a8e28067f9

RUN set -x \
	&& curl -fSL "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.29-linux-amd64" -o bosh \
	&& echo "${BOSH_SHA256} *bosh" | sha256sum -c - \
	&& mv bosh /usr/bin/bosh \
	&& chmod a+x /usr/bin/bosh

ENV GROOTFS_VERSION 0.24.0
ENV DRAX_SHA256 e2b75c72b64a7d1ecb2914f1ea09b6f2f99b62efba830c31b2384cd4c9e26452
ENV TARDIS_SHA256 414f4221cc43195852206942a949f07ba015c89323f4d9c27e8f2ca0d74ba85c
ENV GROOTFS_SHA256 24120892d69dedb7df0f96e273617217a47e5238b30df935b75a559266e68f04
ENV GDN_VERSION 1.9.2
ENV GDN_SHA256 a070b6ef634c7e10e30363d5f02979a77a05ff328311ce71a37cde6020b890d0

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

COPY rootfs /

COPY bosh-deployment /usr/local/bosh-deployment
COPY bosh-warden-cpi-release /usr/local/bosh-warden-cpi-release

