TAG ?= clover/base
PLATFORM ?= linux/amd64,linux/386,linux/arm/v7,linux/arm64/v8,linux/ppc64le,linux/s390x

latest:
	docker buildx build --platform ${PLATFORM} --tag ${TAG}:$@ --push .

.PHONY: latest
