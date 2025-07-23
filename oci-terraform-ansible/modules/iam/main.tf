# IAM Policies for Load Balancer Service

# Dynamic Group for Load Balancer Service
resource "oci_identity_dynamic_group" "load_balancer_service" {
  count          = var.create_load_balancer_policies ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.name_prefix}-load-balancer-service-dg"
  description    = "Dynamic group for load balancer service instances"
  
  # Match all load balancer instances in the compartment
  matching_rule = "ALL {resource.type='loadbalancer', resource.compartment.id='${var.compartment_id}'}"
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Policy to allow Load Balancer service to manage network resources
resource "oci_identity_policy" "load_balancer_service_policy" {
  count          = var.create_load_balancer_policies ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.name_prefix}-load-balancer-service-policy"
  description    = "Policy to allow load balancer service to access required resources"
  
  statements = [
    # Allow load balancer to manage network resources
    "allow service loadbalancer to manage virtual-network-family in compartment id ${var.compartment_id}",
    
    # Allow load balancer to read compute instances for health checks
    "allow service loadbalancer to read instance-family in compartment id ${var.compartment_id}",
    
    # Allow load balancer to manage certificates
    "allow service loadbalancer to manage certificates in compartment id ${var.compartment_id}",
    
    # Allow load balancer to read secrets (for SSL certificates)
    "allow service loadbalancer to read secret-family in compartment id ${var.compartment_id}",
    
    # Allow load balancer to use network security groups
    "allow service loadbalancer to use network-security-groups in compartment id ${var.compartment_id}",
    
    # Allow load balancer to manage load balancer resources
    "allow service loadbalancer to manage load-balancers in compartment id ${var.compartment_id}"
  ]
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Policy for dynamic group (if using dynamic groups for advanced configurations)
resource "oci_identity_policy" "load_balancer_dynamic_group_policy" {
  count          = var.create_load_balancer_policies && var.enable_dynamic_group_policies ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.name_prefix}-load-balancer-dg-policy"
  description    = "Policy for load balancer dynamic group"
  
  statements = [
    # Allow dynamic group to read network resources
    "allow dynamic-group ${oci_identity_dynamic_group.load_balancer_service[0].name} to read virtual-network-family in compartment id ${var.compartment_id}",
    
    # Allow dynamic group to read instance information
    "allow dynamic-group ${oci_identity_dynamic_group.load_balancer_service[0].name} to read instance-family in compartment id ${var.compartment_id}",
    
    # Allow dynamic group to use network security groups
    "allow dynamic-group ${oci_identity_dynamic_group.load_balancer_service[0].name} to use network-security-groups in compartment id ${var.compartment_id}"
  ]
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# WAF Service Policy (if WAF is enabled)
resource "oci_identity_policy" "waf_service_policy" {
  count          = var.create_waf_policies ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.name_prefix}-waf-service-policy"
  description    = "Policy to allow WAF service to access load balancer"
  
  statements = [
    # Allow WAF to manage load balancers
    "allow service waas to manage load-balancers in compartment id ${var.compartment_id}",
    
    # Allow WAF to read virtual network resources
    "allow service waas to read virtual-network-family in compartment id ${var.compartment_id}",
    
    # Allow WAF to manage WAF policies
    "allow service waas to manage waas-family in compartment id ${var.compartment_id}"
  ]
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Health Check Service Policy
resource "oci_identity_policy" "health_check_service_policy" {
  count          = var.create_health_check_policies ? 1 : 0
  compartment_id = var.compartment_id
  name           = "${var.name_prefix}-health-check-service-policy"
  description    = "Policy to allow health check service to access instances"
  
  statements = [
    # Allow health check service to read instances
    "allow service health-check to read instance-family in compartment id ${var.compartment_id}",
    
    # Allow health check service to read network resources
    "allow service health-check to read virtual-network-family in compartment id ${var.compartment_id}",
    
    # Allow health check service to manage health checks
    "allow service health-check to manage health-checks in compartment id ${var.compartment_id}"
  ]
  
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}