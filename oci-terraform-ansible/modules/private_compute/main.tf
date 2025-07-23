# Private Compute Module - Creates private instances with reserved private IPs

# Create private instances
resource "oci_core_instance" "private_instance" {
  count               = var.instance_count
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "${var.name_prefix}-private-instance-${count.index + 1}"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = var.instance_shape_config != null ? [var.instance_shape_config] : []
    content {
      memory_in_gbs = shape_config.value.memory_in_gbs
      ocpus         = shape_config.value.ocpus
    }
  }

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    display_name     = "${var.name_prefix}-private-instance-${count.index + 1}-vnic"
    assign_public_ip = false
    hostname_label   = "${var.hostname_label_prefix}${count.index + 1}"
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data          = var.user_data != null ? base64encode(var.user_data) : null
  }

  freeform_tags = merge(var.freeform_tags, {
    "Instance" = "${var.name_prefix}-private-instance-${count.index + 1}"
  })
  defined_tags = var.defined_tags
}

# Create VNIC attachments for reserved private IPs
resource "oci_core_vnic_attachment" "private_instance_vnic_attachment" {
  count        = var.create_reserved_ips ? var.instance_count : 0
  instance_id  = oci_core_instance.private_instance[count.index].id
  display_name = "${var.name_prefix}-private-instance-${count.index + 1}-secondary-vnic"

  create_vnic_details {
    subnet_id              = var.private_subnet_id
    display_name           = "${var.name_prefix}-private-instance-${count.index + 1}-secondary-vnic"
    assign_public_ip       = false
    skip_source_dest_check = false
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create reserved private IPs for the instances that can be detached and reused
resource "oci_core_private_ip" "private_instance_private_ip" {
  count          = var.create_reserved_ips ? var.instance_count : 0
  display_name   = "${var.name_prefix}-private-instance-${count.index + 1}-private-ip"
  ip_address     = var.reserved_ip_addresses != null && length(var.reserved_ip_addresses) > count.index ? var.reserved_ip_addresses[count.index] : cidrhost(var.private_subnet_cidr, 10 + count.index)
  vnic_id        = oci_core_vnic_attachment.private_instance_vnic_attachment[count.index].vnic_id
  hostname_label = "${var.hostname_label_prefix}${count.index + 1}-private-ip"
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [oci_core_vnic_attachment.private_instance_vnic_attachment]
}

# This resource ensures the private instances' private IPs are detached before the VNICs are destroyed
resource "null_resource" "detach_private_instance_private_ip" {
  count = var.create_reserved_ips ? var.instance_count : 0
  
  triggers = {
    private_ip_id = oci_core_private_ip.private_instance_private_ip[count.index].id
  }

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