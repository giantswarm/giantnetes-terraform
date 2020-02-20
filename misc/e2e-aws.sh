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
TFDIR=${WORKDIR}/platforms/aws/giantnetes
CLUSTER=e2e-terraform-$(echo ${CIRCLE_SHA1} | cut -c 1-4)-${MASTER_COUNT}
SSH_USER="e2e"
KUBECTL_CMD="sudo /opt/bin/hyperkube kubectl --kubeconfig=/etc/kubernetes/kubeconfig/addons.yaml"

WORKER_COUNT=1

export TF_VAR_master_count=${MASTER_COUNT}

# Please set any non empty value to E2E_ENABLE_CONFORMANCE in CircleCI
# to enable full run of e2e conformance tests.
E2E_ENABLE_CONFORMANCE=${E2E_ENABLE_CONFORMANCE:-""}

# Which files concerned by AWS.
AWS_FILES_REGEX="^modules/aws|^modules/container-linux|^platforms/aws|^templates|^misc/e2e-aws.sh|^misc/e2e.sh|^\.circleci"

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

source_bootstrap() {
  # Do not fail on pipefails/errors in bootstrap
  set +o errexit
  set +o nounset
  set +o pipefail
  source bootstrap.sh
  set -o errexit
  set -o nounset
  set -o pipefail
}

stage-preflight() {
  PROGS=( git terraform terraform-provider-gotemplate aws az ansible-playbook ssh-keygen )
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
  [ ! -z "${E2E_ENABLE_CONFORMANCE+x}" ] || fail "variable E2E_ENABLE_CONFORMANCE is not set"
  [ ! -z "${CIRCLE_BRANCH+x}" ] || fail "variable CIRCLE_BRANCH is not set"
  [ ! -z "${CIRCLE_SHA1+x}" ] || fail "variable CIRCLE_SHA1 is not set"
}

stage-prepare() {
  msg "Configuring aws cli..."
  export AWS_ACCESS_KEY_ID=${E2E_AWS_ACCESS_KEY}
  export AWS_SECRET_ACCESS_KEY=${E2E_AWS_SECRET_KEY}

  mkdir -p ${TFDIR}

  cat > ${TFDIR}/bootstrap.sh << EOF
export AWS_DEFAULT_REGION=${E2E_AWS_REGION}
export TF_VAR_aws_account=${E2E_AWS_ACCOUNT}
export TF_VAR_aws_region=\${AWS_DEFAULT_REGION}
export TF_VAR_cluster_name=${CLUSTER}
export TF_VAR_base_domain=\${TF_VAR_cluster_name}.\${TF_VAR_aws_region}.aws.gigantic.io
export TF_VAR_root_dns_zone_id=${E2E_AWS_ROUTE53_ZONE}
export TF_VAR_nodes_vault_token=
export TF_VAR_aws_customer_gateway_id=
export TF_VAR_worker_count=${WORKER_COUNT}
# export logs in CI
export TF_VAR_logentries_enabled=${LOGENTRIES_ENABLED}
export TF_VAR_logentries_prefix="aws-${CLUSTER}"
export TF_VAR_logentries_token=${LOGENTRIES_TOKEN}

terraform init ./
EOF

 # This removes the configuration of the backend to init Terraform
 # with the local backend
 sed -i '/backend "s3" {}/d' ${WORKDIR}/platforms/aws/giantnetes/main.tf
}

