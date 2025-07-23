#!/bin/bash

# Get Terraform outputs
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip)

# Get private instance IPs (array output)
PRIVATE_INSTANCE_IPS=$(terraform output -json private_instance_private_ips)
FIRST_PRIVATE_IP=$(echo $PRIVATE_INSTANCE_IPS | jq -r '.[0]')
SECOND_PRIVATE_IP=$(echo $PRIVATE_INSTANCE_IPS | jq -r '.[1] // empty')

# Check if we have a second instance
if [ "$SECOND_PRIVATE_IP" != "" ] && [ "$SECOND_PRIVATE_IP" != "null" ]; then
  CREATE_SECOND_INSTANCE="true"
else
  CREATE_SECOND_INSTANCE="false"
fi

# Create Ansible inventory file
cat > ansible/inventory/hosts.ini << EOF
[bastion]
bastion ansible_host=${BASTION_PUBLIC_IP} ansible_user=opc

[private_instances]
private_instance_1 ansible_host=${FIRST_PRIVATE_IP} ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i ${SSH_PRIVATE_KEY_PATH} opc@${BASTION_PUBLIC_IP}"'
EOF

if [ "$CREATE_SECOND_INSTANCE" == "true" ]; then
  cat >> ansible/inventory/hosts.ini << EOF
private_instance_2 ansible_host=${SECOND_PRIVATE_IP} ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i ${SSH_PRIVATE_KEY_PATH} opc@${BASTION_PUBLIC_IP}"'
EOF
fi

cat >> ansible/inventory/hosts.ini << EOF

[all:vars]
ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH}
bastion_public_ip=${BASTION_PUBLIC_IP}
first_private_instance_ip=${FIRST_PRIVATE_IP}
second_private_instance_ip=${SECOND_PRIVATE_IP}
create_second_instance=${CREATE_SECOND_INSTANCE}
EOF

echo "Ansible inventory file generated at ansible/inventory/hosts.ini"