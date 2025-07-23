# Load Balancer Connectivity Guide

## Overview

This guide ensures that your OCI Load Balancer has all the necessary policies and network security rules to properly connect to backend instances. The configuration includes comprehensive IAM policies, Network Security Groups (NSGs), and connectivity verification tools.

## 🔐 IAM Policies for Load Balancer Service

### 1. Load Balancer Service Policies

The load balancer service requires specific IAM policies to function properly:

```hcl
# Allow load balancer service to manage network resources
"allow service loadbalancer to manage virtual-network-family in compartment id ${compartment_id}"

# Allow load balancer to read compute instances for health checks
"allow service loadbalancer to read instance-family in compartment id ${compartment_id}"

# Allow load balancer to manage certificates
"allow service loadbalancer to manage certificates in compartment id ${compartment_id}"

# Allow load balancer to use network security groups
"allow service loadbalancer to use network-security-groups in compartment id ${compartment_id}"
```

### 2. WAF Service Policies (if WAF is enabled)

```hcl
# Allow WAF to manage load balancers
"allow service waas to manage load-balancers in compartment id ${compartment_id}"

# Allow WAF to read virtual network resources
"allow service waas to read virtual-network-family in compartment id ${compartment_id}"
```

### 3. Health Check Service Policies

```hcl
# Allow health check service to read instances
"allow service health-check to read instance-family in compartment id ${compartment_id}"

# Allow health check service to read network resources
"allow service health-check to read virtual-network-family in compartment id ${compartment_id}"
```

## 🛡️ Network Security Groups (NSGs)

### Load Balancer NSG Rules

**Ingress Rules:**
- **HTTPS (443)**: Allow from specified CIDR blocks (configured via `allowed_ipv4_cidr` and `allowed_ipv6_cidr`)
- **HTTP (80)**: Allow from specified CIDR blocks (if `allow_http = true`)

**Egress Rules:**
- **To Private Compute NSG**: Allow traffic on application ports (8080, 8443, 9090) to private compute NSG
- **To Private Subnet CIDR**: Allow traffic on application ports to private subnet (for broader compatibility)

### Private Compute NSG Rules

**Ingress Rules:**
- **SSH (22)**: Allow from bastion NSG only
- **Application Ports (8080, 8443, 9090)**: Allow from load balancer NSG
- **Application Ports (8080, 8443, 9090)**: Allow from public subnet CIDR (for direct access if needed)

**Egress Rules:**
- **All Traffic**: Allow all outbound traffic to 0.0.0.0/0

### Bastion NSG Rules

**Ingress Rules:**
- **SSH (22)**: Allow from specified SSH CIDR blocks (configured via `allowed_ssh_cidr`)

**Egress Rules:**
- **All Traffic**: Allow all outbound traffic to 0.0.0.0/0

## 🔧 Configuration Variables

### Enable IAM Policies

```hcl
# In terraform.tfvars or variables
create_load_balancer_policies = true    # Creates load balancer service policies
enable_dynamic_group_policies = false   # Creates dynamic group policies (advanced)
create_health_check_policies = false    # Creates health check service policies
```

### Network Security Configuration

```hcl
# IP filtering for load balancer access
allowed_ipv4_cidr = ["10.0.0.0/8"]           # IPv4 CIDR blocks allowed to access LB
allowed_ipv6_cidr = ["2400:a844:4088::/48"]  # IPv6 CIDR blocks allowed to access LB
allowed_ssh_cidr  = ["0.0.0.0/0"]            # CIDR blocks allowed SSH access to bastion

# Application ports
app_ports = [8080, 8443, 9090]  # Ports allowed from LB to backend instances

# Protocol enablement
allow_http  = false  # Enable HTTP (port 80) listener
allow_https = true   # Enable HTTPS (port 443) listener
```

## 🚀 Deployment Steps

### 1. Apply Terraform Configuration

```bash
# Deploy infrastructure with IAM policies
terraform apply
```

### 2. Verify Load Balancer Connectivity

```bash
# Run comprehensive connectivity verification
./verify_load_balancer_connectivity.sh
```

### 3. Deploy Applications to Backend Instances

```bash
# Run Ansible provisioning
./run_ansible.sh
```

## 🔍 Connectivity Verification

The `verify_load_balancer_connectivity.sh` script performs comprehensive checks:

### 1. Load Balancer Tests
- ✅ HTTPS endpoint accessibility
- ✅ Health check endpoint response
- ✅ SSL certificate validation

### 2. Backend Instance Tests
- ✅ SSH connectivity via bastion
- ✅ Tomcat service status
- ✅ Firewall configuration
- ✅ Application port accessibility

### 3. Network Security Tests
- ✅ NSG configuration verification
- ✅ Security list rules validation
- ✅ Network connectivity paths

### 4. IAM Policy Tests
- ✅ Load balancer service policy existence
- ✅ WAF service policy (if enabled)
- ✅ Health check service policy (if enabled)

## 🛠️ Troubleshooting

### Issue: Load Balancer Cannot Connect to Backends

**Symptoms:**
- Load balancer health checks failing
- Backend instances showing as "Critical" in OCI Console
- HTTP 502/503 errors from load balancer

**Solutions:**

1. **Check NSG Rules:**
   ```bash
   # Verify load balancer can reach backend instances
   terraform output load_balancer_nsg_id
   terraform output private_compute_nsg_id
   ```

2. **Verify Backend Services:**
   ```bash
   # Test Tomcat on each backend instance
   ssh -J opc@<bastion_ip> opc@<private_ip> "curl -I http://localhost:8080/"
   ```

