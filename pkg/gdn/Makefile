.PHONY: tag push
default: push

ORG?=luan
IMAGE=gdn
DEPS=Dockerfile

ifeq ($(HASH),)
HASH_COMMIT?=HEAD # Setting this is only really useful with the show-tag target
HASH?=$(shell git ls-tree --full-tree $(HASH_COMMIT) -- $(CURDIR) | awk '{print $$3}')

ifneq ($(HASH_COMMIT),HEAD) # Others can't be dirty by definition
DIRTY:=$(shell git update-index -q --refresh && git diff-index --quiet HEAD -- $(CURDIR) || echo "-dirty")
endif
endif

TAG:=$(ORG)/$(IMAGE):$(HASH)$(DIRTY)


tag: $(DEPS)
	docker build -t $(TAG) .

push: tag
	DOCKER_CONTENT_TRUST=1 docker pull $(ORG)/$(IMAGE) || \
	DOCKER_CONTENT_TRUST=1 docker push $(ORG)/$(IMAGE)
