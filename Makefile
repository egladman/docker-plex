DOCKER := docker
SED := sed
GIT := git

DOCKER_BUILD_FLAGS :=

SPACE=$() $()
COMMA=,

TAG_WITH_LATEST := true
REPOSITORY := plex

GIT_HASH := $(shell $(GIT) rev-parse HEAD)
TARGET_ARCH ?= $(shell uname -m)

ifneq ($(TARGET_ARCH),x86_64)
    DOCKERFILE_SUFFIX := .$(TARGET_ARCH)
endif

override TAGS += git-$(GIT_HASH)

# Tag image with 'latest' by default
ifeq ($(TAG_WITH_LATEST),true)
    override TAGS += latest
endif

# Auto enable buildx when available
BUILDX_ENABLED := $(shell docker buildx version > /dev/null 2>&1 && printf true || printf false)
BUILDX_PLATFORMS := linux/amd64 linux/arm64 linux/arm/v7

ifdef REPOSITORY_PREFIX
    override REPOSITORY := $(REPOSITORY_PREFIX)/$(REPOSITORY)
endif

ifdef TAGS
		TAG_PREFIX := --tag $(REPOSITORY):
    override DOCKER_BUILD_FLAGS += $(TAG_PREFIX)$(subst $(SPACE),$(SPACE)$(TAG_PREFIX),$(strip $(TAGS)))
endif

ifeq ($(BUILDX_ENABLED),true)
		override DOCKER := $(DOCKER) buildx
		override DOCKER_BUILD_FLAGS += --platform $(subst $(SPACE),$(COMMA),$(BUILDX_PLATFORMS))
endif

$(info Docker buildx enabled: $(BUILDX_ENABLED))

.PHONY: image image-push

image:
	$(DOCKER) build . --file Dockerfile$(DOCKERFILE_SUFFIX) $(DOCKER_BUILD_FLAGS)

image-push:
ifeq ($(BUILDX_ENABLED),true)
	$(MAKE) image DOCKER_BUILD_FLAGS+="--push"
else
	$(DOCKER) push $(REPOSITORY) --all-tags
endif
