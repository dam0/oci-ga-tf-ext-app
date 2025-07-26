#!/bin/bash

# Load Balancer Connectivity Verification Script
# This script verifies that the load balancer can properly connect to backend instances

set -e

echo "=== OCI Load Balancer Connectivity Verification ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    print_status "ERROR" "Terraform is not installed or not in PATH"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    print_status "ERROR" "jq is not installed or not in PATH"
    exit 1
fi

print_status "INFO" "Starting load balancer connectivity verification..."
echo ""

# Get Terraform outputs
print_status "INFO" "Retrieving Terraform outputs..."

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    print_status "ERROR" "Terraform state file not found. Please run 'terraform apply' first."
    exit 1
fi

# Get load balancer information
LB_IP=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "")
LB_ID=$(terraform output -raw load_balancer_id 2>/dev/null || echo "")
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips 2>/dev/null || echo "[]")

if [ -z "$LB_IP" ] || [ -z "$LB_ID" ] || [ -z "$BASTION_IP" ]; then
    print_status "ERROR" "Failed to retrieve required Terraform outputs"
    exit 1
fi

PRIVATE_IPS=($(echo "$PRIVATE_IPS_JSON" | jq -r '.[]'))

print_status "SUCCESS" "Retrieved Terraform outputs"
echo "  Load Balancer IP: $LB_IP"
echo "  Load Balancer ID: $LB_ID"
echo "  Bastion IP: $BASTION_IP"
echo "  Private Instance IPs: ${PRIVATE_IPS[*]}"
echo ""

# 1. Test Load Balancer HTTPS Endpoint
print_status "INFO" "Testing load balancer HTTPS endpoint..."
if curl -k -s --connect-timeout 10 "https://$LB_IP" > /dev/null 2>&1; then
    print_status "SUCCESS" "Load balancer HTTPS endpoint is accessible"
else
    print_status "WARNING" "Load balancer HTTPS endpoint is not responding (this may be expected if backends are not ready)"
fi

# 2. Test Load Balancer Health Check Endpoint
print_status "INFO" "Testing load balancer health check..."
HEALTH_CHECK_RESPONSE=$(curl -k -s -w "%{http_code}" -o /dev/null --connect-timeout 10 "https://$LB_IP/ords/r/marinedataregister" 2>/dev/null || echo "000")
if [ "$HEALTH_CHECK_RESPONSE" = "200" ]; then
    print_status "SUCCESS" "Load balancer health check passed (HTTP 200)"
elif [ "$HEALTH_CHECK_RESPONSE" = "404" ]; then
    print_status "WARNING" "Load balancer is accessible but application not found (HTTP 404) - may need Ansible provisioning"
elif [ "$HEALTH_CHECK_RESPONSE" = "000" ]; then
    print_status "WARNING" "Load balancer health check failed - connection timeout"
else
    print_status "WARNING" "Load balancer health check returned HTTP $HEALTH_CHECK_RESPONSE"
fi

# 3. Test Backend Instance Connectivity via Bastion
print_status "INFO" "Testing backend instance connectivity via bastion..."

# Set SSH key path
if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
    if [ -f "terraform.tfvars" ]; then
        SSH_KEY_FROM_TFVARS=$(grep "private_key_path" terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "")
        if [ -n "$SSH_KEY_FROM_TFVARS" ]; then
            export SSH_PRIVATE_KEY_PATH="$SSH_KEY_FROM_TFVARS"
        fi
    fi
    
    if [ -z "$SSH_PRIVATE_KEY_PATH" ]; then
        export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"
    fi
fi

