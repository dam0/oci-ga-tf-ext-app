# 🔗 Load Balancer Connectivity Policies

## Overview

This document explains the network security policies that enable the OCI Load Balancer to connect to the backend Tomcat instances running on private compute instances.

## 🏗️ Architecture

```
Internet → Load Balancer (Public Subnet) → Private Instances (Private Subnet)
           [Load Balancer NSG]              [Private Compute NSG]
```

## 🔒 Network Security Groups (NSGs)

### Load Balancer NSG
**Purpose**: Controls traffic to/from the load balancer
**Location**: `modules/network/main.tf` lines 310-318

### Private Compute NSG  
**Purpose**: Controls traffic to/from private instances
**Location**: `modules/network/main.tf` lines 249-257

## 📋 Connectivity Policies

### 1. Internet → Load Balancer (Ingress)

#### HTTP Traffic (Port 80)
```hcl
# Allow HTTP from allowed CIDR blocks
resource "oci_core_network_security_group_security_rule" "lb_http_ingress"
```
- **Source**: Configured CIDR blocks (IPv4/IPv6)
- **Destination**: Load Balancer NSG
- **Port**: 80
- **Protocol**: TCP

#### HTTPS Traffic (Port 443)
```hcl
# Allow HTTPS from allowed CIDR blocks  
resource "oci_core_network_security_group_security_rule" "lb_https_ingress"
```
- **Source**: Configured CIDR blocks (IPv4/IPv6)
- **Destination**: Load Balancer NSG
- **Port**: 443
- **Protocol**: TCP

### 2. Load Balancer → Private Instances (Egress)

#### CIDR-Based Rules (Primary)
```hcl
# Load balancer egress to private subnet
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_cidr"
```
- **Source**: Load Balancer NSG
- **Destination**: Private subnet CIDR (10.0.2.0/24)
- **Ports**: Application ports (8080, 8888)
- **Protocol**: TCP

#### NSG-to-NSG Rules (Enhanced Security)
```hcl
# Load balancer egress to private compute NSG
resource "oci_core_network_security_group_security_rule" "lb_egress_to_private_nsg"
```
- **Source**: Load Balancer NSG
- **Destination**: Private Compute NSG
- **Ports**: Application ports (8080, 8888)
- **Protocol**: TCP

### 3. Private Instances ← Load Balancer (Ingress)

#### CIDR-Based Rules (Primary)
```hcl
# Allow application ports from load balancer subnet
resource "oci_core_network_security_group_security_rule" "private_app_ports_cidr"
```
- **Source**: Public subnet CIDR (10.0.1.0/24)
- **Destination**: Private Compute NSG
- **Ports**: Application ports (8080, 8888)
- **Protocol**: TCP

#### NSG-to-NSG Rules (Enhanced Security)
```hcl
# Allow application ports from load balancer NSG
resource "oci_core_network_security_group_security_rule" "private_app_ports_from_lb_nsg"
```
- **Source**: Load Balancer NSG
- **Destination**: Private Compute NSG
- **Ports**: Application ports (8080, 8888)
- **Protocol**: TCP

## 🎯 Application Ports

The following ports are configured for load balancer connectivity:

### Default Application Ports
- **8080**: Tomcat HTTP (primary backend port)
- **8888**: Management/monitoring port

### Configuration Location
```hcl
# In variables.tf
variable "app_ports" {
  description = "Application ports to allow from load balancer"
  type        = list(number)
  default     = [8080, 8888]
}
```

## 🔄 Traffic Flow

### HTTPS Request Flow
1. **Client** → **Load Balancer** (Port 443, HTTPS)
2. **Load Balancer** → **Private Instance** (Port 8080, HTTP)
3. **Private Instance** → **Load Balancer** (Response)
4. **Load Balancer** → **Client** (HTTPS Response)

### Health Check Flow
1. **Load Balancer** → **Private Instance** (Port 8080, HTTP GET /ords/)
2. **Private Instance** → **Load Balancer** (HTTP 200 OK)

## 🛡️ Security Features

### Dual Policy Approach
- **CIDR-based rules**: Broader compatibility, subnet-level security
- **NSG-to-NSG rules**: Enhanced security, instance-level control

### Benefits
- **Redundancy**: Multiple rules ensure connectivity
- **Flexibility**: Works with various OCI configurations
- **Security**: Least-privilege access principles
- **Monitoring**: Clear traffic flow for troubleshooting

