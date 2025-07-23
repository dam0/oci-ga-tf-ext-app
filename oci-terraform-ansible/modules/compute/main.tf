# Compute Module - Creates instances with detachable private IPs

# Create a bastion host in the public subnet
resource "oci_core_instance" "bastion" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-bastion"
  shape               = var.instance_shape

  shape_config {
    memory_in_gbs = var.bastion_memory_in_gbs
    ocpus         = var.bastion_ocpus
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
    display_name     = "${var.name_prefix}-bastion-vnic"
    assign_public_ip = true
    hostname_label   = "bastion"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a VNIC attachment for the bastion's reserved private IP
resource "oci_core_vnic_attachment" "bastion_vnic_attachment" {
  instance_id  = oci_core_instance.bastion.id
  display_name = "${var.name_prefix}-bastion-secondary-vnic"

  create_vnic_details {
    subnet_id              = var.public_subnet_id
    display_name           = "${var.name_prefix}-bastion-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# Create a reserved private IP for the bastion that can be detached and reused
resource "oci_core_private_ip" "bastion_private_ip" {
  display_name   = "${var.name_prefix}-bastion-private-ip"
  ip_address     = cidrhost(var.public_subnet_cidr, var.bastion_private_ip_host_num)
  vnic_id        = oci_core_vnic_attachment.bastion_vnic_attachment.vnic_id
  hostname_label = "bastion-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.bastion_vnic_attachment]
}

# This resource ensures the bastion's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_bastion_private_ip" {
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.bastion_private_ip.id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching bastion private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.bastion_private_ip]
}

# Create a private instance in the private subnet
resource "oci_core_instance" "private_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-private-instance"
  shape               = var.instance_shape

  shape_config {
    memory_in_gbs = var.private_instance_memory_in_gbs
    ocpus         = var.private_instance_ocpus
  }

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    display_name     = "${var.name_prefix}-private-instance-vnic"
    assign_public_ip = false
    hostname_label   = "private"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a VNIC attachment for the private instance's reserved private IP
resource "oci_core_vnic_attachment" "private_instance_vnic_attachment" {
  instance_id  = oci_core_instance.private_instance.id
  display_name = "${var.name_prefix}-private-instance-secondary-vnic"

  create_vnic_details {
    subnet_id              = var.private_subnet_id
    display_name           = "${var.name_prefix}-private-instance-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# Create a reserved private IP for the private instance that can be detached and reused
resource "oci_core_private_ip" "private_instance_private_ip" {
  display_name   = "${var.name_prefix}-private-instance-private-ip"
  ip_address     = cidrhost(var.private_subnet_cidr, var.private_instance_ip_host_num)
  vnic_id        = oci_core_vnic_attachment.private_instance_vnic_attachment.vnic_id
  hostname_label = "private-instance-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.private_instance_vnic_attachment]
}

# This resource ensures the private instance's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_private_instance_private_ip" {
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.private_instance_private_ip.id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching private instance private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.private_instance_private_ip]
}

# Create a second private instance if requested
resource "oci_core_instance" "private_instance_secondary" {
  count               = var.create_second_instance ? 1 : 0
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-private-instance-secondary"
  shape               = var.instance_shape

  shape_config {
    memory_in_gbs = var.private_instance_memory_in_gbs
    ocpus         = var.private_instance_ocpus
  }

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    display_name     = "${var.name_prefix}-private-instance-secondary-vnic"
    assign_public_ip = false
    hostname_label   = "private2"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }
}

# Create a VNIC attachment for the second private instance
resource "oci_core_vnic_attachment" "private_instance_secondary_vnic_attachment" {
  count        = var.create_second_instance ? 1 : 0
  instance_id  = oci_core_instance.private_instance_secondary[0].id
  display_name = "${var.name_prefix}-private-instance-secondary-vnic-attachment"

  create_vnic_details {
    subnet_id              = var.private_subnet_id
    display_name           = "${var.name_prefix}-private-instance-secondary-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  # This ensures proper destroy order
  lifecycle {
    create_before_destroy = true
  }
}

# Create a reserved private IP for the second private instance that can be detached and reused
resource "oci_core_private_ip" "private_instance_secondary_private_ip" {
  count          = var.create_second_instance ? 1 : 0
  display_name   = "${var.name_prefix}-private-instance-secondary-private-ip"
  ip_address     = cidrhost(var.private_subnet_cidr, var.secondary_instance_ip_host_num)
  vnic_id        = oci_core_vnic_attachment.private_instance_secondary_vnic_attachment[0].vnic_id
  hostname_label = "private-instance-secondary-private-ip"
  
  # This ensures the private IP is detached before the VNIC is destroyed
  lifecycle {
    create_before_destroy = true
  }
  
  # Add explicit dependency to control destroy order
  depends_on = [oci_core_vnic_attachment.private_instance_secondary_vnic_attachment]
}

# This resource ensures the second private instance's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_private_instance_secondary_private_ip" {
  count = var.create_second_instance ? 1 : 0
  
  # Only run this on destroy
  triggers = {
    private_ip_id = oci_core_private_ip.private_instance_secondary_private_ip[0].id
  }

  # This provisioner will run before the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Detaching second private instance private IP ${self.triggers.private_ip_id} before VNIC destruction"
      # Uncomment the line below when running in an environment with OCI CLI configured
      # oci network private-ip update --private-ip-id ${self.triggers.private_ip_id} --vnic-id null || true
    EOT
  }

  depends_on = [oci_core_private_ip.private_instance_secondary_private_ip]
}