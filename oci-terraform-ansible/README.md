# OCI Terraform Configuration with Ansible Provisioning

This Terraform configuration provisions an Oracle Cloud Infrastructure (OCI) environment with a public bastion host and private instances, each with attached private IPs that can be detached for reuse. It also includes Ansible playbooks to provision the instances with Java, SQLCL, Oracle ORDS, and Tomcat server.

## Architecture

The project uses a modular architecture with the following components:

### Modules
- **Network Module**: Creates VCN, subnets, gateways, route tables, and security lists
- **Compute Module**: Creates instances with detachable private IPs
- **Load Balancer Module**: Creates a load balancer with HTTP to HTTPS redirect
- **Ansible Module**: Provisions instances using Ansible

This modular approach provides several benefits:
- **Reusability**: Modules can be reused across different projects
- **Maintainability**: Each module has a single responsibility
- **Scalability**: Easy to add or modify components without affecting the entire infrastructure
- **Testability**: Modules can be tested independently

## Resources Created

### Infrastructure (Terraform)
- Virtual Cloud Network (VCN)
- Internet Gateway
- NAT Gateway
- Public and Private Route Tables
- Public and Private Security Lists
- Public and Private Subnets
- Public Bastion Host (in public subnet)
- Private Instance(s) (in private subnet)
- Reusable Private IPs for each instance
- Load Balancer with HTTP to HTTPS redirect
- SSL Certificate for HTTPS connections

### Software (Ansible)
- Java 11 (on all instances)
- Tomcat 9 (on private instances)
- Oracle SQLCL (on all instances)
- Oracle ORDS (on private instances)

## Prerequisites

1. An Oracle Cloud Infrastructure account
2. OCI CLI configured with API keys
3. Terraform installed
4. Ansible installed (for software provisioning)
5. SSH key pair for instance access

## Setup Instructions

### Infrastructure Deployment

1. Clone this repository
2. Create a `terraform.tfvars` file based on the example:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```
3. Edit `terraform.tfvars` with your OCI credentials and configuration
4. Initialize Terraform:
   ```
   terraform init
   ```
5. Plan the deployment:
   ```
   terraform plan
   ```
6. Apply the configuration:
   ```
   terraform apply
   ```

### Software Provisioning

The Terraform configuration includes a `null_resource` that automatically runs Ansible provisioning after the infrastructure is deployed. This will:

1. Wait for the instances to be fully initialized
2. Generate an Ansible inventory file from Terraform outputs
3. Run the Ansible playbook to install and configure the required software

If you need to run the Ansible provisioning manually:

1. Set your SSH private key path:
   ```
   export SSH_PRIVATE_KEY_PATH=/path/to/your/private/key
   ```
2. Generate the Ansible inventory:
   ```
   ./generate_inventory.sh
   ```
3. Run the Ansible playbook:
   ```
   cd ansible
   ansible-playbook -i inventory/hosts.ini provision.yml
   ```

## Module Usage

### Network Module

```hcl
module "network" {
  source = "./modules/network"

  compartment_id = var.compartment_id
  vcn_cidr       = "10.0.0.0/16"
  
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  
  name_prefix = "test-ext"
  dns_label   = "testextvcn"
  
  # Optional security settings
  allow_http  = true
  allow_https = true
  app_ports   = [8080, 8443, 9090] # Tomcat and ORDS ports
}
```

### Compute Module

```hcl
module "compute" {
  source = "./modules/compute"
  
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  name_prefix         = "test-ext"
  
  # Instance configuration
  instance_shape     = "VM.Standard.E4.Flex"
  instance_image_ocid = var.instance_image_ocid
  ssh_public_key     = var.ssh_public_key
  
  # Network references
  public_subnet_id   = module.network.public_subnet_id
  private_subnet_id  = module.network.private_subnet_id
  public_subnet_cidr = module.network.public_subnet_cidr
  private_subnet_cidr = module.network.private_subnet_cidr
  
  # Instance sizing
  bastion_memory_in_gbs = 16
  bastion_ocpus = 1
  private_instance_memory_in_gbs = 16
  private_instance_ocpus = 2
  
  # Private IP configuration
  bastion_private_ip_host_num = 10
  private_instance_ip_host_num = 10
  secondary_instance_ip_host_num = 11
  
  # Optional second instance
  create_second_instance = false
}
```

### Load Balancer Module

```hcl
module "load_balancer" {
  source = "./modules/load_balancer"
  
  compartment_id = var.compartment_id
  name_prefix    = "test-ext"
  
  # Network references
  public_subnet_id = module.network.public_subnet_id
  
  # Backend instances
  private_instance_ids = [module.compute.private_instance_id]
  
  # SSL Certificate
  certificate_ocid = "ocid1.certificate.oc1.ap-sydney-1.amaaaaaauvuxtpqavipyy4kzf6dtloospnhtfqmq42fkhbneskpxjuwyzs5q"
  
  # Load balancer configuration
  lb_shape                   = "flexible"
  lb_min_shape_bandwidth_mbps = 10
  lb_max_shape_bandwidth_mbps = 100
  
  # Backend configuration
  backend_port         = 8080
  health_check_port    = 8080
  health_check_url_path = "/"
}
```

### Ansible Module

```hcl
module "ansible" {
  source = "./modules/ansible"
  
  # Instance references
  bastion_id = module.compute.bastion_id
  private_instance_id = module.compute.private_instance_id
  private_instance_secondary_id = module.compute.private_instance_secondary_id
  
  # IP addresses for Ansible inventory
  bastion_public_ip = module.compute.bastion_public_ip
  private_instance_private_ip = module.compute.private_instance_private_ip
  