## 🔍 Verification Commands

### Check NSG Rules
```bash
# List load balancer NSG rules
oci network nsg-security-rule list --nsg-id <LOAD_BALANCER_NSG_ID>

# List private compute NSG rules  
oci network nsg-security-rule list --nsg-id <PRIVATE_COMPUTE_NSG_ID>
```

### Test Connectivity
```bash
# From load balancer subnet to private instance
curl -v http://10.0.2.160:8080/ords/

# Health check endpoint
curl -v http://10.0.2.160:8080/ords/
```

### Check Load Balancer Backend Health
```bash
# Via OCI CLI
oci lb backend-health get --load-balancer-id <LB_ID> --backend-set-name tomcat_backend_set --backend-name <BACKEND_NAME>
```

## 🚨 Troubleshooting

### Backend Health Check Failures

#### Symptom
Load balancer shows backends as "UNHEALTHY"

#### Possible Causes
1. **NSG Rules Missing**: Application ports not allowed
2. **Tomcat Not Running**: Service not started on private instances
3. **Firewall Blocking**: OS-level firewall blocking ports
4. **Health Check Path**: Incorrect health check URL

#### Solutions
```bash
# 1. Verify NSG rules exist
terraform plan | grep -A 10 "private_app_ports"

# 2. Check Tomcat status on private instances
ansible private_instances -i inventory/hosts.ini -m shell -a "systemctl status tomcat"

# 3. Check OS firewall
ansible private_instances -i inventory/hosts.ini -m shell -a "firewall-cmd --list-all"

# 4. Test health check endpoint
ansible private_instances -i inventory/hosts.ini -m shell -a "curl -v http://localhost:8080/ords/"
```

### Connection Timeouts

#### Symptom
Load balancer returns 502 Bad Gateway or timeouts

#### Possible Causes
1. **Route Table Issues**: Private instances can't reach internet
2. **Security List Conflicts**: Subnet-level rules blocking traffic
3. **Instance Performance**: High CPU/memory usage

#### Solutions
```bash
# 1. Check route tables
oci network route-table get --rt-id <PRIVATE_ROUTE_TABLE_ID>

# 2. Verify security lists
oci network security-list get --security-list-id <PRIVATE_SECURITY_LIST_ID>

# 3. Check instance metrics in OCI Console
```

## 📊 Monitoring

### Key Metrics
- **Backend Health**: Healthy/Unhealthy backend count
- **Response Time**: Average response time from backends
- **Connection Count**: Active connections to backends
- **Error Rate**: 4xx/5xx responses from backends

### Monitoring Tools
- **OCI Console**: Load Balancer metrics dashboard
- **OCI CLI**: Backend health status commands
- **Ansible**: Service status checks on private instances

## 🔧 Configuration Variables

### Network Configuration
```hcl
# Public subnet CIDR (where load balancer resides)
public_subnet_cidr = "10.0.1.0/24"

# Private subnet CIDR (where backends reside)  
private_subnet_cidr = "10.0.2.0/24"

# Application ports for load balancer connectivity
app_ports = [8080, 8888]
```

### Load Balancer Configuration
```hcl
# Backend health check settings
health_check_url_path = "/ords/"
health_check_return_code = 200
health_check_interval_ms = 30000
health_check_timeout_ms = 5000
health_check_retries = 3
```

## ✅ Validation Checklist

Before deployment, ensure:

- [ ] Load Balancer NSG has egress rules to private subnet/NSG
- [ ] Private Compute NSG has ingress rules from load balancer
- [ ] Application ports (8080, 8888) are configured correctly
- [ ] Health check endpoint (/ords/) is accessible
- [ ] Tomcat service is configured to start automatically
- [ ] OS firewall allows application ports
- [ ] Route tables allow proper traffic flow

## 🎉 Expected Results

After proper configuration:

✅ **Load Balancer Status**: Active  
✅ **Backend Health**: All backends healthy  
✅ **HTTPS Access**: `https://<LB_IP>/ords/r/marinedataregister` works  
✅ **Health Checks**: Passing consistently  
✅ **Response Time**: < 5 seconds average  
✅ **Error Rate**: < 1% 4xx/5xx responses  

The load balancer connectivity policies ensure secure, reliable communication between the load balancer and backend Tomcat instances! 🚀