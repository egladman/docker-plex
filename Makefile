DOCKER := docker
SED := sed
GIT := git

DOCKER_BUILD_FLAGS :=

SPACE=$() $()
COMMA=,

TAG_WITH_LATEST := true
REPOSITORY := plex
DOCKERFILE := Dockerfile

BUILDX_X86_64_PLATFORM_NAME:= linux/amd64
BUILDX_AARCH64_PLATFORM_NAME := linux/arm64
BUILDX_ARMHF_PLATFORM_NAME := linux/arm/v7

BUILDX_INSTALLED := $(shell docker buildx version > /dev/null 2>&1 && printf true || printf false)
BUILDX_PLATFORMS := $(BUILDX_X86_64_PLATFORM_NAME) \
                    $(BUILDX_AARCH64_PLATFORM_NAME) \
                    $(BUILDX_ARMHF_PLATFORM_NAME)

GIT_HASH := $(shell $(GIT) rev-parse HEAD)

# By default build only the image that matches the host architecture
TARGET_ARCH := $(shell uname -m)
TARGET_ARCH_UPPERCASE := $(shell set -- $(TARGET_ARCH) && printf $${1^^}) # To uppercase
TARGET_PLATFORMS := $(BUILDX_$(strip $(TARGET_ARCH_UPPERCASE))_PLATFORM_NAME) # This is a hack

ifneq ($(TARGET_ARCH),x86_64)
	DOCKERFILE := $(DOCKERFILE).$(TARGET_ARCH)
endif

# The 'all' keyword will only work if a common dockerfile is used for
# multiple architectures
ifeq ($(TARGET_PLATFORMS),all)
    override TARGET_PLATFORMS := $(BUILDX_PLATFORMS)
else ifeq ($(words $(TARGET_PLATFORMS)),1)
    TAG_PREFIX := $(TARGET_ARCH)-
endif

$(info *************)
$(info     architecture: $(TARGET_ARCH))
$(info        platforms: $(TARGET_PLATFORMS))
$(info       git commit: $(GIT_HASH))
$(info       dockerfile: $(DOCKERFILE))
$(info buildx installed: $(BUILDX_INSTALLED))
$(info *************)

override TAGS += $(TAG_PREFIX)git-$(GIT_HASH)

# Tag image with 'latest' by default
ifeq ($(TAG_WITH_LATEST),true)
    override TAGS += $(TAG_PREFIX)latest

    # For backwards compatability
    ifeq ($(TARGET_ARCH),x86_64)
    ifeq ($(words $(TARGET_PLATFORMS)),1)
	  override TAGS += latest git-$(GIT_HASH)
    endif
    endif
endif

ifdef REPOSITORY_PREFIX
    override REPOSITORY := $(REPOSITORY_PREFIX)/$(REPOSITORY)
endif

ifdef TAGS
		TAG_OPTION := --tag $(REPOSITORY):
    override DOCKER_BUILD_FLAGS += $(TAG_OPTION)$(subst $(SPACE),$(SPACE)$(TAG_OPTION),$(strip $(TAGS)))
endif

ifeq ($(BUILDX_INSTALLED),true)
		override DOCKER := $(DOCKER) buildx
		override DOCKER_BUILD_FLAGS += --platform $(subst $(SPACE),$(COMMA),$(strip $(TARGET_PLATFORMS)))
endif

.PHONY: image image-push

image:
	$(DOCKER) build . --file $(DOCKERFILE) $(DOCKER_BUILD_FLAGS)

image-push:
ifeq ($(BUILDX_ENABLED),true)
	$(MAKE) image DOCKER_BUILD_FLAGS+="--push"
else
	$(DOCKER) push $(REPOSITORY) --all-tags
endif
