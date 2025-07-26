#!/bin/bash

# Generate Ansible inventory for modular Terraform configuration
set -e

echo "Generating Ansible inventory from Terraform outputs..."

# Get Terraform outputs
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip)

# Get private instance IPs as JSON array and extract individual IPs
PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips)
PRIVATE_INSTANCE_IPS=($(echo "$PRIVATE_IPS_JSON" | jq -r '.[]' 2>/dev/null))

# Check if we have any private instances
if [ ${#PRIVATE_INSTANCE_IPS[@]} -eq 0 ]; then
  echo "Error: No private instances found in Terraform outputs"
  exit 1
fi

echo "Found ${#PRIVATE_INSTANCE_IPS[@]} private instance(s)"
echo "Bastion IP: $BASTION_PUBLIC_IP"

# Create inventory directory if it doesn't exist
mkdir -p ansible/inventory

# Create Ansible inventory file
cat > ansible/inventory/hosts.ini << EOF
[bastion]
bastion ansible_host=${BASTION_PUBLIC_IP} ansible_user=opc

[private_instances]
EOF

# Add each private instance to the inventory
for i in "${!PRIVATE_INSTANCE_IPS[@]}"; do
  instance_name="private_instance_$((i+1))"
  instance_ip="${PRIVATE_INSTANCE_IPS[$i]}"
  echo "Adding $instance_name with IP $instance_ip"
  
  cat >> ansible/inventory/hosts.ini << EOF
${instance_name} ansible_host=${instance_ip} ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no opc@${BASTION_PUBLIC_IP}"'
EOF
done

# Add group variables
cat >> ansible/inventory/hosts.ini << EOF

[all:vars]
ansible_ssh_private_key_file=${SSH_PRIVATE_KEY_PATH}
bastion_public_ip=${BASTION_PUBLIC_IP}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Ansible inventory file generated at ansible/inventory/hosts.ini"
echo ""
echo "Inventory contents:"
cat ansible/inventory/hosts.ini