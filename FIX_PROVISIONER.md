# Fix Ansible Provisioner Error

## Issue
The Terraform null_resource for Ansible provisioning is using an old cached command that references the outdated inventory script and SSH configuration.

## Root Cause
Terraform caches the provisioner commands in the state file. Even though we've updated the main.tf file, the old command is still being executed.

## Solution

### Step 1: Destroy the Cached Provisioner
```bash
# Destroy only the Ansible provisioning resource
terraform destroy -target=null_resource.ansible_provisioning

# Confirm destruction when prompted
```

### Step 2: Verify Latest Code
Make sure you're using the latest generate_inventory.sh script:

```bash
# Check the script exists and is executable
ls -la generate_inventory.sh

# Verify it uses the correct output names
grep -n "private_instance_private_ips" generate_inventory.sh
```

### Step 3: Disable Automatic Provisioning (Recommended)
Edit your `terraform.tfvars` file:

```hcl
# Disable automatic provisioning to avoid SSH issues
enable_ansible_provisioning = false
```

### Step 4: Re-apply Infrastructure
```bash
# Apply without Ansible provisioning
terraform apply
```

### Step 5: Run Ansible Manually
```bash
# Export SSH key path
export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"

# Generate inventory
./generate_inventory.sh

# Run Ansible manually
cd ansible
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v
```

## Alternative: Force Recreate Provisioner

If you want to keep automatic provisioning enabled:

```bash
# Taint the resource to force recreation
terraform taint null_resource.ansible_provisioning

# Apply to recreate with new command
terraform apply
```

## Why This Happened

1. **Terraform State Caching**: Provisioner commands are stored in the state file
2. **Code Updates**: We updated main.tf but the state still had the old command
3. **Output Name Changes**: The script now uses `private_instance_private_ips` (plural) instead of `private_instance_private_ip` (singular)

## Prevention

To avoid this in the future:
- Use manual Ansible provisioning (recommended)
- Always destroy/recreate null_resources when changing provisioner commands
- Use terraform taint when updating provisioner logic