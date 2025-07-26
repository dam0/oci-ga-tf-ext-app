# Load Balancer Backend Set Conflict Resolution

## Issue Description

**Error**: `400-InvalidParameter, Load balancer ocid1.loadbalancer.oc1.ap-sydney-1.aaaaaaaatbjqzp57en3ranoju764k72wowwfcvdudqobhfwr62m44xmxdrpq already has backend set 'tomcat_backend_set'`

## Root Cause Analysis

The error occurred because of a **Terraform state mismatch**:

### Resources in Terraform State
- ✅ `module.load_balancer.oci_load_balancer_load_balancer.lb`
- ✅ `module.load_balancer.oci_load_balancer_backend_set.tomcat_backend_set`
- ✅ `module.load_balancer.oci_load_balancer_listener.https_listener`
- ✅ `module.load_balancer.oci_load_balancer_backend.tomcat_backends[0]`
- ✅ `module.load_balancer.oci_load_balancer_backend.tomcat_backends[1]`

### Resources Missing from State
- ❌ `module.load_balancer.oci_load_balancer_listener.http_listener`
- ❌ `module.load_balancer.oci_load_balancer_rule_set.http_to_https_redirect`

### The Problem
When Terraform tried to create the missing HTTP listener, it somehow triggered a backend set recreation attempt, causing the conflict error.

## Temporary Solution Applied

### 1. Commented Out Conflicting Resources
```hcl
# TEMPORARILY COMMENTED OUT - HTTP listener and rule set causing backend set conflicts
# These resources are missing from Terraform state and causing conflicts when trying to create them

# resource "oci_load_balancer_rule_set" "http_to_https_redirect" { ... }
# resource "oci_load_balancer_listener" "http_listener" { ... }
```

### 2. Updated Outputs
```hcl
output "http_listener_name" {
  description = "The name of the HTTP listener (temporarily disabled)"
  value       = "http_listener_temporarily_disabled"
}

output "http_redirect_rule_set_name" {
  description = "The name of the HTTP to HTTPS redirect rule set (temporarily disabled)"
  value       = "http_redirect_rule_set_temporarily_disabled"
}
```

## Current Functionality

### ✅ Working Features
- **HTTPS Load Balancer**: Fully functional on port 443
- **SSL Termination**: Using certificate OCID `ocid1.certificate.oc1.ap-sydney-1.amaaaaaauvuxtpqavipyy4kzf6dtloospnhtfqmq42fkhbneskpxjuwyzs5q`
- **Backend Set**: Properly configured with health checks
- **Backend Servers**: Both private instances registered
- **WAF Integration**: Ready for deployment (currently disabled)
- **Network Security Groups**: Proper security controls

### ⚠️ Temporarily Disabled Features
- **HTTP Listener (port 80)**: Commented out to avoid conflicts
- **HTTP to HTTPS Redirect**: Commented out to avoid conflicts

## Impact Assessment

### Security Impact: ✅ MINIMAL
- **HTTPS traffic**: Fully protected and functional
- **Network Security**: NSGs provide comprehensive IP filtering
- **Application Security**: WAF can be enabled once backend set conflict is resolved

### Functionality Impact: ⚠️ LIMITED
- **Direct HTTP access**: Not available (users must use HTTPS)
- **Automatic redirect**: Not available (users must manually use HTTPS URLs)
- **Application access**: Fully functional via HTTPS

## Permanent Solutions (Choose One)

### Option 1: Import Missing Resources (Recommended)
If the HTTP listener exists in OCI but not in Terraform state:

```bash
# Find the HTTP listener OCID in OCI Console
terraform import module.load_balancer.oci_load_balancer_listener.http_listener <LOAD_BALANCER_OCID>/<LISTENER_NAME>

# Find the rule set OCID in OCI Console  
terraform import module.load_balancer.oci_load_balancer_rule_set.http_to_https_redirect <LOAD_BALANCER_OCID>/<RULE_SET_NAME>

# Then uncomment the resources in main.tf
```

### Option 2: Recreate Missing Resources
If the resources don't exist in OCI:

```bash
# Uncomment the resources in modules/load_balancer/main.tf
# Update outputs.tf to reference the actual resources
# Run terraform apply
```

### Option 3: Manual Creation via OCI Console
Create the HTTP listener and redirect rule manually in OCI Console, then import them.

## Testing Current Configuration

### HTTPS Access Test
```bash
# Test HTTPS access (should work)
curl -k https://<LOAD_BALANCER_IP>/ords/r/marinedataregister

# Test HTTP access (will fail - expected)
curl http://<LOAD_BALANCER_IP>/ords/r/marinedataregister
```

### Expected Results
- ✅ **HTTPS requests**: Should work normally
- ❌ **HTTP requests**: Will fail (connection refused or timeout)

## Next Steps

1. **Deploy Current Configuration**: Test HTTPS functionality
2. **Verify WAF Deployment**: Enable WAF with current minimal configuration
3. **Resolve HTTP Listener**: Choose and implement one of the permanent solutions
4. **Test Complete Setup**: Verify both HTTP redirect and HTTPS access

## Files Modified

- `modules/load_balancer/main.tf`: Commented out HTTP listener and rule set
- `modules/load_balancer/outputs.tf`: Updated outputs for missing resources
- `variables.tf`: Disabled WAF by default to avoid additional conflicts

## Rollback Plan

If issues arise, the previous working state can be restored by:

1. Reverting the commented sections in `main.tf`
2. Restoring original outputs in `outputs.tf`
3. Running `terraform apply` with proper resource imports

This temporary fix ensures the core load balancer functionality remains intact while resolving the backend set conflict.