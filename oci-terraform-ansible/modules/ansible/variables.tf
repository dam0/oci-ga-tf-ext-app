variable "bastion_id" {
  description = "The OCID of the bastion instance"
  type        = string
}

variable "private_instance_id" {
  description = "The OCID of the private instance"
  type        = string
}

variable "private_instance_secondary_id" {
  description = "The OCID of the secondary private instance"
  type        = string
  default     = ""
}

variable "create_second_instance" {
  description = "Whether a second instance was created"
  type        = bool
  default     = false
}

variable "bastion_public_ip" {
  description = "The public IP of the bastion host"
  type        = string
}

variable "private_instance_private_ip" {
  description = "The private IP of the private instance"
  type        = string
}

variable "private_instance_secondary_private_ip" {
  description = "The private IP of the secondary private instance"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to the private SSH key"
  type        = string
}

variable "wait_time_seconds" {
  description = "Time to wait for instances to initialize before provisioning"
  type        = number
  default     = 120
}

variable "inventory_script_path" {
  description = "Path to the script that generates Ansible inventory"
  type        = string
  default     = "./generate_inventory.sh"
}

variable "ansible_dir" {
  description = "Directory containing Ansible playbooks"
  type        = string
  default     = "ansible"
}

variable "inventory_file" {
  description = "Path to the Ansible inventory file"
  type        = string
  default     = "inventory/hosts.ini"
}

variable "playbook_file" {
  description = "Name of the Ansible playbook to run"
  type        = string
  default     = "provision.yml"
}

variable "ansible_limit" {
  description = "Limit Ansible run to specific hosts"
  type        = string
  default     = "--limit private_instances"
}

variable "ansible_extra_vars" {
  description = "Extra variables to pass to Ansible"
  type        = string
  default     = "ansible_user=opc ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no opc@$BASTION_PUBLIC_IP\"'"
}