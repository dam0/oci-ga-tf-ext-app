# Ansible Provisioning Fix - Inventory Generation Error Resolution

## Issue Resolved ✅

**Error**: `Output "private_instance_private_ip" not found`

**Root Cause**: The `generate_inventory.sh` script was trying to access Terraform outputs using singular names, but the modular configuration uses plural array outputs.

## What Was Fixed

### 1. Updated Terraform Output References
**Before** (Singular - Incorrect):
```bash
PRIVATE_INSTANCE_IP=$(terraform output -raw private_instance_private_ip)
SECOND_PRIVATE_INSTANCE_IP=$(terraform output -raw second_private_instance_private_ip)
```

**After** (Plural Array - Correct):
```bash
PRIVATE_INSTANCE_IPS=$(terraform output -json private_instance_private_ips)
FIRST_PRIVATE_IP=$(echo $PRIVATE_INSTANCE_IPS | jq -r '.[0]')
SECOND_PRIVATE_IP=$(echo $PRIVATE_INSTANCE_IPS | jq -r '.[1] // empty')
```

### 2. Improved Instance Detection
- **Automatic Detection**: Script now automatically detects if a second instance exists
- **JSON Parsing**: Uses `jq` to properly parse array outputs from Terraform
- **Null Handling**: Properly handles cases where only one instance exists

### 3. Updated Inventory Structure
**Generated Inventory** (`ansible/inventory/hosts.ini`):
```ini
[bastion]
bastion ansible_host=159.13.46.200 ansible_user=opc

[private_instances]
private_instance_1 ansible_host=10.0.2.160 ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i /path/to/key.pem -o StrictHostKeyChecking=no opc@159.13.46.200"'
private_instance_2 ansible_host=10.0.2.53 ansible_user=opc ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -i /path/to/key.pem -o StrictHostKeyChecking=no opc@159.13.46.200"'

[all:vars]
ansible_ssh_private_key_file=/path/to/key.pem
bastion_public_ip=159.13.46.200
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 4. Simplified Terraform Provisioner
**Updated** `main.tf` provisioner:
```hcl
provisioner "local-exec" {
  command = <<-EOT
    # Wait for instances to be fully initialized
    sleep 120

    # Export SSH key path for inventory generation
    export SSH_PRIVATE_KEY_PATH=${var.private_key_path}

    # Generate Ansible inventory
    ./generate_inventory.sh

    # Run Ansible playbook with proper SSH configuration
    cd ansible && ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v
  EOT
}
```

## Testing Results ✅

### Terraform Outputs Available
```bash
$ terraform output bastion_public_ip
"159.13.46.200"

$ terraform output private_instance_private_ips
[
  "10.0.2.160",
  "10.0.2.53",
]
```

### Inventory Generation Working
```bash
$ ./generate_inventory.sh
Generating Ansible inventory from Terraform outputs...
Found 2 private instance(s)
Bastion IP: 159.13.46.200
Adding private_instance_1 with IP 10.0.2.160
Adding private_instance_2 with IP 10.0.2.53
Ansible inventory file generated at ansible/inventory/hosts.ini
```

### SSH Connectivity Ready
- ✅ **Bastion Host**: Direct SSH access via public IP
- ✅ **Private Instances**: SSH access via bastion proxy
- ✅ **SSH Keys**: Proper key path configuration
- ✅ **Proxy Commands**: Correctly formatted for Ansible

## Ansible Playbook Structure

### Roles Applied to Private Instances
1. **common**: Basic system setup and packages
2. **firewall**: Configure firewall rules (ports 22, 8080, 8888)
3. **java**: Install and configure Java 11
4. **tomcat**: Install and configure Tomcat 9
5. **apex**: Deploy APEX 24.1 images and configuration
6. **sqlcl**: Install Oracle SQLcl for database operations
7. **ords**: Configure Oracle REST Data Services

### Expected Deployment Results
After successful Ansible provisioning:
- ✅ **Tomcat 9**: Running on port 8080
- ✅ **APEX 24.1**: Images deployed to `/opt/tomcat/webapps/ords/i/apex_ui/`
- ✅ **ORDS**: Configured for database connectivity
- ✅ **Firewall**: Ports 22, 8080, 8888 open
- ✅ **Load Balancer**: Backend health checks passing

## Next Steps

### 1. Deploy Infrastructure (If Not Already Done)
```bash
cd /workspace/oci-terraform-ansible
terraform apply
```

### 2. Manual Ansible Run (If Provisioner Failed)
If the Terraform provisioner fails, you can run Ansible manually:
```bash
cd /workspace/oci-terraform-ansible

# Generate inventory
export SSH_PRIVATE_KEY_PATH=/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem
./generate_inventory.sh

# Run Ansible playbook
cd ansible
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v
```

### 3. Test APEX Application
After Ansible completes:
```bash
# Test Tomcat directly on private instances (via bastion)
ssh -J opc@159.13.46.200 opc@10.0.2.160 "curl -I http://localhost:8080/"

# Test via load balancer (HTTPS)
curl -k https://<LOAD_BALANCER_IP>/ords/r/marinedataregister
```

### 4. Verify Load Balancer Health Checks
- **Health Check URL**: `http://<BACKEND_IP>:8080/`
- **Expected Response**: HTTP 200 OK
- **Check Interval**: 30 seconds
- **Timeout**: 5 seconds

## Troubleshooting

### Common Issues and Solutions

1. **SSH Connection Failures**
   ```bash
   # Test bastion connectivity
   ssh -i /path/to/key.pem opc@159.13.46.200
   
   # Test private instance connectivity
   ssh -J opc@159.13.46.200 -i /path/to/key.pem opc@10.0.2.160
   ```

2. **Ansible Playbook Failures**
   ```bash
   # Run with increased verbosity
   ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -vvv
   
   # Test connectivity only
   ansible -i inventory/hosts.ini private_instances -m ping
   ```

3. **Tomcat Service Issues**
   ```bash
   # Check Tomcat status on private instances
   ssh -J opc@159.13.46.200 opc@10.0.2.160 "sudo systemctl status tomcat"
   
   # Check Tomcat logs
   ssh -J opc@159.13.46.200 opc@10.0.2.160 "sudo journalctl -u tomcat -f"
   ```

4. **APEX Images Missing**
   ```bash
   # Verify APEX images deployment
   ssh -J opc@159.13.46.200 opc@10.0.2.160 "ls -la /opt/tomcat/webapps/ords/i/apex_ui/"
   ```

## Files Modified

- ✅ `generate_inventory.sh`: Updated for modular Terraform outputs
- ✅ `main.tf`: Simplified Ansible provisioner command
- ✅ `ansible/inventory/hosts.ini`: Generated with correct structure

## Dependencies

- **jq**: JSON parsing utility (available in environment)
- **ansible**: Ansible automation platform
- **ssh**: SSH client with proxy command support
- **terraform**: For output retrieval

## Security Configuration

### SSH Security
- **Key-based Authentication**: No password authentication
- **Bastion Host**: All private instance access via bastion
- **StrictHostKeyChecking**: Disabled for automation (can be enabled for production)

### Network Security
- **Private Instances**: No direct internet access
- **Load Balancer**: Only HTTPS (443) exposed to internet
- **NSG Rules**: Granular security group controls

The Ansible provisioning is now ready for deployment! 🚀