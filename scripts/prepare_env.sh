#!/usr/bin/env sh
set -x
export PROVIDER=openstack

# Set Ansible config
cp -f ansible.cfg ~/.ansible.cfg

# Prepare inventory
cp -f contrib/terraform/$PROVIDER/sample-inventory/cluster.tfvars .
ln -sfn contrib/terraform/$PROVIDER/hosts

terraform init contrib/terraform/$PROVIDER

mkdir -p ~/.ssh
chmod 400 ~/.ssh/id_rsa

terraform validate -var-file=cluster.tfvars contrib/terraform/$PROVIDER

export ANSIBLE_INVENTORY=hosts