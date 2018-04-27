#!/bin/bash

# Copyright 2018 Giant Swarm.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

WORKDIR=$(pwd)
BUILDDIR=${WORKDIR}/build
CLUSTER=e2e-cluster-$(echo ${CIRCLE_SHA1} | cut -c 1-6)
SSH_USER="e2e"
KUBECTL_CMD="docker run -i --net=host --rm quay.io/giantswarm/docker-kubectl:f51f93c30d27927d2b33122994c0929b3e6f2432"
WORKER_COUNT=1

# Which files concerned by AWS.
AWS_FILES_REGEX="^modules/aws|^modules/container-linux|^platforms/aws|^ignition|^misc/e2e-aws.sh|^misc/e2e.sh|^\.circleci"

fail() {
  printf "\033[1;31merror: %s: %s\033[0m\n" ${FUNCNAME[1]} "${1:-"Unknown error"}"
  exit 1
}

msg() {
  printf "\033[1;32m%s: %s\033[0m\n" ${FUNCNAME[1]} "$1"
}

determine-changes() {
  # Output all changed file names between this PR and master branch.
  # For master branch check changed files in last commit.
  if [ ${CIRCLE_BRANCH} = "master" ]; then
    git diff-tree --no-commit-id --name-only -r HEAD | grep -q -E $1
  else
    git diff-tree --no-commit-id --name-only -r HEAD origin/master | grep -q -E $1
  fi
}

exec_on(){
    local base_domain=${CLUSTER}.${E2E_AWS_REGION}.aws.gigantic.io
    local host=$1
    shift 1

    ssh -q -t \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ProxyCommand="ssh -W %h:%p -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SSH_USER}@bastion1.${base_domain}" \
        ${SSH_USER}@${host}.${base_domain} "PATH=\$PATH:/opt/bin $*"
}

stage-preflight() {
  # TODO: move this to e2e-Dockerfile
  pip install ansible -q -q -q --upgrade

  PROGS=( git terraform terraform-provider-ct aws az ansible-playbook ssh-keygen )
  for prog in ${PROGS[@]}; do
    msg "Checking $prog"
    which $prog &>/dev/null || fail "$prog not installed"
  done

  msg "Checking necessary variables are set"
  [ ! -z "${E2E_AWS_ACCESS_KEY+x}" ] || fail "variable E2E_AWS_ACCESS_KEY is not set"
  [ ! -z "${E2E_AWS_ACCOUNT+x}" ] || fail "variable E2E_AWS_ACCOUNT is not set"
  [ ! -z "${E2E_AWS_SECRET_KEY+x}" ] || fail "variable E2E_AWS_SECRET_KEY is not set"
  [ ! -z "${E2E_AWS_REGION+x}" ] || fail "variable E2E_AWS_REGION is not set"
  [ ! -z "${E2E_AWS_ROUTE53_ZONE+x}" ] || fail "variable E2E_AWS_ROUTE53_ZONE is not set"
  [ ! -z "${E2E_GITHUB_TOKEN+x}" ] || fail "variable E2E_GITHUB_TOKEN is not set"
  [ ! -z "${CIRCLE_BRANCH+x}" ] || fail "variable CIRCLE_BRANCH is not set"
  [ ! -z "${CIRCLE_SHA1+x}" ] || fail "variable CIRCLE_SHA1 is not set"
}

stage-prepare-builddir() {
  msg "Configuring aws cli..."
  export AWS_ACCESS_KEY_ID=${E2E_AWS_ACCESS_KEY}
  export AWS_SECRET_ACCESS_KEY=${E2E_AWS_SECRET_KEY}

  msg "Creating and switching to build directory..."
  [ -d ${BUILDDIR} ] && rm -rf ${BUILDDIR}
  mkdir -p ${BUILDDIR}

  touch ${BUILDDIR}/backend.tf
  touch ${BUILDDIR}/provider.tf

  cat > ${BUILDDIR}/envs.sh << EOF
export AWS_DEFAULT_REGION=${E2E_AWS_REGION}
export TF_VAR_aws_account=${E2E_AWS_ACCOUNT}
export TF_VAR_aws_region=\${AWS_DEFAULT_REGION}
export TF_VAR_cluster_name=${CLUSTER}
export TF_VAR_base_domain=\${TF_VAR_cluster_name}.\${TF_VAR_aws_region}.aws.gigantic.io
export TF_VAR_root_dns_zone_id=${E2E_AWS_ROUTE53_ZONE}
export TF_VAR_nodes_vault_token=
export TF_VAR_aws_customer_gateway_id=
export TF_VAR_worker_count=${WORKER_COUNT}
EOF
}

stage-prepare-ssh(){
    ssh-keygen -t rsa -N "" -f ${BUILDDIR}/${SSH_USER}.key

    ssh_pub_key=$(cat ${BUILDDIR}/${SSH_USER}.key.pub)

    cat >> ${WORKDIR}/ignition/users.yaml << EOF
  - name: ${SSH_USER}
    groups:
      - "sudo"
      - "docker"
    ssh_authorized_keys:
      - $(cat ${BUILDDIR}/${SSH_USER}.key.pub)
EOF

    eval "$(ssh-agent)"
    ssh-add ${BUILDDIR}/${SSH_USER}.key
}

stage-terraform-only-vault() {
  cd ${BUILDDIR}

  source envs.sh
  terraform init ../platforms/aws/giantnetes
  terraform apply -auto-approve -target="module.dns" ../platforms/aws/giantnetes
  terraform apply -auto-approve -target="module.vpc" ../platforms/aws/giantnetes
  terraform apply -auto-approve -target="module.bastion" ../platforms/aws/giantnetes
  terraform apply -auto-approve -target="module.vault" ../platforms/aws/giantnetes

  cd -
}

