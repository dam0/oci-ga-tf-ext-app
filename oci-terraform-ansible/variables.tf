# Modular Terraform Variables for OCI Infrastructure

# OCI Provider Variables
variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for the instances"
  type        = string
}

# Network Configuration
variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "oci-ext"
}

variable "dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "ociextvcn"
}

variable "allow_http" {
  description = "Allow HTTP traffic on port 80"
  type        = bool
  default     = false
}

variable "allow_https" {
  description = "Allow HTTPS traffic on port 443"
  type        = bool
  default     = false
}

variable "app_ports" {
  description = "List of application ports to allow from public subnet"
  type        = list(number)
  default     = [8080, 8443, 9090] # Tomcat and ORDS ports
}

# Instance Configuration
variable "instance_shape" {
  description = "The shape of the instances"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_image_ocid" {
  description = "The OCID of the instance image"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for the instances"
  type        = string
}

# Bastion Configuration
variable "bastion_shape_config" {
  description = "The shape configuration for the bastion instance"
  type = object({
    memory_in_gbs = number
    ocpus         = number
  })
  default = {
    memory_in_gbs = 16
    ocpus         = 1
  }
}

variable "create_bastion_reserved_ip" {
  description = "Whether to create a reserved private IP for the bastion"
  type        = bool
  default     = true
}

variable "bastion_reserved_ip_address" {
  description = "The reserved IP address for the bastion"
  type        = string
  default     = null
}

variable "bastion_user_data" {
  description = "User data script for bastion initialization"
  type        = string
  default     = null
}

# Private Instance Configuration
variable "private_instance_count" {
  description = "Number of private instances to create"
  type        = number
  default     = 2
}

variable "private_instance_shape_config" {
  description = "The shape configuration for private instances"
  type = object({
    memory_in_gbs = number
    ocpus         = number
  })
  default = {
    memory_in_gbs = 16
    ocpus         = 2
  }
}

variable "create_private_reserved_ips" {
  description = "Whether to create reserved private IPs for private instances"
  type        = bool
  default     = true
}

variable "private_reserved_ip_addresses" {
  description = "List of reserved IP addresses for private instances"
  type        = list(string)
  default     = null
}

variable "private_instance_user_data" {
  description = "User data script for private instance initialization"
  type        = string
  default     = null
}

# Ansible Configuration
variable "enable_ansible_provisioning" {
  description = "Whether to run Ansible provisioning after infrastructure creation"
  type        = bool
  default     = true
}

# Load Balancer Configuration
variable "certificate_ocid" {
  description = "The OCID of the certificate to use for HTTPS"
  type        = string
  default     = "ocid1.certificate.oc1.ap-sydney-1.amaaaaaauvuxtpqavipyy4kzf6dtloospnhtfqmq42fkhbneskpxjuwyzs5q"
}

variable "lb_shape" {
  description = "The shape of the load balancer"
  type        = string
  default     = "flexible"
}

variable "lb_min_bandwidth_mbps" {
  description = "Minimum bandwidth for flexible shape load balancer"
  type        = number
  default     = 10
}

variable "lb_max_bandwidth_mbps" {
  description = "Maximum bandwidth for flexible shape load balancer"
  type        = number
  default     = 100
}

variable "lb_is_private" {
  description = "Whether the load balancer is private (no public IP)"
  type        = bool
  default     = false
}

variable "tomcat_port" {
  description = "The port used to communicate with the Tomcat backend instances"
  type        = number
  default     = 8080
}

variable "health_check_url_path" {
  description = "The URL path used for health checks"
  type        = string
  default     = "/"
}

# WAF Configuration
variable "enable_waf" {
  description = "Whether to enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_rate_limit_requests_per_minute" {
  description = "Number of requests allowed per minute for rate limiting"
  type        = number
  default     = 100
}

variable "waf_allowed_paths" {
  description = "List of paths to allow through the WAF"
  type        = list(string)
  default     = ["/ords/r/marinedataregister", "/"]
}

# Tags
variable "freeform_tags" {
  description = "Freeform tags for all resources"
  type        = map(string)
  default = {
    "Environment" = "development"
    "Project"     = "oci-terraform-ansible"
  }
}

variable "defined_tags" {
  description = "Defined tags for all resources"
  type        = map(string)
  default     = {}
}