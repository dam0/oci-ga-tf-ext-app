# 🔧 Ansible Provisioning Troubleshooting

## Current Issue: "Output 'private_instance_private_ip' not found"

### Root Cause
The error indicates that your local `generate_inventory.sh` script is still looking for the old output name `private_instance_private_ip` (singular) instead of the new name `private_instance_private_ips` (plural).

## 🎯 IMMEDIATE SOLUTION

### Option 1: Use the Fixed Script (Recommended)
```bash
# Set your SSH key path
export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"

# Use the comprehensive fix script
./fix_and_run_ansible.sh
```

### Option 2: Debug First, Then Fix
```bash
# 1. Debug what outputs are available
./debug_outputs.sh

# 2. If outputs look correct, run the fix script
./fix_and_run_ansible.sh
```

### Option 3: Manual Steps
```bash
# 1. Check your current script version
head -20 generate_inventory.sh

# 2. Look for this line (should be line 12):
# PRIVATE_IPS_JSON=$(terraform output -json private_instance_private_ips)

# 3. If it shows the old name, pull the latest code:
git pull origin oci-terraform-ansible

# 4. Run the updated script
export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"
./generate_inventory.sh
```

## 🔍 Diagnostic Commands

### Check Terraform Outputs
```bash
# List all outputs
terraform output

# Check specific outputs
terraform output bastion_public_ip
terraform output private_instance_private_ips
```

### Check Script Version
```bash
# Look for the correct output name in the script
grep "private_instance_private_ips" generate_inventory.sh

# Should return line 12 with the correct plural name
```

### Test SSH Connectivity
```bash
# Test bastion connection
ssh -i /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem opc@<BASTION_IP>

# Test private instance via bastion
ssh -i /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem -o ProxyCommand="ssh -W %h:%p -i /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem opc@<BASTION_IP>" opc@<PRIVATE_IP>
```

## 🚨 Common Issues and Fixes

### Issue 1: "Host key verification failed"
```bash
# Add bastion to known_hosts
ssh-keyscan -H <BASTION_IP> >> ~/.ssh/known_hosts

# Or disable strict checking (less secure)
export ANSIBLE_HOST_KEY_CHECKING=False
```

### Issue 2: "Permission denied (publickey)"
```bash
# Check key permissions
chmod 600 /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem

# Verify key is correct
ssh-keygen -l -f /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem
```

### Issue 3: "Connection refused"
```bash
# Check if instances are running
# In OCI Console: Compute > Instances > Check status

# Check security groups allow SSH
# In OCI Console: Networking > Network Security Groups
```

### Issue 4: Old script version
```bash
# Pull latest changes
git pull origin oci-terraform-ansible

# Verify script is updated
grep -n "private_instance_private_ips" generate_inventory.sh
```

## 📋 What the Fix Script Does

1. **Validates Environment**: Checks SSH key path and Terraform state
2. **Debugs Outputs**: Shows all available Terraform outputs
3. **Handles SSH Keys**: Adds bastion to known_hosts automatically
4. **Generates Inventory**: Creates proper Ansible inventory with correct IPs
5. **Tests Connectivity**: Verifies SSH connections before running playbook
6. **Runs Ansible**: Executes the provisioning playbook with proper error handling

## 🎯 Expected Results

After running the fix script successfully:

```
✅ SSH key path: /Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem
✅ Terraform state found
✅ Bastion IP: 159.13.46.200
✅ Found 2 private instance(s)
✅ Bastion added to known_hosts
✅ Inventory generated at ansible/inventory/hosts.ini
✅ Bastion connectivity OK
✅ Private instances connectivity OK
🚀 Running Ansible provisioning...
```

## 🆘 If All Else Fails

1. **Check Git Status**: Make sure you have the latest code
   ```bash
   git status
   git pull origin oci-terraform-ansible
   ```

2. **Recreate Infrastructure**: If outputs are missing
   ```bash
   terraform destroy
   terraform apply
   ```

3. **Manual Inventory**: Create inventory manually
   ```bash
   # Get IPs from OCI Console and create inventory/hosts.ini manually
   ```

4. **Contact Support**: Share the output of:
   ```bash
   terraform output
   cat generate_inventory.sh | head -20
   ```

The fix script should resolve your issue automatically! 🚀