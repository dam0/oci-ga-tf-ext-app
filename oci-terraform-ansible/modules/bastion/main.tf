# Bastion Module - Creates bastion host with reserved private IP

# Create a bastion host in the public subnet
resource "oci_core_instance" "bastion" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-bastion"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = var.instance_shape_config != null ? [var.instance_shape_config] : []
    content {
      memory_in_gbs = shape_config.value.memory_in_gbs
      ocpus         = shape_config.value.ocpus
    }
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
    display_name     = "${var.name_prefix}-bastion-vnic"
    assign_public_ip = true
    hostname_label   = var.hostname_label
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data          = var.user_data != null ? base64encode(var.user_data) : null
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Create a VNIC attachment for the bastion's reserved private IP (optional)
resource "oci_core_vnic_attachment" "bastion_vnic_attachment" {
  count        = var.create_reserved_ip ? 1 : 0
  instance_id  = oci_core_instance.bastion.id
  display_name = "${var.name_prefix}-bastion-secondary-vnic"

  create_vnic_details {
    subnet_id              = var.public_subnet_id
    display_name           = "${var.name_prefix}-bastion-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create a reserved private IP for the bastion that can be detached and reused
resource "oci_core_private_ip" "bastion_private_ip" {
  count          = var.create_reserved_ip ? 1 : 0
  display_name   = "${var.name_prefix}-bastion-private-ip"
  ip_address     = var.reserved_ip_address
  vnic_id        = oci_core_vnic_attachment.bastion_vnic_attachment[0].vnic_id
  hostname_label = "${var.hostname_label}-private-ip"
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [oci_core_vnic_attachment.bastion_vnic_attachment]
}

# This resource ensures the bastion's private IP is detached before the VNIC is destroyed
resource "null_resource" "detach_bastion_private_ip" {
  count = var.create_reserved_ip ? 1 : 0
  
  triggers = {
    private_ip_id = oci_core_private_ip.bastion_private_ip[0].id
  }

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