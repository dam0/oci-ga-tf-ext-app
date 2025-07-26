# Ansible Module - Provisions instances using Ansible

# Null resource to run Ansible provisioning after infrastructure completes
resource "null_resource" "ansible_provisioning" {
  # Only run when instances are created or updated
  triggers = {
    bastion_id = var.bastion_id
    private_instance_id = var.private_instance_id
    second_private_instance_id = var.create_second_instance ? var.private_instance_secondary_id : "none"
  }

  # Generate Ansible inventory from Terraform outputs
  provisioner "local-exec" {
    command = <<-EOT
      # Wait for instances to be fully initialized
      sleep ${var.wait_time_seconds}

      # Export SSH key path
      export SSH_PRIVATE_KEY_PATH=${var.private_key_path}
      export BASTION_PUBLIC_IP=${var.bastion_public_ip}
      export PRIVATE_INSTANCE_IP=${var.private_instance_private_ip}
      export SECONDARY_INSTANCE_IP=${var.create_second_instance ? var.private_instance_secondary_private_ip : ""}

      # Generate Ansible inventory
      ${var.inventory_script_path}

      # Run Ansible playbook
      cd ${var.ansible_dir} && ansible-playbook -i ${var.inventory_file} ${var.playbook_file} ${var.ansible_limit} --private-key ${var.private_key_path} -e "${var.ansible_extra_vars}"
    EOT
  }
}