# OCI Terraform with Ansible Provisioning - Modular Architecture

This repository provides a modular Terraform configuration for provisioning Oracle Cloud Infrastructure (OCI) resources with Ansible-based software provisioning. The modular approach makes the configuration more maintainable, reusable, and scalable.

## Architecture Overview

The infrastructure consists of:

- **Network Module**: VCN, public/private subnets, gateways, and security groups
- **Bastion Module**: Jump server in public subnet with optional reserved private IP
- **Private Compute Module**: Private instances with reserved private IPs that can be detached and reused
- **Ansible Integration**: Automated software provisioning using Ansible playbooks

### Network Architecture

```
Internet Gateway
       |
   Public Subnet (10.0.1.0/24)
       |
   Bastion Host
       |
   NAT Gateway
       |
   Private Subnet (10.0.2.0/24)
       |
   Private Instances
```

## Module Structure

```
modules/
├── network/
│   ├── main.tf          # Network resources (VCN, subnets, gateways, security)
│   ├── variables.tf     # Network module variables
│   └── outputs.tf       # Network module outputs
├── bastion/
│   ├── main.tf          # Bastion host with reserved IP
│   ├── variables.tf     # Bastion module variables
│   └── outputs.tf       # Bastion module outputs
└── private_compute/
    ├── main.tf          # Private instances with reserved IPs
    ├── variables.tf     # Private compute module variables
    └── outputs.tf       # Private compute module outputs
```

## Features

### Modular Design
- **Reusable Components**: Each module can be used independently
- **Configurable**: Extensive variable support for customization
- **Scalable**: Easy to add more instances or modify configurations

### Network Security
- Public subnet with Internet Gateway access for bastion
- Private subnet with NAT Gateway for outbound access only
- Security groups with minimal required access
- Application ports (8080, 8443, 9090) configurable

### Reserved Private IPs
- Each instance has a reserved private IP that can be detached
- IPs can be reused when instances are recreated
- Proper lifecycle management to prevent IP conflicts

### Ansible Integration
- Automated software installation and configuration
- Java 11, Tomcat 9, Oracle SQLCL, and ORDS installation
- Uses bastion as jump host for private instance access

## Prerequisites

1. **OCI Account**: Active Oracle Cloud Infrastructure account
2. **OCI CLI**: Configured with appropriate credentials
3. **Terraform**: Version 1.0 or later
4. **Ansible**: Version 2.9 or later
5. **SSH Key Pair**: For instance access

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd oci-terraform-ansible
```

### 2. Configure Variables

Copy and customize the example variables file:

```bash
cp terraform-modular.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your OCI configuration:

```hcl
# Required OCI Configuration
tenancy_ocid     = "ocid1.tenancy.oc1..your-tenancy-id"
user_ocid        = "ocid1.user.oc1..your-user-id"
fingerprint      = "your-key-fingerprint"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-ashburn-1"
compartment_id   = "ocid1.compartment.oc1..your-compartment-id"
availability_domain = "Uocm:US-ASHBURN-AD-1"

# Instance Configuration
instance_image_ocid = "ocid1.image.oc1.us-ashburn-1.your-image-id"
ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-public-key"

# Customize as needed
private_instance_count = 2
enable_ansible_provisioning = true
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="terraform.tfvars"

# Apply the configuration
terraform apply -var-file="terraform.tfvars"
```

### 4. Access Instances

After deployment, use the provided SSH commands:

```bash
# Connect to bastion
ssh -i ~/.ssh/your-key opc@<bastion-public-ip>

# Connect to private instances through bastion
ssh -i ~/.ssh/your-key -o ProxyCommand='ssh -W %h:%p -i ~/.ssh/your-key opc@<bastion-public-ip>' opc@<private-instance-ip>
```

## Module Configuration

### Network Module

The network module creates the foundational networking components:

```hcl
module "network" {
  source = "./modules/network"

  compartment_id        = var.compartment_id
  vcn_cidr             = "10.0.0.0/16"
  public_subnet_cidr   = "10.0.1.0/24"
  private_subnet_cidr  = "10.0.2.0/24"
  name_prefix          = "my-project"
  allow_http           = false
  allow_https          = false
  app_ports            = [8080, 8443, 9090]
}
```

### Bastion Module

The bastion module creates a jump server with optional reserved IP:

