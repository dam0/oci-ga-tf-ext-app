# 🔒 Required Rulesets for Load Balancer → Backend Set Connectivity

## Overview

For the OCI Load Balancer to successfully reach the backend set (Tomcat instances), specific Network Security Group (NSG) rules must be configured. Here are the **exact rulesets** required:

## 🎯 Critical Rulesets

### 1. **Load Balancer NSG - Egress Rules**

#### Rule 1: Load Balancer → Backend Instances (Port 8080)
```hcl
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_cidr" {
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"  # TCP
  destination               = "10.0.2.0/24"  # Private subnet CIDR
  destination_type         = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8080  # Tomcat HTTP port
      max = 8080
    }
  }
  
  description = "Allow load balancer to reach Tomcat on port 8080"
}
```

#### Rule 2: Load Balancer → Backend Instances (Port 8888 - Optional)
```hcl
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_cidr_8888" {
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"  # TCP
  destination               = "10.0.2.0/24"  # Private subnet CIDR
  destination_type         = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8888  # Management port
      max = 8888
    }
  }
  
  description = "Allow load balancer to reach management port 8888"
}
```

### 2. **Private Compute NSG - Ingress Rules**

#### Rule 1: Backend Instances ← Load Balancer (Port 8080)
```hcl
resource "oci_core_network_security_group_security_rule" "private_app_ports_cidr_8080" {
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"  # TCP
  source                    = "10.0.1.0/24"  # Public subnet CIDR (where LB is)
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8080  # Tomcat HTTP port
      max = 8080
    }
  }
  
  description = "Allow load balancer subnet to reach Tomcat on port 8080"
}
```

#### Rule 2: Backend Instances ← Load Balancer (Port 8888 - Optional)
```hcl
resource "oci_core_network_security_group_security_rule" "private_app_ports_cidr_8888" {
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"  # TCP
  source                    = "10.0.1.0/24"  # Public subnet CIDR (where LB is)
  source_type              = "CIDR_BLOCK"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8888  # Management port
      max = 8888
    }
  }
  
  description = "Allow load balancer subnet to reach management port 8888"
}
```

## 🔐 Enhanced Security: NSG-to-NSG Rules

For better security, you can also use NSG-to-NSG rules instead of CIDR-based rules:

### Load Balancer NSG → Private Compute NSG
```hcl
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_nsg" {
  network_security_group_id = oci_core_network_security_group.load_balancer_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6"  # TCP
  destination               = oci_core_network_security_group.private_compute_nsg.id
  destination_type         = "NETWORK_SECURITY_GROUP"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
  
  description = "Allow load balancer NSG to reach private compute NSG on port 8080"
}
```

### Private Compute NSG ← Load Balancer NSG
```hcl
resource "oci_core_network_security_group_security_rule" "private_app_ports_from_lb_nsg" {
  network_security_group_id = oci_core_network_security_group.private_compute_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6"  # TCP
  source                    = oci_core_network_security_group.load_balancer_nsg.id
  source_type              = "NETWORK_SECURITY_GROUP"
  stateless                = false
  
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
  
  description = "Allow load balancer NSG to reach private compute NSG on port 8080"
}
```

## 📋 Minimum Required Rulesets Summary

### **CRITICAL - Must Have These 2 Rules:**

1. **Load Balancer Egress**: Allow LB to send traffic to backend instances on port 8080
2. **Backend Ingress**: Allow backend instances to receive traffic from LB on port 8080

### **Rule Parameters:**
- **Protocol**: TCP (6)
- **Port**: 8080 (Tomcat HTTP)
- **Source**: Load balancer subnet/NSG (10.0.1.0/24)
- **Destination**: Private instances subnet/NSG (10.0.2.0/24)
- **Stateless**: false (stateful connection tracking)

## 🔍 Current Implementation Status

### ✅ Already Implemented in Your Configuration

Looking at `modules/network/main.tf`, these rules are **already configured**:

#### Lines 383-401: Load Balancer Egress (CIDR-based)
```hcl
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_cidr" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  # ... configured for ports 8080, 8888
}
```

#### Lines 404-422: Load Balancer Egress (NSG-to-NSG)
```hcl
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_nsg" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  # ... configured for ports 8080, 8888
}
```

#### Lines 279-297: Private Compute Ingress (CIDR-based)
```hcl
resource "oci_core_network_security_group_security_rule" "private_app_ports_cidr" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  # ... configured for ports 8080, 8888
}
```

#### Lines 300-318: Private Compute Ingress (NSG-to-NSG)
```hcl
resource "oci_core_network_security_group_security_rule" "private_app_ports_from_lb_nsg" {
  for_each = toset([for port in var.app_ports : tostring(port)])
  # ... configured for ports 8080, 8888
}
```

## 🎯 Verification Commands

### Check if Rules are Applied
```bash
# Verify Terraform configuration
terraform plan | grep -A 5 "lb_egress_to_private"
terraform plan | grep -A 5 "private_app_ports"

# Check actual OCI NSG rules
oci network nsg-security-rule list --nsg-id <LOAD_BALANCER_NSG_ID>
oci network nsg-security-rule list --nsg-id <PRIVATE_COMPUTE_NSG_ID>
```

### Test Connectivity
```bash
# From load balancer subnet to private instance
curl -v http://10.0.2.160:8080/ords/

# Health check test
curl -v http://10.0.2.160:8080/ords/
```

## 🚨 Common Issues

### Issue 1: Backend Health Check Failures
**Symptom**: Load balancer shows backends as "UNHEALTHY"

**Required Rules Missing**:
- Load balancer egress to port 8080
- Private instance ingress from load balancer

**Fix**:
```bash
terraform apply  # Deploy the NSG rules
```

### Issue 2: 502 Bad Gateway Errors
**Symptom**: Load balancer returns 502 errors

**Possible Causes**:
- NSG rules not applied
- Tomcat not running on port 8080
- Health check endpoint not responding

**Fix**:
```bash
# Check NSG rules
terraform show | grep -A 10 "lb_egress_to_private"

# Check Tomcat status
ansible private_instances -i inventory/hosts.ini -m shell -a "systemctl status tomcat"

# Test health check endpoint
ansible private_instances -i inventory/hosts.ini -m shell -a "curl -v http://localhost:8080/ords/"
```

## 🎉 Conclusion

### ✅ Your Configuration is Complete!

The required rulesets for load balancer → backend set connectivity are **already implemented** in your Terraform configuration. The rules include:

1. **Load Balancer Egress**: ✅ Configured (both CIDR and NSG-to-NSG)
2. **Backend Ingress**: ✅ Configured (both CIDR and NSG-to-NSG)
3. **Port Configuration**: ✅ 8080 (Tomcat) and 8888 (Management)
4. **Security**: ✅ Least-privilege access with specific ports

### 🚀 Next Steps:
1. **Deploy**: `terraform apply`
2. **Provision**: `./fix_and_run_ansible.sh`
3. **Validate**: `./validate_lb_connectivity.sh`
4. **Test**: `curl -k https://<LB_IP>/ords/r/marinedataregister`

Your load balancer connectivity rulesets are **production-ready**! 🎯