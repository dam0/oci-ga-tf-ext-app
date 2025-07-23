# Private Compute Module Variables

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for the instances"
  type        = string
}

variable "private_subnet_id" {
  description = "The OCID of the private subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "The CIDR block of the private subnet"
  type        = string
}

variable "instance_count" {
  description = "Number of private instances to create"
  type        = number
  default     = 1
}

variable "instance_shape" {
  description = "The shape of the instances"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_shape_config" {
  description = "The shape configuration for flexible instances"
  type = object({
    memory_in_gbs = number
    ocpus         = number
  })
  default = {
    memory_in_gbs = 16
    ocpus         = 2
  }
}

variable "instance_image_ocid" {
  description = "The OCID of the instance image"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for the instances"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "oci-ext"
}

variable "hostname_label_prefix" {
  description = "Hostname label prefix for the instances"
  type        = string
  default     = "private"
}

variable "create_reserved_ips" {
  description = "Whether to create reserved private IPs"
  type        = bool
  default     = true
}

variable "reserved_ip_addresses" {
  description = "List of reserved IP addresses (if create_reserved_ips is true)"
  type        = list(string)
  default     = null
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags for the instances"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for the instances"
  type        = map(string)
  default     = {}
}

variable "nsg_ids" {
  description = "List of Network Security Group OCIDs to attach to the instances"
  type        = list(string)
  default     = []
}