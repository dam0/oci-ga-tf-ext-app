# Manual Ansible Provisioning Guide

## Overview

Ansible provisioning is **disabled by default** in the Terraform configuration to avoid connectivity issues during infrastructure deployment. This guide provides step-by-step instructions for running Ansible provisioning manually after Terraform completes.

## Why Manual Provisioning?

### Advantages
- **Reliability**: Avoids SSH connectivity issues during Terraform apply
- **Debugging**: Easier to troubleshoot Ansible issues separately
- **Flexibility**: Can run provisioning multiple times or selectively
- **Environment Independence**: Works regardless of where Terraform runs

### When to Use
- **Always recommended** for production deployments
- When running Terraform from CI/CD pipelines
- When SSH keys or network access might be limited during Terraform execution

## Prerequisites

### 1. Completed Terraform Deployment
```bash
terraform apply
# Wait for successful completion
```

### 2. Required Tools
```bash
# Install Ansible (if not already installed)
pip install ansible

# Verify installation
ansible --version
```

### 3. SSH Key Access
Ensure you have access to the SSH private key specified in your Terraform configuration:
```bash
# Verify key exists and has correct permissions
ls -la ~/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem
chmod 600 ~/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem
```

## Step-by-Step Provisioning

### Step 1: Generate Ansible Inventory
```bash
cd /path/to/oci-terraform-ansible

# Export SSH key path
export SSH_PRIVATE_KEY_PATH="/Users/damo/.ssh/oci/ga-ops-2025-06-30T03_52_32.238Z.pem"

# Generate inventory from Terraform outputs
./generate_inventory.sh
```

**Expected Output:**
```
Generating Ansible inventory from Terraform outputs...
Found 2 private instance(s)
Bastion IP: 159.13.46.200
Adding private_instance_1 with IP 10.0.2.160
Adding private_instance_2 with IP 10.0.2.53
Ansible inventory file generated at ansible/inventory/hosts.ini
```

### Step 2: Verify Connectivity
```bash
cd ansible

# Test bastion connectivity
ansible bastion -i inventory/hosts.ini -m ping

# Test private instances connectivity
ansible private_instances -i inventory/hosts.ini -m ping
```

**Expected Output:**
```
bastion | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
private_instance_1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
private_instance_2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Step 3: Run Full Provisioning
```bash
cd ansible

# Run complete provisioning playbook
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances -v
```

### Step 4: Verify Installation
```bash
# Test individual components
ansible-playbook -i inventory/hosts.ini test-apex.yml -v
ansible-playbook -i inventory/hosts.ini test-firewall.yml -v
```

## Troubleshooting

### SSH Connection Issues

#### Problem: "Connection refused" or "Host unreachable"
```bash
# Check bastion connectivity
ssh -i /path/to/key opc@<BASTION_IP>

# Check private instance via bastion
ssh -i /path/to/key -o ProxyCommand="ssh -W %h:%p -i /path/to/key opc@<BASTION_IP>" opc@<PRIVATE_IP>
```

#### Problem: "Permission denied (publickey)"
```bash
# Verify key permissions
chmod 600 /path/to/private/key

# Check if key is correct
ssh-keygen -l -f /path/to/private/key
```

#### Problem: "Host key verification failed"
```bash
# Add to known_hosts or disable strict checking
ssh-keyscan <BASTION_IP> >> ~/.ssh/known_hosts

# Or use StrictHostKeyChecking=no (less secure)
```

### Ansible Playbook Issues

#### Problem: Task failures
```bash
# Run with increased verbosity
ansible-playbook -i inventory/hosts.ini provision.yml -vvv

# Run specific roles only
ansible-playbook -i inventory/hosts.ini provision.yml --tags "java,tomcat"

# Skip problematic tasks
ansible-playbook -i inventory/hosts.ini provision.yml --skip-tags "apex"
```

#### Problem: Inventory issues
```bash
# Verify inventory syntax
ansible-inventory -i inventory/hosts.ini --list