stage-prepare-ssh(){
    ssh-keygen -t rsa -N "" -f ${TFDIR}/${SSH_USER}.key

    echo "Private key (you can use it to SSH to bastion host:"
    echo "================================================"
    cat ${TFDIR}/${SSH_USER}.key
    echo "================================================"

    ssh_pub_key=$(cat ${TFDIR}/${SSH_USER}.key.pub)

    cat > ${WORKDIR}/ignition/bastion-users.yaml << EOF
passwd:
  users:
  - name: ${SSH_USER}
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - $(cat ${TFDIR}/${SSH_USER}.key.pub)
  - name: vol
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFGDg/p4JWewXAs8kExJnCaNXEN1v2LZf0YWWiblHFp1+i2bp8qSmAJT3i6Yw0kHY2/6MotBCKAsFtlqxuhKaFs3jDcmdOugmWz4Qj7oerQ/ypJE/wZ9PY79gbK75aEKyOdVf7dUT6Ah+oSfETgpY/3a9pVZ/dSF3WBFIBw5k4YarFzcELQE4Bo4dcsLHsNrkI9Bk6gkGbTY+1TtfJmOu0bEXxXHdEq+JfW0MFssjh3I5n0DT09qDnztAvRAjjqjlyNKNt8reErV0LlvsDM5c+426Bz9JgM5vP3sD5ai8lpuH0iCBHoo9678XTKKTYbbz0s7kgXUb0vGS+GbOcaKBKmZ8a0xDpsft9+/LbmnuUic8b4c4/cRw5wSV1IYqyDqARp/d9PaJlYa22ISGnDbYmXUTsef0PhUenK9gtYrGsVhQmkqeLYiIYqwsl7+uouFMpQDmdZjY/B4fKcRA3oRGCFuwzT1vrtJL41dw9WyzM+3xnHTMFZdko9TlgDiEeu6gdpsTGJf4VALUWgXeyW/egte2im86kjMxzQuCw/aOmiYMqwZH2YfI0dS9jLuZbxePKTUounct66SrNXBrbu2d0BiPj6bl1dG6oZhwtArRnbiG5+cTakDvLhFgahTQFAT1De7o3Nr+BfjNQkVlQNKaIPUOdypiDNJE/6q/GOHVRQw==
  - name: calvix
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9IyAZvlEL7lrxDghpqWjs/z/q4E0OtEbmKW9oD0zhYfyHIaX33YYoj3iC7oEd6OEvY4+L4awjRZ2FrXerN/tTg9t1zrW7f7Tah/SnS9XYY9zyo4uzuq1Pa6spOkjpcjtXbQwdQSATD0eeLraBWWVBDIg1COAMsAhveP04UaXAKGSQst6df007dIS5pmcATASNNBc9zzBmJgFwPDLwVviYqoqcYTASka4fSQhQ+fSj9zO1pgrCvvsmA/QeHz2Cn5uFzjh8ftqkM10sjiYibknsBuvVKZ2KpeTY6XoTOT0d9YWoJpfqAEE00+RmYLqDTQGWm5pRuZSc9vbnnH2MiEKf calvix@masteR
EOF
    cat > ${WORKDIR}/ignition/users.yaml << EOF
passwd:
  users:
  - name: ${SSH_USER}
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - $(cat ${TFDIR}/${SSH_USER}.key.pub)
  - name: vol
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFGDg/p4JWewXAs8kExJnCaNXEN1v2LZf0YWWiblHFp1+i2bp8qSmAJT3i6Yw0kHY2/6MotBCKAsFtlqxuhKaFs3jDcmdOugmWz4Qj7oerQ/ypJE/wZ9PY79gbK75aEKyOdVf7dUT6Ah+oSfETgpY/3a9pVZ/dSF3WBFIBw5k4YarFzcELQE4Bo4dcsLHsNrkI9Bk6gkGbTY+1TtfJmOu0bEXxXHdEq+JfW0MFssjh3I5n0DT09qDnztAvRAjjqjlyNKNt8reErV0LlvsDM5c+426Bz9JgM5vP3sD5ai8lpuH0iCBHoo9678XTKKTYbbz0s7kgXUb0vGS+GbOcaKBKmZ8a0xDpsft9+/LbmnuUic8b4c4/cRw5wSV1IYqyDqARp/d9PaJlYa22ISGnDbYmXUTsef0PhUenK9gtYrGsVhQmkqeLYiIYqwsl7+uouFMpQDmdZjY/B4fKcRA3oRGCFuwzT1vrtJL41dw9WyzM+3xnHTMFZdko9TlgDiEeu6gdpsTGJf4VALUWgXeyW/egte2im86kjMxzQuCw/aOmiYMqwZH2YfI0dS9jLuZbxePKTUounct66SrNXBrbu2d0BiPj6bl1dG6oZhwtArRnbiG5+cTakDvLhFgahTQFAT1De7o3Nr+BfjNQkVlQNKaIPUOdypiDNJE/6q/GOHVRQw==
  - name: calvix
    groups:
      - "sudo"
      - "docker"
    sshAuthorizedKeys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9IyAZvlEL7lrxDghpqWjs/z/q4E0OtEbmKW9oD0zhYfyHIaX33YYoj3iC7oEd6OEvY4+L4awjRZ2FrXerN/tTg9t1zrW7f7Tah/SnS9XYY9zyo4uzuq1Pa6spOkjpcjtXbQwdQSATD0eeLraBWWVBDIg1COAMsAhveP04UaXAKGSQst6df007dIS5pmcATASNNBc9zzBmJgFwPDLwVviYqoqcYTASka4fSQhQ+fSj9zO1pgrCvvsmA/QeHz2Cn5uFzjh8ftqkM10sjiYibknsBuvVKZ2KpeTY6XoTOT0d9YWoJpfqAEE00+RmYLqDTQGWm5pRuZSc9vbnnH2MiEKf calvix@masteR
EOF

    eval "$(ssh-agent)"
    ssh-add ${TFDIR}/${SSH_USER}.key
}