if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    print_status "WARNING" "SSH private key not found at $SSH_PRIVATE_KEY_PATH - skipping backend connectivity tests"
else
    print_status "INFO" "Using SSH key: $SSH_PRIVATE_KEY_PATH"
    
    # Test bastion connectivity first
    print_status "INFO" "Testing bastion host connectivity..."
    if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes opc@"$BASTION_IP" "echo 'Bastion connection successful'" 2>/dev/null; then
        print_status "SUCCESS" "Bastion host is accessible"
        
        # Test each private instance
        for i in "${!PRIVATE_IPS[@]}"; do
            PRIVATE_IP="${PRIVATE_IPS[$i]}"
            print_status "INFO" "Testing private instance $((i+1)) ($PRIVATE_IP)..."
            
            # Test SSH connectivity
            if ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$PRIVATE_IP" "echo 'Private instance connection successful'" 2>/dev/null; then
                print_status "SUCCESS" "Private instance $((i+1)) is accessible via SSH"
                
                # Test Tomcat service
                print_status "INFO" "Testing Tomcat service on private instance $((i+1))..."
                TOMCAT_STATUS=$(ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$PRIVATE_IP" "curl -s -w '%{http_code}' -o /dev/null --connect-timeout 5 http://localhost:8080/ 2>/dev/null || echo '000'" 2>/dev/null)
                
                if [ "$TOMCAT_STATUS" = "200" ]; then
                    print_status "SUCCESS" "Tomcat is running on private instance $((i+1))"
                elif [ "$TOMCAT_STATUS" = "404" ]; then
                    print_status "WARNING" "Tomcat is running but no application deployed on private instance $((i+1))"
                else
                    print_status "WARNING" "Tomcat is not responding on private instance $((i+1)) (HTTP $TOMCAT_STATUS)"
                fi
                
                # Test firewall rules
                print_status "INFO" "Testing firewall configuration on private instance $((i+1))..."
                FIREWALL_STATUS=$(ssh -i "$SSH_PRIVATE_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o BatchMode=yes -o ProxyCommand="ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_IP" opc@"$PRIVATE_IP" "sudo firewall-cmd --list-ports 2>/dev/null | grep -q '8080\|8443' && echo 'configured' || echo 'not_configured'" 2>/dev/null)
                
                if [ "$FIREWALL_STATUS" = "configured" ]; then
                    print_status "SUCCESS" "Firewall is properly configured on private instance $((i+1))"
                else
                    print_status "WARNING" "Firewall may not be configured for Tomcat ports on private instance $((i+1))"
                fi
                
            else
                print_status "ERROR" "Cannot connect to private instance $((i+1)) via SSH"
            fi
        done
        
    else
        print_status "ERROR" "Cannot connect to bastion host"
    fi
fi

# 4. Test Network Security Group Rules
print_status "INFO" "Checking Network Security Group configuration..."

# Get NSG information
LB_NSG_ID=$(terraform output -raw load_balancer_nsg_id 2>/dev/null || echo "")
PRIVATE_NSG_ID=$(terraform output -raw private_compute_nsg_id 2>/dev/null || echo "")

if [ -n "$LB_NSG_ID" ] && [ -n "$PRIVATE_NSG_ID" ]; then
    print_status "SUCCESS" "Network Security Groups are configured"
    echo "  Load Balancer NSG: $LB_NSG_ID"
    echo "  Private Compute NSG: $PRIVATE_NSG_ID"
else
    print_status "WARNING" "Could not retrieve NSG information"
fi

# 5. Test IAM Policies
print_status "INFO" "Checking IAM policies..."

LB_POLICY_ID=$(terraform output -raw load_balancer_service_policy_id 2>/dev/null || echo "")
if [ -n "$LB_POLICY_ID" ] && [ "$LB_POLICY_ID" != "null" ]; then
    print_status "SUCCESS" "Load balancer service policy is configured: $LB_POLICY_ID"
else
    print_status "WARNING" "Load balancer service policy not found - may need to enable create_load_balancer_policies"
fi

# 6. Summary and Recommendations
echo ""
print_status "INFO" "=== CONNECTIVITY VERIFICATION SUMMARY ==="
echo ""

print_status "INFO" "Load Balancer Configuration:"
echo "  • HTTPS Endpoint: https://$LB_IP"
echo "  • Application Path: https://$LB_IP/ords/r/marinedataregister"
echo "  • Backend Instances: ${#PRIVATE_IPS[@]} configured"
echo ""

print_status "INFO" "Next Steps:"
echo "  1. If backends are not responding, run Ansible provisioning:"
echo "     ./run_ansible.sh"
echo ""
echo "  2. Monitor load balancer health in OCI Console:"
echo "     Networking → Load Balancers → Backend Sets → Health Check Status"
echo ""
echo "  3. Test application deployment:"
echo "     curl -k https://$LB_IP/ords/r/marinedataregister"
echo ""

print_status "SUCCESS" "Load balancer connectivity verification completed!"