3. **Check Firewall Rules:**
   ```bash
   # Verify firewall allows application ports
   ssh -J opc@<bastion_ip> opc@<private_ip> "sudo firewall-cmd --list-ports"
   ```

### Issue: IAM Policy Errors

**Symptoms:**
- "Unauthorized" errors in load balancer logs
- Cannot create/modify load balancer resources
- Certificate management failures

**Solutions:**

1. **Enable IAM Policies:**
   ```hcl
   create_load_balancer_policies = true
   ```

2. **Check Policy Statements:**
   ```bash
   terraform output load_balancer_service_policy_id
   ```

3. **Verify Compartment Permissions:**
   - Ensure policies are created in correct compartment
   - Check tenancy-level permissions if needed

### Issue: Network Connectivity Problems

**Symptoms:**
- Cannot reach load balancer from internet
- Backend instances unreachable from load balancer
- SSH connectivity issues

**Solutions:**

1. **Check Security Lists:**
   ```bash
   # Verify public subnet allows HTTPS
   # Verify private subnet allows application ports from public subnet
   ```

2. **Verify Route Tables:**
   ```bash
   # Public subnet should route to Internet Gateway
   # Private subnet should route to NAT Gateway
   ```

3. **Test Network Paths:**
   ```bash
   # Use connectivity verification script
   ./verify_load_balancer_connectivity.sh
   ```

## 📋 Security Best Practices

### 1. Principle of Least Privilege
- ✅ Load balancer NSG only allows necessary ports
- ✅ Private instances only accessible via bastion
- ✅ IAM policies scoped to specific compartment

### 2. Network Segmentation
- ✅ Load balancer in public subnet
- ✅ Backend instances in private subnet
- ✅ Bastion host for secure access

### 3. Traffic Encryption
- ✅ HTTPS termination at load balancer
- ✅ SSL certificate management
- ✅ HTTP to HTTPS redirect (when enabled)

### 4. Access Control
- ✅ IP-based filtering for load balancer access
- ✅ SSH access restricted to specific CIDR blocks
- ✅ WAF protection for application endpoints

## 🎯 Health Check Configuration

### Load Balancer Health Check Settings

```hcl
health_checker {
  protocol            = "HTTP"
  port                = 8080
  url_path            = "/"
  return_code         = 200
  interval_ms         = 30000
  timeout_in_millis   = 3000
  retries             = 3
}
```

### Backend Instance Health Requirements

For backends to pass health checks:

1. **Tomcat Service Running:**
   ```bash
   sudo systemctl status tomcat
   ```

2. **Port 8080 Accessible:**
   ```bash
   curl -I http://localhost:8080/
   ```

3. **Firewall Rules Configured:**
   ```bash
   sudo firewall-cmd --list-ports | grep 8080
   ```

4. **Application Deployed:**
   ```bash
   curl -I http://localhost:8080/ords/r/marinedataregister
   ```

## 📊 Monitoring and Logging

### OCI Console Monitoring

1. **Load Balancer Health:**
   - Navigate to: Networking → Load Balancers → [Your LB] → Backend Sets
   - Check: Health Check Status for each backend

2. **Network Security Groups:**
   - Navigate to: Networking → Virtual Cloud Networks → [Your VCN] → Network Security Groups
   - Verify: Security rules are properly configured

3. **IAM Policies:**
   - Navigate to: Identity & Security → Identity → Policies
   - Check: Load balancer service policies exist

### Command Line Monitoring

```bash
# Check load balancer status
oci lb load-balancer get --load-balancer-id <lb_id>

# Check backend health
oci lb backend-health get --load-balancer-id <lb_id> --backend-set-name <backend_set_name>

# Check NSG rules
oci network nsg list --compartment-id <compartment_id>
```

## 🔄 Maintenance and Updates

### Regular Checks

1. **Monthly:**
   - Run connectivity verification script
   - Review load balancer metrics
   - Check certificate expiration

2. **Quarterly:**
   - Review and update IAM policies
   - Audit network security rules
   - Test disaster recovery procedures

3. **As Needed:**
   - Update backend instance configurations
   - Modify load balancer settings
   - Adjust security rules

### Update Procedures

1. **Adding New Backend Instances:**
   ```bash
   # Update Terraform configuration
   # Apply changes
   terraform apply
   
   # Verify connectivity
   ./verify_load_balancer_connectivity.sh
   ```

2. **Modifying Security Rules:**
   ```bash
   # Update NSG rules in Terraform
   # Apply changes carefully
   terraform plan
   terraform apply
   ```

3. **Certificate Updates:**
   ```bash
   # Update certificate OCID in terraform.tfvars
   certificate_ocid = "ocid1.certificate.oc1...."
   terraform apply
   ```

## 🎉 Success Indicators

Your load balancer connectivity is properly configured when:

- ✅ Load balancer responds to HTTPS requests
- ✅ All backend instances show "OK" health status
- ✅ Application endpoints return expected responses
- ✅ SSL certificate is properly configured
- ✅ WAF policies are active (if enabled)
- ✅ All connectivity verification tests pass

## 📞 Support and Resources

- **OCI Documentation:** [Load Balancer Service](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm)
- **Network Security Groups:** [NSG Documentation](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/networksecuritygroups.htm)
- **IAM Policies:** [Policy Reference](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm)
- **Connectivity Verification:** Run `./verify_load_balancer_connectivity.sh` for detailed diagnostics