# Test specific groups
ansible private_instances -i inventory/hosts.ini --list-hosts
```

## Selective Provisioning

### Run Specific Roles
```bash
# Install only Java and Tomcat
ansible-playbook -i inventory/hosts.ini provision.yml --tags "java,tomcat"

# Install only APEX components
ansible-playbook -i inventory/hosts.ini provision.yml --tags "apex,ords"

# Configure only firewall
ansible-playbook -i inventory/hosts.ini provision.yml --tags "firewall"
```

### Target Specific Instances
```bash
# Provision only first instance
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instance_1

# Provision only second instance
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instance_2
```

## What Gets Installed

### Java Environment
- **OpenJDK 11**: Latest stable version
- **Java alternatives**: Properly configured
- **Environment variables**: JAVA_HOME, PATH

### Apache Tomcat 9
- **Installation**: `/opt/tomcat`
- **Service**: `systemctl status tomcat`
- **Ports**: 8080 (HTTP), 8443 (HTTPS), 8009 (AJP)
- **Manager app**: Configured with admin user

### Oracle APEX 24.1
- **Location**: `/opt/tomcat/webapps/ords/i/apex_ui/`
- **Images**: Complete APEX static files
- **Integration**: Configured with Tomcat

### Oracle REST Data Services (ORDS)
- **WAR file**: Deployed to Tomcat
- **Configuration**: Ready for database connection
- **URL**: `http://<instance>:8080/ords/`

### SQL*Plus and SQLcl
- **SQL*Plus**: Oracle database client
- **SQLcl**: Modern command-line interface
- **Path**: Added to system PATH

### Firewall Configuration
- **SSH (22)**: Allowed from bastion
- **HTTP (8080)**: Allowed from load balancer
- **HTTPS (8443)**: Allowed from load balancer
- **Management (8888)**: Allowed from load balancer

## Post-Provisioning Verification

### 1. Service Status
```bash
# Check all services on private instances
ansible private_instances -i inventory/hosts.ini -m shell -a "systemctl status tomcat"
```

### 2. Application Access
```bash
# Test Tomcat manager (from bastion)
curl http://10.0.2.160:8080/manager/html

# Test APEX static files
curl http://10.0.2.160:8080/ords/i/apex_ui/css/Core.css
```

### 3. Load Balancer Integration
```bash
# Test via load balancer (replace with actual LB IP)
curl -k https://<LOAD_BALANCER_IP>/ords/r/marinedataregister
```

## Re-running Provisioning

### Safe to Re-run
Ansible playbooks are **idempotent** - safe to run multiple times:

```bash
# Re-run complete provisioning
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances

# Update only specific components
ansible-playbook -i inventory/hosts.ini provision.yml --tags "apex" --limit private_instances
```

### Force Reinstallation
```bash
# Force reinstall Java
ansible-playbook -i inventory/hosts.ini provision.yml --tags "java" --extra-vars "force_reinstall=true"
```

## Integration with Terraform

### Enable Automatic Provisioning (Optional)
If you want Terraform to run Ansible automatically:

```hcl
# In terraform.tfvars or variables
enable_ansible_provisioning = true
```

Then run:
```bash
terraform apply
```

### Disable Automatic Provisioning (Default)
```hcl
# In terraform.tfvars or variables
enable_ansible_provisioning = false
```

## Next Steps

After successful provisioning:

1. **Configure Database Connection**: Update ORDS configuration
2. **Deploy APEX Applications**: Import your applications
3. **Configure SSL**: Set up HTTPS certificates for Tomcat
4. **Monitor Services**: Set up monitoring and alerting
5. **Backup Configuration**: Create system backups

## Support

### Log Locations
- **Ansible logs**: Console output during playbook run
- **Tomcat logs**: `/opt/tomcat/logs/`
- **System logs**: `/var/log/messages`, `journalctl -u tomcat`

### Common Commands
```bash
# Check Tomcat status
sudo systemctl status tomcat

# Restart Tomcat
sudo systemctl restart tomcat

# View Tomcat logs
sudo tail -f /opt/tomcat/logs/catalina.out

# Check firewall status
sudo firewall-cmd --list-all
```

This manual approach provides better control and reliability for production deployments! 🚀