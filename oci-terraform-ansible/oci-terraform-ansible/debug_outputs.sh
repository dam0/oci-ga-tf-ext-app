#!/bin/bash

echo "=== Debugging Terraform Outputs ==="
echo ""

echo "1. Checking if terraform state exists..."
if [ -f "terraform.tfstate" ]; then
    echo "✅ terraform.tfstate found"
else
    echo "❌ terraform.tfstate NOT found - run 'terraform apply' first"
    exit 1
fi

echo ""
echo "2. Listing all available outputs..."
terraform output

echo ""
echo "3. Checking specific outputs..."

echo "Bastion public IP:"
terraform output bastion_public_ip 2>&1 || echo "❌ bastion_public_ip not found"

echo ""
echo "Private instance IPs (plural):"
terraform output private_instance_private_ips 2>&1 || echo "❌ private_instance_private_ips not found"

echo ""
echo "Private instance IP (singular - old name):"
terraform output private_instance_private_ip 2>&1 || echo "❌ private_instance_private_ip not found (this is expected)"

echo ""
echo "4. Raw JSON output for private instances:"
terraform output -json private_instance_private_ips 2>&1 || echo "❌ JSON output failed"

echo ""
echo "=== Debug Complete ==="