# Network Module Variables

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

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

# IP Filtering Variables
variable "allowed_ipv4_cidr" {
  description = "List of allowed IPv4 CIDR blocks for application access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ipv6_cidr" {
  description = "List of allowed IPv6 CIDR blocks for application access"
  type        = list(string)
  default     = []
}

variable "allowed_ssh_cidr" {
  description = "List of allowed CIDR blocks for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}