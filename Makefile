SHELL := /bin/bash

PWD := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

VCS_REF := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

TERRAFORM_VERSION ?= "0.12.24"
ANSIBLE_VERSION ?= "2.9.5"

IMAGE_NAME ?= "terraform-ansible"
IMAGE_TAG ?= "alpha"
CONTAINER_NAME ?= $(IMAGE_NAME)

DOCKER_PUBLISH_NAME ?= "shmileee/terraform-ansible"
DOCKER_PUBLISH_TAG ?= $(IMAGE_TAG)

.PHONY: build-image
build-image:
	docker build -f Dockerfile -t $(IMAGE_NAME):$(IMAGE_TAG) \
	--build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
	--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) .

.PHONY: stop-container
stop-container:
	-@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true

.PHONY: clean
clean: stop-container
	-@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true

.PHONY: publish
publish:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_PUBLISH_NAME):$(DOCKER_PUBLISH_TAG)
	docker push $(DOCKER_PUBLISH_NAME):$(DOCKER_PUBLISH_TAG)

.PHONY: terraform
terraform: stop-container
	docker run -t \
	-v $(PWD)/kubespray:/opt/kubespray \
	-v $(PWD)/scripts:/opt/kubespray/scripts \
	-v $$HOME/.ssh:/root/.ssh \
	--entrypoint /bin/sh \
	--name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_TAG) \
	/opt/kubespray/scripts/prepare_env.sh
