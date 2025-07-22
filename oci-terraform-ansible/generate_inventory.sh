#!/bin/bash

# Get Terraform outputs
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip)
PRIVATE_INSTANCE_IP=$(terraform output -raw private_instance_private_ip)
CREATE_SECOND_INSTANCE=$(terraform output -raw create_second_instance 2>/dev/null || echo "false")
SECOND_PRIVATE_INSTANCE_IP=""

if [ "$CREATE_SECOND_INSTANCE" == "true" ]; then
  SECOND_PRIVATE_INSTANCE_IP=$(terraform output -raw second_private_instance_private_ip)
fi

# Create Ansible inventory file
cat > ansible/inventory/hosts.ini << EOF
[bastion]
bastion ansible_host=${BASTION_PUBLIC_IP} ansible_user=opc

[private_instances]
private_instance ansible_host=${PRIVATE_INSTANCE_IP} ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i ${SSH_PRIVATE_KEY_PATH} opc@${BASTION_PUBLIC_IP}"'
EOF

if [ "$CREATE_SECOND_INSTANCE" == "true" ]; then
  cat >> ansible/inventory/hosts.ini << EOF
private_instance_secondary ansible_host=${SECOND_PRIVATE_INSTANCE_IP} ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i ${SSH_PRIVATE_KEY_PATH} opc@${BASTION_PUBLIC_IP}"'
EOF
fi

cat >> ansible/inventory/hosts.ini << EOF

[all:vars]
ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH}
bastion_public_ip=${BASTION_PUBLIC_IP}
private_instance_private_ip=${PRIVATE_INSTANCE_IP}
second_private_instance_private_ip=${SECOND_PRIVATE_INSTANCE_IP}
create_second_instance=${CREATE_SECOND_INSTANCE}
EOF

echo "Ansible inventory file generated at ansible/inventory/hosts.ini"