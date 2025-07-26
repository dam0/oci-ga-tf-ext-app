#!/bin/bash

# Manual Ansible Provisioning Script
# This script runs Ansible provisioning independently of Terraform

set -e

echo "=== OCI Terraform + Ansible Provisioning ==="
echo "Running Ansible provisioning manually..."
echo ""

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
  echo "Error: main.tf not found. Please run this script from the oci-terraform-ansible directory."
  exit 1
fi

# Check if Terraform state exists
if [ ! -f "terraform.tfstate" ]; then
  echo "Error: terraform.tfstate not found. Please run 'terraform apply' first."
  exit 1
fi

# Set SSH key path (update this path as needed)
if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
  # Try to detect the SSH key path from terraform.tfvars
  if [ -f "terraform.tfvars" ]; then
    SSH_KEY_FROM_TFVARS=$(grep "private_key_path" terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
    if [ -n "$SSH_KEY_FROM_TFVARS" ]; then
      export SSH_PRIVATE_KEY_PATH="$SSH_KEY_FROM_TFVARS"
    fi
  fi
  
  # Default fallback
  if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
    export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"
  fi
fi

# Check if SSH key exists
if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
  echo "Error: SSH private key not found at $SSH_PRIVATE_KEY_PATH"
  echo ""
  echo "Please set the SSH_PRIVATE_KEY_PATH environment variable or update this script:"
  echo "  export SSH_PRIVATE_KEY_PATH=/path/to/your/ssh/key.pem"
  echo "  ./run_ansible.sh"
  echo ""
  echo "Or update the path in terraform.tfvars:"
  echo "  private_key_path = \"/path/to/your/ssh/key.pem\""
  exit 1
fi

echo "Using SSH key: $SSH_PRIVATE_KEY_PATH"
echo ""

# Wait for instances to be fully initialized (if just deployed)
echo "Waiting 30 seconds for instances to be fully ready..."
sleep 30

# Generate Ansible inventory
echo "Generating Ansible inventory..."
./generate_inventory.sh

if [ ! -f "ansible/inventory/hosts.ini" ]; then
  echo "Error: Failed to generate Ansible inventory"
  exit 1
fi

echo ""
echo "Generated inventory:"
echo "==================="
cat ansible/inventory/hosts.ini
echo "==================="
echo ""

# Test SSH connectivity to bastion
echo "Testing SSH connectivity to bastion..."
BASTION_IP=$(terraform output -raw bastion_public_ip)
if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no opc@"$BASTION_IP" "echo 'Bastion connectivity: OK'" 2>/dev/null; then
  echo "✅ Bastion SSH connectivity: OK"
else
  echo "❌ Bastion SSH connectivity: FAILED"
  echo "Please check:"
  echo "1. SSH key path: $SSH_PRIVATE_KEY_PATH"
  echo "2. Bastion IP: $BASTION_IP"
  echo "3. Security group rules allow SSH (port 22)"
  exit 1
fi

# Test SSH connectivity to private instances via bastion
echo "Testing SSH connectivity to private instances..."
PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips)
PRIVATE_IPS=($(echo "$PRIVATE_IPS_JSON" | jq -r '.[]'))

for i in "${!PRIVATE_IPS[@]}"; do
  PRIVATE_IP="${PRIVATE_IPS[$i]}"
  echo "Testing private_instance_$((i+1)) (${PRIVATE_IP})..."
  
  if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
     -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" \
     opc@"$PRIVATE_IP" "echo 'Private instance connectivity: OK'" 2>/dev/null; then
    echo "✅ private_instance_$((i+1)) SSH connectivity: OK"
  else
    echo "❌ private_instance_$((i+1)) SSH connectivity: FAILED"
    echo "Please check network connectivity and security group rules"
    exit 1
  fi
done

echo ""
echo "All SSH connectivity tests passed! 🎉"
echo ""

# Run Ansible playbook
echo "Running Ansible playbook..."
echo "=========================="

cd ansible

# Test Ansible connectivity first
echo "Testing Ansible connectivity..."
if ansible -i inventory/hosts.ini private_instances -m ping -v; then
  echo "✅ Ansible connectivity: OK"
else
  echo "❌ Ansible connectivity: FAILED"
  echo "Please check the inventory file and SSH configuration"
  exit 1
fi

echo ""
echo "Running Ansible provisioning playbook..."
echo "========================================"

# Run the actual provisioning
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v

echo ""
echo "=== Ansible Provisioning Complete! ==="
echo ""

# Test Tomcat service
echo "Testing Tomcat service on private instances..."
for i in "${!PRIVATE_IPS[@]}"; do
  PRIVATE_IP="${PRIVATE_IPS[$i]}"
  echo "Testing Tomcat on private_instance_$((i+1)) (${PRIVATE_IP})..."
  
  if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
     -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" \
     opc@"$PRIVATE_IP" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/" 2>/dev/null | grep -q "200"; then
    echo "✅ private_instance_$((i+1)) Tomcat: OK (HTTP 200)"
  else
    echo "⚠️  private_instance_$((i+1)) Tomcat: Not ready yet (this is normal, may take a few minutes)"
  fi
done

echo ""
echo "🚀 Deployment Summary:"
echo "====================="
echo "✅ Infrastructure: Deployed"
echo "✅ Ansible Provisioning: Complete"
echo "✅ SSH Connectivity: Working"
echo "⏳ Tomcat Services: Starting (may take a few minutes)"
echo ""
echo "Next Steps:"
echo "1. Wait 2-3 minutes for Tomcat to fully start"
echo "2. Test load balancer: curl -k https://$(terraform output -raw load_balancer_ip)/ords/r/marinedataregister"
echo "3. Check load balancer health checks in OCI Console"
echo ""
echo "For troubleshooting, check:"
echo "- Tomcat logs: ssh -J opc@$BASTION_IP opc@<PRIVATE_IP> 'sudo journalctl -u tomcat -f'"
echo "- APEX images: ssh -J opc@$BASTION_IP opc@<PRIVATE_IP> 'ls -la /opt/tomcat/webapps/ords/i/apex_ui/'"