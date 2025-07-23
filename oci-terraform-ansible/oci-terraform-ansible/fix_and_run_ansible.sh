#!/bin/bash

# Fix and Run Ansible Provisioning
set -e

echo "🔧 Fix and Run Ansible Provisioning"
echo "=================================="

# Check if SSH key path is set
if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
    echo "❌ SSH_PRIVATE_KEY_PATH not set"
    echo "Run: export SSH_PRIVATE_KEY_PATH=\"/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem\""
    exit 1
fi

echo "✅ SSH key path: $SSH_PRIVATE_KEY_PATH"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ terraform.tfstate not found"
    echo "Run 'terraform apply' first to create infrastructure"
    exit 1
fi

echo "✅ Terraform state found"

# Debug outputs
echo ""
echo "🔍 Checking Terraform outputs..."
echo "Available outputs:"
terraform output

# Try to get bastion IP
echo ""
echo "Getting bastion public IP..."
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip 2>/dev/null)
if [ -z "$BASTION_PUBLIC_IP" ]; then
    echo "❌ Could not get bastion public IP"
    exit 1
fi
echo "✅ Bastion IP: $BASTION_PUBLIC_IP"

# Try to get private instance IPs
echo ""
echo "Getting private instance IPs..."
if terraform output private_instance_private_ips >/dev/null 2>&1; then
    echo "✅ Found private_instance_private_ips output"
    PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips)
    echo "Raw JSON: $PRIVATE_IPS_JSON"
    
    # Parse IPs
    PRIVATE_INSTANCE_IPS=($(echo "$PRIVATE_IPS_JSON" | jq -r '.[]' 2>/dev/null))
    echo "✅ Found ${#PRIVATE_INSTANCE_IPS[@]} private instance(s)"
    for ip in "${PRIVATE_INSTANCE_IPS[@]}"; do
        echo "  - $ip"
    done
else
    echo "❌ private_instance_private_ips output not found"
    echo "Available outputs:"
    terraform output
    exit 1
fi

# Add bastion to known_hosts to avoid SSH prompts
echo ""
echo "🔐 Adding bastion to known_hosts..."
ssh-keyscan -H "$BASTION_PUBLIC_IP" >> ~/.ssh/known_hosts 2>/dev/null || true
echo "✅ Bastion added to known_hosts"

# Generate inventory
echo ""
echo "📝 Generating Ansible inventory..."
mkdir -p ansible/inventory

cat > ansible/inventory/hosts.ini << EOF
[bastion]
bastion ansible_host=${BASTION_PUBLIC_IP} ansible_user=opc

[private_instances]
EOF

# Add each private instance
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

echo "✅ Inventory generated at ansible/inventory/hosts.ini"

# Show inventory
echo ""
echo "📋 Generated inventory:"
echo "======================"
cat ansible/inventory/hosts.ini

# Test connectivity
echo ""
echo "🔌 Testing connectivity..."
cd ansible

echo "Testing bastion connectivity..."
if ansible bastion -i inventory/hosts.ini -m ping; then
    echo "✅ Bastion connectivity OK"
else
    echo "❌ Bastion connectivity failed"
    exit 1
fi

echo ""
echo "Testing private instances connectivity..."
if ansible private_instances -i inventory/hosts.ini -m ping; then
    echo "✅ Private instances connectivity OK"
else
    echo "⚠️  Private instances connectivity failed - continuing anyway"
fi

# Run Ansible provisioning
echo ""
echo "🚀 Running Ansible provisioning..."
echo "================================="
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v

echo ""
echo "🎉 Ansible provisioning completed!"
echo ""
echo "Next steps:"
echo "1. Test Tomcat: curl http://<private_ip>:8080"
echo "2. Test load balancer: curl -k https://<lb_ip>/ords/r/marinedataregister"
echo "3. Check services: ansible private_instances -i inventory/hosts.ini -m shell -a 'systemctl status tomcat'"