```hcl
module "bastion" {
  source = "./modules/bastion"

  compartment_id         = var.compartment_id
  availability_domain    = var.availability_domain
  public_subnet_id       = module.network.public_subnet_id
  instance_shape         = "VM.Standard.E4.Flex"
  instance_shape_config  = {
    memory_in_gbs = 16
    ocpus         = 1
  }
  create_reserved_ip     = true
  reserved_ip_address    = "10.0.1.10"  # Optional specific IP
}
```

### Private Compute Module

The private compute module creates multiple private instances:

```hcl
module "private_compute" {
  source = "./modules/private_compute"

  compartment_id         = var.compartment_id
  availability_domain    = var.availability_domain
  private_subnet_id      = module.network.private_subnet_id
  private_subnet_cidr    = module.network.private_subnet_cidr
  instance_count         = 3
  instance_shape         = "VM.Standard.E4.Flex"
  instance_shape_config  = {
    memory_in_gbs = 32
    ocpus         = 4
  }
  create_reserved_ips    = true
  reserved_ip_addresses  = ["10.0.2.10", "10.0.2.11", "10.0.2.12"]
}
```

## Ansible Provisioning

The Ansible playbooks automatically install and configure:

- **Java 11**: OpenJDK runtime environment
- **Tomcat 9**: Application server on private instances
- **Oracle SQLCL**: SQL command line tool
- **Oracle ORDS**: REST Data Services on private instances

### Ansible Structure

```
ansible/
├── provision.yml        # Main playbook
├── inventory/
│   └── hosts.ini       # Generated inventory
├── group_vars/
│   └── all.yml         # Global variables
└── roles/
    ├── common/         # Common setup tasks
    ├── java/           # Java installation
    ├── tomcat/         # Tomcat setup
    ├── sqlcl/          # SQLCL installation
    └── ords/           # ORDS configuration
```

### Manual Ansible Execution

If you need to run Ansible separately:

```bash
# Generate inventory from Terraform outputs
./generate_inventory.sh

# Run specific roles
cd ansible
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances --tags java
ansible-playbook -i inventory/hosts.ini provision.yml --limit private_instances --tags tomcat
```

## Customization

### Adding More Instances

Increase the instance count in your variables:

```hcl
private_instance_count = 5
```

### Custom Instance Shapes

Modify the shape configuration:

```hcl
private_instance_shape_config = {
  memory_in_gbs = 64
  ocpus         = 8
}
```

### Additional Application Ports

Add more ports to the security configuration:

```hcl
app_ports = [8080, 8443, 9090, 3000, 5432]
```

### Custom User Data

Add initialization scripts:

```hcl
private_instance_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y htop
EOF
```

## Advanced Features

### Reserved IP Management

Reserved IPs can be detached and reused:

```bash
# List reserved IPs
oci network private-ip list --subnet-id <subnet-id>

# Detach IP from instance
oci network private-ip update --private-ip-id <ip-id> --vnic-id null

# Attach IP to new instance
oci network private-ip update --private-ip-id <ip-id> --vnic-id <new-vnic-id>
```

### Multi-Environment Support

Use different variable files for different environments:

```bash
# Development
terraform apply -var-file="dev.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

### Tagging Strategy

Implement consistent tagging:

```hcl
freeform_tags = {
  "Environment" = "production"
  "Project"     = "web-application"
  "Owner"       = "team-alpha"
  "CostCenter"  = "engineering"
}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify OCI CLI configuration: `oci iam user get --user-id <user-id>`
   - Check private key permissions: `chmod 600 ~/.oci/oci_api_key.pem`

2. **Terraform State Issues**
   - Use remote state for team collaboration
   - Lock state during operations: `terraform apply -lock=true`

3. **Ansible Connection Issues**
   - Verify SSH key permissions: `chmod 600 ~/.ssh/your-key`
   - Test bastion connectivity first
   - Check security group rules

4. **Instance Launch Failures**
   - Verify availability domain has capacity
   - Check service limits in OCI console
   - Ensure image OCID is correct for the region

### Debugging

Enable detailed logging:

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform apply

# Ansible debugging
ansible-playbook -vvv provision.yml
```

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="terraform.tfvars"
```

**Note**: Reserved IPs will be properly detached before VNICs are destroyed.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review OCI documentation

## Changelog

### v2.0.0 - Modular Architecture
- Implemented modular design with separate network, bastion, and compute modules
- Enhanced configurability and reusability
- Improved documentation and examples
- Added support for multiple private instances
- Enhanced tagging and lifecycle management

### v1.0.0 - Initial Release
- Basic Terraform configuration for OCI
- Ansible integration for software provisioning
- Reserved private IP support
- Basic documentation