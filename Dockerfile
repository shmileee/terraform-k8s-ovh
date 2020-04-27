FROM alpine as build
ARG TERRAFORM_VERSION
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip /files/terraform.zip
WORKDIR /files
RUN mkdir /build
RUN for f in *.zip; do unzip $f -d /build; done

FROM alpine

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL maintainer="Aleksandr Ponomarov. <ponomarov.aleksandr@gmail.com>" \
      org.label-schema.url="https://github.com/shmileee/terraform-k8s-ovh" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.vcs-url="git@github.com:shmileee/terraform-k8s-ovh.git" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible with Terraform on alpine docker image" \
      org.label-schema.schema-version="1.0"

# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1

RUN apk --update add --virtual build-dependencies g++ python3-dev libffi-dev openssl-dev build-base && \
    apk add --no-cache -U git openssh python3 openssl ca-certificates && \
    if [ ! -e /usr/bin/python ]; then ln -sf /usr/bin/python3 /usr/bin/python ; fi && \
    python3 -m ensurepip && \
    if [ ! -e /usr/bin/pip ]; then ln -s /usr/bin/pip3 /usr/bin/pip ; fi && \
    pip install --no-cache --upgrade pip setuptools wheel cffi

# Install Terraform
COPY --from=build /build/* /usr/local/bin/

# Install Ansible
ARG ANSIBLE_VERSION
RUN echo "===> Installing Ansible..." && \
    pip install ansible==${ANSIBLE_VERSION}

# Tools
RUN echo "===> Installing handy tools (not absolutely required)..." && \
    apk --update add sshpass openssh-client rsync

# Cleanup
RUN echo "===> Removing package list..."  && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/*

COPY scripts/idle.sh /bin/idle
RUN chmod +x /bin/idle

WORKDIR /opt/kubespray

CMD ["/bin/idle"]
ENTRYPOINT ["/bin/idle"]
