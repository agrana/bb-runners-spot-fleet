#!/bin/bash

dnf -y install python3
pip3 install awscli
pip3 install ansible

# Install ansible role that provides docker installation recipe
/usr/local/bin/ansible-galaxy install geerlingguy.docker

# Run the ansible role directly
/usr/local/bin/ansible -e docker_edition="ce" \
  -e docker_package="docker-cd-20.10.11" \
  -e ansible_os_family="RedHat" \
  -e ansible_distribution="centos" \
  -e ansible_distribution_major_version="8" \
  -m include_role \
  -a name=geerlingguy.docker localhost

# Get the docker command for the build runner from parameter store
builder_command=$(/usr/local/bin/aws ssm get-parameters --with-decryption \
  --names builder-${count} \
  --region=# Your region \
  --query Parameters[0].Value | tr -d \")

# Execute docker with the parameter comming from parameter store
$builder_command
