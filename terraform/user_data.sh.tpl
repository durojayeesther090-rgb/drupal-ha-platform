#!/bin/bash
# Bootstrap: install Ansible, then let Ansible configure the server.
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

export DEBIAN_FRONTEND=noninteractive
export HOME=/root
apt-get update -y
apt-get install -y ansible git awscli

ansible-pull \
  --url "${repo_url}" \
  --checkout "${repo_branch}" \
  --directory /opt/ansible-pull \
  --inventory localhost, \
  --connection local \
  --extra-vars "aws_region=${region} db_secret_arn=${secret_arn} efs_id=${efs_id} log_prefix=${log_prefix}" \
  ansible/site.yml
