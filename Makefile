.PHONY: default all
default: pkg
all: default

.PHONY: pkg
pkg:
	$(MAKE) -C pkg tag

