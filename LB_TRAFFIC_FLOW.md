# 🔄 Load Balancer Traffic Flow & Required Rules

## Visual Traffic Flow

```
┌─────────────────┐    HTTPS/443     ┌──────────────────┐    HTTP/8080    ┌─────────────────┐
│                 │ ──────────────► │                  │ ─────────────► │                 │
│   Internet      │                 │  Load Balancer   │                │ Private Instance│
│   Client        │ ◄────────────── │  (Public Subnet) │ ◄───────────── │ (Private Subnet)│
│                 │    HTTPS/443     │                  │    HTTP/8080    │                 │
└─────────────────┘                 └──────────────────┘                └─────────────────┘
                                           │                                       │
                                           │                                       │
                                    ┌──────▼──────┐                        ┌──────▼──────┐
                                    │Load Balancer│                        │Private Compute│
                                    │     NSG     │                        │     NSG     │
                                    │             │                        │             │
                                    │EGRESS Rules │                        │INGRESS Rules│
                                    │Port: 8080   │                        │Port: 8080   │
                                    │Dest: Private│                        │Src: Public  │
                                    │Subnet/NSG   │                        │Subnet/NSG   │
                                    └─────────────┘                        └─────────────┘
```

## 🎯 Required Rules Breakdown

### Rule Set 1: Load Balancer → Backend (EGRESS)

```
┌─────────────────────────────────────────────────────────────────┐
│ Load Balancer NSG - EGRESS RULES                               │
├─────────────────────────────────────────────────────────────────┤
│ Rule 1: LB → Private Subnet (CIDR-based)                       │
│   Direction: EGRESS                                             │
│   Protocol: TCP (6)                                             │
│   Source: Load Balancer NSG                                     │
│   Destination: 10.0.2.0/24 (Private Subnet)                    │
│   Port: 8080                                                    │
│   Purpose: Allow LB to send requests to Tomcat                 │
├─────────────────────────────────────────────────────────────────┤
│ Rule 2: LB → Private NSG (NSG-to-NSG)                          │
│   Direction: EGRESS                                             │
│   Protocol: TCP (6)                                             │
│   Source: Load Balancer NSG                                     │
│   Destination: Private Compute NSG                              │
│   Port: 8080                                                    │
│   Purpose: Enhanced security with NSG-to-NSG communication     │
└─────────────────────────────────────────────────────────────────┘
```

### Rule Set 2: Backend ← Load Balancer (INGRESS)

```
┌─────────────────────────────────────────────────────────────────┐
│ Private Compute NSG - INGRESS RULES                            │
├─────────────────────────────────────────────────────────────────┤
│ Rule 1: Private Subnet ← LB Subnet (CIDR-based)                │
│   Direction: INGRESS                                            │
│   Protocol: TCP (6)                                             │
│   Source: 10.0.1.0/24 (Public Subnet)                          │
│   Destination: Private Compute NSG                              │
│   Port: 8080                                                    │
│   Purpose: Allow Tomcat to receive requests from LB            │
├─────────────────────────────────────────────────────────────────┤
│ Rule 2: Private NSG ← LB NSG (NSG-to-NSG)                      │
│   Direction: INGRESS                                            │
│   Protocol: TCP (6)                                             │
│   Source: Load Balancer NSG                                     │
│   Destination: Private Compute NSG                              │
│   Port: 8080                                                    │
│   Purpose: Enhanced security with NSG-to-NSG communication     │
└─────────────────────────────────────────────────────────────────┘
```

## 🔍 Health Check Flow

```
Load Balancer Health Check Process:
┌─────────────────┐
│ Load Balancer   │
│ Health Checker  │
└─────────┬───────┘
          │ HTTP GET /ords/
          │ Port: 8080
          │ Interval: 30s
          │ Timeout: 5s
          ▼
┌─────────────────┐
│ Private Instance│
│ Tomcat Server   │
│ Port: 8080      │
└─────────┬───────┘
          │ HTTP 200 OK
          │ Response Body
          ▼
┌─────────────────┐
│ Load Balancer   │
│ Backend Status: │
│ ✅ HEALTHY      │
└─────────────────┘
```

## 📋 Rule Implementation Status

### ✅ Currently Implemented Rules

Your configuration already includes **ALL required rules**:

#### 1. Load Balancer Egress Rules
- ✅ **CIDR-based**: `lb_egress_to_private_cidr` (lines 383-401)
- ✅ **NSG-to-NSG**: `lb_egress_to_private_nsg` (lines 404-422)

#### 2. Private Compute Ingress Rules  
- ✅ **CIDR-based**: `private_app_ports_cidr` (lines 279-297)
- ✅ **NSG-to-NSG**: `private_app_ports_from_lb_nsg` (lines 300-318)

#### 3. Port Configuration
- ✅ **Port 8080**: Tomcat HTTP (primary)
- ✅ **Port 8888**: Management (optional)
- ✅ **Configurable**: Via `var.app_ports` variable

## 🎯 Minimum Required Rules (Simplified)

If you only need the **absolute minimum** rules for basic connectivity:

### Rule 1: Load Balancer Egress
```hcl
# Allow load balancer to reach backend on port 8080
resource "oci_core_network_security_group_security_rule" "lb_to_backend" {
  network_security_group_id = var.load_balancer_nsg_id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "10.0.2.0/24"  # Private subnet
  destination_type         = "CIDR_BLOCK"
  
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
}
```

### Rule 2: Backend Ingress
```hcl
# Allow backend to receive traffic from load balancer on port 8080
resource "oci_core_network_security_group_security_rule" "backend_from_lb" {
  network_security_group_id = var.private_compute_nsg_id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "10.0.1.0/24"  # Public subnet
  source_type              = "CIDR_BLOCK"
  
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
}
```

## 🚀 Deployment Commands

### Apply the Rules
```bash
# Deploy all NSG rules
terraform apply

# Verify rules are created
terraform show | grep -A 10 "network_security_group_security_rule"
```

### Test Connectivity
```bash
# Validate load balancer connectivity
./validate_lb_connectivity.sh

# Test backend health
curl -v http://<PRIVATE_IP>:8080/ords/
```

## 🎉 Summary

### **Your Load Balancer Connectivity is COMPLETE! ✅**

**Required Rules**: ✅ All implemented  
**Security**: ✅ Dual approach (CIDR + NSG-to-NSG)  
**Ports**: ✅ 8080 (Tomcat) + 8888 (Management)  
**Health Checks**: ✅ Configured for /ords/ endpoint  
**Documentation**: ✅ Complete with troubleshooting  

### **Traffic Flow**: Internet → LB (443/HTTPS) → Backend (8080/HTTP) → Response

The rulesets are **production-ready** and will allow your load balancer to successfully reach the backend set! 🎯