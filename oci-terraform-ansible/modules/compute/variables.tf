variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "The availability domain for resources"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "test-ext"
}

variable "instance_shape" {
  description = "The shape of the instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_image_ocid" {
  description = "The OCID of the instance image"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for instance access"
  type        = string
}

variable "public_subnet_id" {
  description = "The OCID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "The OCID of the private subnet"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
}

variable "bastion_memory_in_gbs" {
  description = "Memory allocation for bastion instance in GBs"
  type        = number
  default     = 16
}

variable "bastion_ocpus" {
  description = "OCPU allocation for bastion instance"
  type        = number
  default     = 1
}

variable "private_instance_memory_in_gbs" {
  description = "Memory allocation for private instance in GBs"
  type        = number
  default     = 16
}

variable "private_instance_ocpus" {
  description = "OCPU allocation for private instance"
  type        = number
  default     = 2
}

variable "bastion_private_ip_host_num" {
  description = "Host number for bastion's private IP within the subnet CIDR"
  type        = number
  default     = 10
}

variable "private_instance_ip_host_num" {
  description = "Host number for private instance's private IP within the subnet CIDR"
  type        = number
  default     = 10
}

variable "secondary_instance_ip_host_num" {
  description = "Host number for secondary private instance's private IP within the subnet CIDR"
  type        = number
  default     = 11
}

variable "create_second_instance" {
  description = "Whether to create a second instance with its own reserved private IP"
  type        = bool
  default     = false
}