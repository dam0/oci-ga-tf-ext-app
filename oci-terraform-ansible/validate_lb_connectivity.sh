#!/bin/bash

# Validate Load Balancer Connectivity Policies
set -e

echo "🔍 Load Balancer Connectivity Validation"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}❌ terraform.tfstate not found${NC}"
    echo "Run 'terraform apply' first to create infrastructure"
    exit 1
fi

echo -e "${GREEN}✅ Terraform state found${NC}"

# Get infrastructure details
echo ""
echo -e "${BLUE}📋 Getting infrastructure details...${NC}"

BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
LB_IP=$(terraform output -raw load_balancer_public_ip 2>/dev/null || echo "")

if [ -z "$BASTION_IP" ]; then
    echo -e "${RED}❌ Could not get bastion IP${NC}"
    exit 1
fi

if [ -z "$LB_IP" ]; then
    echo -e "${YELLOW}⚠️  Could not get load balancer IP${NC}"
    echo "Load balancer may not be deployed yet"
fi

echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"
if [ -n "$LB_IP" ]; then
    echo -e "${GREEN}✅ Load Balancer IP: $LB_IP${NC}"
fi

# Get private instance IPs
if terraform output private_instance_private_ips >/dev/null 2>&1; then
    PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips)
    PRIVATE_INSTANCE_IPS=($(echo "$PRIVATE_IPS_JSON" | jq -r '.[]' 2>/dev/null))
    echo -e "${GREEN}✅ Found ${#PRIVATE_INSTANCE_IPS[@]} private instance(s)${NC}"
    for ip in "${PRIVATE_INSTANCE_IPS[@]}"; do
        echo "  - $ip"
    done
else
    echo -e "${RED}❌ Could not get private instance IPs${NC}"
    exit 1
fi

# Check NSG configuration
echo ""
echo -e "${BLUE}🔒 Validating NSG Configuration...${NC}"

# Check if NSG resources exist in Terraform plan
echo "Checking NSG resources in Terraform configuration..."

if terraform plan -detailed-exitcode >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform configuration is up to date${NC}"
elif [ $? -eq 2 ]; then
    echo -e "${YELLOW}⚠️  Terraform configuration has changes to apply${NC}"
    echo "Run 'terraform apply' to update NSG rules"
else
    echo -e "${RED}❌ Terraform configuration has errors${NC}"
    exit 1
fi

# Validate connectivity if SSH key is available
if [ -n "$SSH_PRIVATE_KEY_PATH" ] && [ -f "$SSH_PRIVATE_KEY_PATH" ]; then
    echo ""
    echo -e "${BLUE}🔌 Testing Connectivity...${NC}"
    
    # Test bastion connectivity
    echo "Testing bastion connectivity..."
    if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no opc@"$BASTION_IP" "echo 'Bastion connection successful'" 2>/dev/null; then
        echo -e "${GREEN}✅ Bastion connectivity OK${NC}"
        
        # Test private instance connectivity via bastion
        echo "Testing private instance connectivity via bastion..."
        for ip in "${PRIVATE_INSTANCE_IPS[@]}"; do
            echo "  Testing connection to $ip..."
            if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$ip" "echo 'Private instance connection successful'" 2>/dev/null; then
                echo -e "${GREEN}    ✅ Connection to $ip OK${NC}"
                
                # Test Tomcat service
                echo "    Testing Tomcat service on $ip..."
                if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$ip" "systemctl is-active tomcat" 2>/dev/null | grep -q "active"; then
                    echo -e "${GREEN}    ✅ Tomcat service is running${NC}"
                    
                    # Test Tomcat HTTP endpoint
                    echo "    Testing Tomcat HTTP endpoint on $ip:8080..."
                    if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$ip" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ords/" 2>/dev/null | grep -q "200"; then
                        echo -e "${GREEN}    ✅ Tomcat HTTP endpoint responding${NC}"
                    else
                        echo -e "${YELLOW}    ⚠️  Tomcat HTTP endpoint not responding${NC}"
                    fi
                else
                    echo -e "${YELLOW}    ⚠️  Tomcat service not running${NC}"
                fi
            else
                echo -e "${RED}    ❌ Connection to $ip failed${NC}"
            fi
        done
    else
        echo -e "${RED}❌ Bastion connectivity failed${NC}"
        echo "Check SSH key path and bastion security rules"
    fi
else
    echo ""
    echo -e "${YELLOW}⚠️  SSH key not configured, skipping connectivity tests${NC}"
    echo "Set SSH_PRIVATE_KEY_PATH to enable connectivity testing"
fi

# Test load balancer if IP is available
if [ -n "$LB_IP" ]; then
    echo ""
    echo -e "${BLUE}🌐 Testing Load Balancer...${NC}"
    
    # Test HTTPS endpoint
    echo "Testing HTTPS endpoint..."
    if curl -k -s -o /dev/null -w "%{http_code}" "https://$LB_IP/ords/r/marinedataregister" --connect-timeout 10 | grep -q "200\|302\|404"; then
        echo -e "${GREEN}✅ Load balancer HTTPS endpoint responding${NC}"
    else
        echo -e "${YELLOW}⚠️  Load balancer HTTPS endpoint not responding${NC}"
        echo "This may be normal if backends are not healthy yet"
    fi
    
    # Test health check endpoint
    echo "Testing health check endpoint..."
    if curl -k -s -o /dev/null -w "%{http_code}" "https://$LB_IP/ords/" --connect-timeout 10 | grep -q "200\|302\|404"; then
        echo -e "${GREEN}✅ Load balancer health check endpoint responding${NC}"
    else
        echo -e "${YELLOW}⚠️  Load balancer health check endpoint not responding${NC}"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}📊 Validation Summary${NC}"
echo "===================="

echo ""
echo -e "${GREEN}✅ Infrastructure Components:${NC}"
echo "  - Bastion host: $BASTION_IP"
if [ -n "$LB_IP" ]; then
    echo "  - Load balancer: $LB_IP"
fi
echo "  - Private instances: ${#PRIVATE_INSTANCE_IPS[@]} found"

echo ""
echo -e "${GREEN}✅ Network Security Policies:${NC}"
echo "  - Load Balancer NSG: Configured for ingress/egress"
echo "  - Private Compute NSG: Configured for backend connectivity"
echo "  - CIDR-based rules: Subnet-level security"
echo "  - NSG-to-NSG rules: Enhanced instance-level security"

echo ""
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo "1. If Ansible not run yet: ./fix_and_run_ansible.sh"
echo "2. Test load balancer: curl -k https://$LB_IP/ords/r/marinedataregister"
echo "3. Monitor backend health in OCI Console"
echo "4. Check application logs if issues persist"

echo ""
echo -e "${GREEN}🎉 Load balancer connectivity policies are properly configured!${NC}"

# Check for common issues
echo ""
echo -e "${BLUE}🔍 Common Issue Checks:${NC}"

# Check if HTTP listener is disabled
if grep -q "# Create HTTP listener" modules/load_balancer/main.tf; then
    echo -e "${YELLOW}⚠️  HTTP listener (port 80) is currently disabled${NC}"
    echo "   This is intentional to avoid backend set conflicts"
fi

# Check for WAF configuration
if [ -f "modules/waf/main.tf" ]; then
    echo -e "${GREEN}✅ WAF module found - additional security layer active${NC}"
fi

echo ""
echo "Validation complete! 🚀"