  # Ansible configuration
  private_key_path = var.private_key_path
  inventory_script_path = "./generate_inventory.sh"
  ansible_dir = "ansible"
  playbook_file = "provision.yml"
}
```

## Network Architecture

This configuration creates a secure network architecture with:

1. A public subnet (10.0.1.0/24) with access to the internet through an Internet Gateway
2. A private subnet (10.0.2.0/24) with outbound-only internet access through a NAT Gateway
3. A bastion host in the public subnet that serves as a jump server to access private instances
4. Private instances in the private subnet that are not directly accessible from the internet
5. A load balancer in the public subnet that routes traffic to the private instances
6. HTTP to HTTPS redirect for secure connections
7. SSL certificate for HTTPS encryption

## Accessing the Environment

### SSH Access to Instances

- The bastion host can be accessed directly via SSH:
  ```
  ssh opc@<bastion_public_ip>
  ```

- The private instances can be accessed via SSH through the bastion host:
  ```
  ssh -J opc@<bastion_public_ip> opc@<private_instance_private_ip>
  ```

### Application Access via Load Balancer

- The Tomcat application can be accessed through the load balancer:
  - HTTP (will redirect to HTTPS): `http://<load_balancer_ip>`
  - HTTPS (secure): `https://<load_balancer_ip>`

- The load balancer routes traffic to the Tomcat instances running on port 8080 in the private subnet
- All HTTP traffic is automatically redirected to HTTPS for secure connections
- The load balancer uses a valid SSL certificate for HTTPS encryption

## Reserved Private IPs

This configuration creates reserved private IPs for each instance:

1. The bastion host has a reserved private IP (10.0.1.10) in the public subnet
2. The private instance has a reserved private IP (10.0.2.10) in the private subnet
3. To create a second private instance with its own reserved private IP (10.0.2.11):
   ```
   terraform apply -var="create_second_instance=true"
   ```

These private IPs are reserved and can be detached from their instances and reused with other resources if needed. The IPs remain reserved even if the instances are terminated, allowing you to attach them to new instances later.

### Automatic Private IP Detachment

This configuration includes safeguards to ensure private IPs are properly detached before their associated VNICs are destroyed:

1. The `lifecycle { create_before_destroy = true }` setting ensures proper resource creation and destruction order
2. Explicit dependencies are set up to control the destroy sequence
3. A `null_resource` with a `local-exec` provisioner is included to explicitly detach the private IP before VNIC destruction

When running in a production environment, you'll need to uncomment the OCI CLI command in the `null_resource` provisioners to enable automatic detachment.

### Manual Detaching and Reattaching Private IPs

You can also manually detach and reattach private IPs using the OCI Console, CLI, or API:

1. To detach a private IP using the OCI CLI:
   ```
   oci network private-ip update --private-ip-id <private_ip_id> --vnic-id null
   ```

2. To attach an existing private IP to a different VNIC:
   ```
   oci network private-ip update --private-ip-id <private_ip_id> --vnic-id <new_vnic_id>
   ```

3. To create a new private IP with a specific address and attach it to a VNIC:
   ```
   oci network private-ip create --display-name "reattached-ip" --ip-address <ip_address> --vnic-id <new_vnic_id>
   ```

This allows you to maintain the same IP address across different resources over time, even after the original resources are destroyed.

## Ansible Provisioning

After the infrastructure is provisioned with Terraform, you can use Ansible to install and configure the required software:

1. Generate the Ansible inventory from Terraform outputs:
   ```
   export SSH_PRIVATE_KEY_PATH=/path/to/your/private/key
   ./generate_inventory.sh
   ```

2. Run the Ansible playbook to provision the instances:
   ```
   cd ansible
   ansible-playbook -i inventory/hosts.ini provision.yml
   ```

### Software Configuration

The Ansible playbooks will install and configure:

1. **Java 11** - Installed on all instances
2. **Tomcat 9** - Installed on private instances
   - Accessible on port 8080
   - Admin console available at http://private-instance-ip:8080/manager/html
   - Default admin credentials (change these in production):
     - Username: admin
     - Password: admin_password

3. **Oracle SQLCL** - Installed on all instances
   - Available in PATH as `sql`

4. **Oracle ORDS** - Installed on private instances
   - Accessible on port 8888
   - Configured to connect to your Oracle database

### Customizing the Installation

You can customize the software installation by modifying the variables in `ansible/group_vars/all.yml`.

## Cleanup

To destroy all resources created by this configuration:

```
terraform destroy
```

## Variables

| Name | Description | Required |
|------|-------------|----------|
| tenancy_ocid | The OCID of your tenancy | Yes |
| user_ocid | The OCID of the user | Yes |
| fingerprint | The fingerprint of the key | Yes |
| private_key_path | The path to the private key | Yes |
| region | The OCI region | Yes |
| compartment_id | The OCID of the compartment | Yes |
| availability_domain | The availability domain for resources | Yes |
| ssh_public_key | The SSH public key for instance access | Yes |
| instance_shape | The shape of the instance | No (default: VM.Standard2.1) |
| instance_image_ocid | The OCID of the instance image | Yes |
| public_subnet_cidr | CIDR block for the public subnet | No (default: 10.0.1.0/24) |
| private_subnet_cidr | CIDR block for the private subnet | No (default: 10.0.2.0/24) |
| vcn_cidr | CIDR block for the VCN | No (default: 10.0.0.0/16) |
| create_second_instance | Whether to create a second private instance with its own reserved private IP | No (default: false) |