variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
}

# variable "user_ocid" {
#   description = "The OCID of the user"
#   type        = string
# }

# variable "fingerprint" {
#   description = "The fingerprint of the key"
#   type        = string
# }

variable "private_key_path" {
  description = "The path to the private key"
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
  description = "The availability domain for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for instance access"
  type        = string
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

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_second_instance" {
  description = "Whether to create a second instance with its own reserved private IP"
  type        = bool
  default     = false
}