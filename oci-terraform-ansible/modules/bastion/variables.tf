# Bastion Module Variables

variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for the instance"
  type        = string
}

variable "public_subnet_id" {
  description = "The OCID of the public subnet"
  type        = string
}

variable "instance_shape" {
  description = "The shape of the instance"
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
    ocpus         = 1
  }
}

variable "instance_image_ocid" {
  description = "The OCID of the instance image"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for the instance"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "oci-ext"
}

variable "hostname_label" {
  description = "Hostname label for the instance"
  type        = string
  default     = "bastion"
}

variable "create_reserved_ip" {
  description = "Whether to create a reserved private IP"
  type        = bool
  default     = true
}

variable "reserved_ip_address" {
  description = "The reserved IP address (if create_reserved_ip is true)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags for the instance"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for the instance"
  type        = map(string)
  default     = {}
}