stage-terraform-only-vault() {
  cd ${TFDIR}

  source_bootstrap
  terraform apply -auto-approve -target="module.dns" ./
  terraform apply -auto-approve -target="module.vpc" ./
  terraform apply -auto-approve -target="module.s3" ./
  terraform apply -auto-approve -target="module.bastion" ./
  terraform apply -auto-approve -target="module.vault" ./

  cd -
}

stage-terraform() {
  cd ${TFDIR}

  source_bootstrap
  terraform apply -auto-approve ./

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
    export CI_RUN=true
    export ANSIBLE_HOST_KEY_CHECKING=False
    # Setup requirered env variables
    export ETCD_BACKUP_AWS_ACCESS_KEY="test"
    export ETCD_BACKUP_AWS_SECRET_KEY="test"
    export OPSCTL_GITHUB_TOKEN="test"
    export VAULT_UNSEAL_TOKEN=token

    # Use default unseal method
    sed -i '/^seal/,$ d' config/vault/vault_unsecure.hcl
    sed -i '/^seal/,$ d' config/vault/vault.hcl

    ansible-playbook -i hosts_inventory/${CLUSTER} -e dc=${CLUSTER} bootstrap.yml

    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${SSH_USER}@bastion1.${base_domain}" ${SSH_USER}@vault1.${base_domain}:/tmp/vault/vault_initialized.json .
    VAULT_TOKEN=$(cat vault_initialized.json | jq .root_token )

    # Insert vault token in envs file.
    sed -i "s/export TF_VAR_nodes_vault_token=.*/export TF_VAR_nodes_vault_token=${VAULT_TOKEN}/" ${TFDIR}/bootstrap.sh

    cd ${WORKDIR}
}

stage-debug() {
  # Output logs for failed units
  exec_on master1 "sudo systemctl list-units --failed | \
          cut -d ' ' -f2 | \
          tail -n+2 | \
          head -n -7 | \
          xargs -i sh -c 'echo logs for {} ; sudo journalctl --no-pager -u {}; echo'"
}

stage-destroy() {
  stage-debug || true

  cd ${TFDIR}
  source_bootstrap
  # accept that the destroy phase can fail
  # the pipeline will be considered passed (if the other steps were successful)
  # and the CI cleaner will get rid of leftovers
  terraform destroy -force ./ || true

  cd -
}

# stage-wait-kubernetes-nodes will check "kubectl get node" until all nodes
# will be in ready state and timeout after 3 minutes.
stage-wait-kubernetes-nodes(){
    local nodes_num_actual=$(exec_on master1 ${KUBECTL_CMD} get node | tail -n +2 | grep -v NotReady | wc -l)
    local nodes_num_expected=$((${WORKER_COUNT} + ${MASTER_COUNT}))

    local tries=0
    until [ ${nodes_num_expected} -eq ${nodes_num_actual} ]; do
        msg "Waiting all nodes to be ready."
        sleep 30; let tries+=1;
        if [ ${tries} -gt 20 ]; then
          echo "# kubectl get node"
          exec_on master1 ${KUBECTL_CMD} get node
          fail "Timeout waiting all nodes to be ready."
        fi
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

    sleep 60
    exec_on master1 ${KUBECTL_CMD} logs --pod-running-timeout=120s e2e -f
    exec_on master1 ${KUBECTL_CMD} logs e2e --tail 1 | grep -q 'Test Suite Passed'
    exec_on master1 "curl -L ${url} 2>/dev/null | ${KUBECTL_CMD} delete -f -"
}

main() {
  stage-preflight

  if ! determine-changes $AWS_FILES_REGEX; then
      msg "No changes. Skipping e2e tests for AWS."
      exit
  fi

  stage-prepare
  stage-prepare-ssh
  trap "stage-destroy" EXIT
  stage-terraform-only-vault
  # Let Vault VM start.
  # In Azure we don't have this issue, because terraform actually wait when OS is ready.
  counter=5;
  vault_address="vault1.${CLUSTER}.${E2E_AWS_REGION}.aws.gigantic.io"
  while ! ssh -o ConnectTimeout=3 ${vault_address}  && [ $counter -gt 0 ]; do
      echo "Waiting for vault to be ready..."
      sleep 30
      ((counter--))
  done

  stage-vault
  stage-terraform

  # Wait for kubernetes nodes.
  stage-wait-kubernetes-nodes

  # Finally run tests if enabled.
  [ ! ${E2E_ENABLE_CONFORMANCE} ] || stage-e2e
}

main