stage-terraform() {
  cd ${BUILDDIR}

  source envs.sh
  terraform init ../platforms/aws/giantnetes
  terraform apply -auto-approve ../platforms/aws/giantnetes

  cd -
}

# TODO: Get rid of external dependencies and setup Vault in development mode.
stage-vault() {
    local base_domain=${CLUSTER}.${E2E_AWS_REGION}.aws.gigantic.io

    # Download Ansible playbooks for Vault bootstrap.
    local tmp=$(mktemp -d)
    cd $tmp
    git clone --depth 1 --quiet https://taylorbot:${E2E_GITHUB_TOKEN}@github.com/giantswarm/hive.git
    cd hive

    # Prepare configuration for Ansible.
    cat <<EOF > ./hosts_inventory/${CLUSTER}
[bootstrap_node]
vault1.${base_domain}

[bootstrap_node:vars]
ansible_python_interpreter="/root/bin/python"
ansible_ssh_user=${SSH_USER}
ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SSH_USER}@bastion1.${base_domain}"'
EOF

    cat <<EOF > ./envs/${CLUSTER}.yml
---
main_domain: "${base_domain}"
allowed_domains: "kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.local"
bare_metal: False
EOF

    # Bootstrap insecure Vault.
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible-playbook -i hosts_inventory/${CLUSTER} -e dc=${CLUSTER} bootstrap1.yml

    # Init Vault with one unencrypted unseal key.
    # NOTE: sed here is to filter ANSI escape codes and color codes.
    init_output=$(exec_on vault1 vault operator init -key-shares=1 -key-threshold=1 |\
        sed -r -e 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' -e 's/[\x01-\x1F\x7F]//g')

    local unseal_key=$(echo ${init_output} | awk '{ print $4 }')
    local root_token=$(echo ${init_output} | awk '{ print $8 }')

    msg "Vault unseal key: ${unseal_key}"
    msg "Vault root token: ${root_token}"

    exec_on vault1 vault operator unseal ${unseal_key}

    # Bootstrap secure Vault.
    export VAULT_TOKEN="${root_token}"
    export AWS_ACCESS_KEY="$E2E_AWS_ACCESS_KEY"
    export AWS_SECRET_KEY="$E2E_AWS_SECRET_KEY"
    ansible-playbook -i hosts_inventory/${CLUSTER} -e dc=${CLUSTER} bootstrap2.yml
    unset AWS_ACCESS_KEY AWS_SECRET_KEY

    exec_on vault1 vault operator unseal ${unseal_key}

    # Insert vault token in envs file.
    sed -i "s/export TF_VAR_nodes_vault_token=.*/export TF_VAR_nodes_vault_token=${VAULT_TOKEN}/" ${BUILDDIR}/envs.sh

    cd ${WORKDIR}
}

stage-destroy() {
  cd ${BUILDDIR}

  source envs.sh

  terraform init ../platforms/aws/giantnetes
  terraform destroy -force ../platforms/aws/giantnetes

  cd -
}

# stage-wait-kubernetes-nodes will check "kubectl get node" until all nodes
# will be in ready state and timeout after 3 minutes.
stage-wait-kubernetes-nodes(){
    local nodes_num_actual=$(exec_on master1 ${KUBECTL_CMD} get node | tail -n +2 | grep -v NotReady | wc -l)
    local nodes_num_expected=$((${WORKER_COUNT} + 1))

    local tries=0
    until [ ${nodes_num_expected} -eq ${nodes_num_actual} ]; do
        msg "Waiting all nodes to be ready."
        sleep 30; let tries+=1;
        [ ${tries} -gt 6 ] && fail "Timeout waiting all nodes to be ready."
        local nodes_num_actual=$(exec_on master1 ${KUBECTL_CMD} get node | tail -n +2 | grep -v NotReady | wc -l)
        msg "Expected nodes ${nodes_num_expected}, actual nodes ${nodes_num_actual}."
    done
    msg "Kubernetes nodes are ready."
}

stage-e2e(){
    local url="https://raw.githubusercontent.com/giantswarm/giantnetes-terraform/${CIRCLE_SHA1}/misc/e2e-conformance-pod.yaml"

    # Allow default service account to list nodes, required by e2e tests.
    exec_on master1 ${KUBECTL_CMD} create clusterrolebinding default-admin \
      --clusterrole=cluster-admin \
      --serviceaccount=default:default

    # Remove nginx-ingress-controller, because pods are staying in Pending state,
    # when only one worker. But e2e tests require all pods in kube-system to be Running.
    exec_on master1 ${KUBECTL_CMD} delete deploy nginx-ingress-controller -n kube-system

    exec_on master1 "curl -L ${url} 2>/dev/null | ${KUBECTL_CMD} apply -f -"
    msg "Started e2e tests..."

    # Give some time for pod to be created and connect to stdout.
    sleep 60

    exec_on master1 ${KUBECTL_CMD} logs e2e -f
    exec_on master1 ${KUBECTL_CMD} logs e2e --tail 1 | grep -q 'Test Suite Passed'
    exec_on master1 "curl -L ${url} 2>/dev/null | ${KUBECTL_CMD} delete -f -"
}

main() {
  stage-preflight

  if ! determine-changes $AWS_FILES_REGEX; then
      msg "No changes. Skipping e2e tests for AWS."
      exit
  fi

  stage-prepare-builddir
  stage-prepare-ssh
  trap "stage-destroy" EXIT
  stage-terraform-only-vault
  stage-vault
  stage-terraform

  # Wait for kubernetes nodes.
  stage-wait-kubernetes-nodes

  # Finally run tests.
  stage-e2e
}

main
