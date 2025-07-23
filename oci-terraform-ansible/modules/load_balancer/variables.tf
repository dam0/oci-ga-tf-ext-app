variable "compartment_id" {
  description = "The OCID of the compartment"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "test-ext"
}

variable "subnet_ids" {
  description = "List of subnet OCIDs for the load balancer (typically public subnets)"
  type        = list(string)
}

variable "backend_servers" {
  description = "List of backend server configurations"
  type = list(object({
    ip_address = string
    backup     = bool
    drain      = bool
    offline    = bool
    weight     = number
  }))
}

variable "certificate_ocid" {
  description = "The OCID of the existing certificate to use for HTTPS"
  type        = string
  default     = "ocid1.certificate.oc1.ap-sydney-1.amaaaaaauvuxtpqavipyy4kzf6dtloospnhtfqmq42fkhbneskpxjuwyzs5q"
}

variable "lb_shape" {
  description = "The shape of the load balancer"
  type        = string
  default     = "flexible"
}

variable "lb_min_shape_bandwidth_mbps" {
  description = "Minimum bandwidth for flexible shape"
  type        = number
  default     = 10
}

variable "lb_max_shape_bandwidth_mbps" {
  description = "Maximum bandwidth for flexible shape"
  type        = number
  default     = 100
}

variable "tomcat_port" {
  description = "The port used to communicate with the Tomcat backend instances"
  type        = number
  default     = 8080
}

variable "health_check_url_path" {
  description = "The URL path used for health checks"
  type        = string
  default     = "/"
}

variable "is_private" {
  description = "Whether the load balancer is private (no public IP)"
  type        = bool
  default     = false
}

variable "backend_set_name" {
  description = "Name for the backend set"
  type        = string
  default     = "tomcat-backend-set"
}

variable "backend_policy" {
  description = "Load balancing policy for the backend set"
  type        = string
  default     = "ROUND_ROBIN"
}

variable "redirect_response_code" {
  description = "Response code for HTTP to HTTPS redirect"
  type        = string
  default     = "301"
}

# Health Check Variables
variable "health_check_return_code" {
  description = "Expected return code for health checks"
  type        = number
  default     = 200
}

variable "health_check_interval_ms" {
  description = "Health check interval in milliseconds"
  type        = number
  default     = 10000
}

variable "health_check_timeout_ms" {
  description = "Health check timeout in milliseconds"
  type        = number
  default     = 3000
}

variable "health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 3
}

# Session Persistence Variables
variable "session_cookie_name" {
  description = "Name of the session persistence cookie"
  type        = string
  default     = "X-Oracle-BMC-LBS-Route"
}

variable "disable_session_fallback" {
  description = "Whether to disable session persistence fallback"
  type        = bool
  default     = false
}

# SSL Configuration Variables
variable "ssl_verify_peer_certificate" {
  description = "Whether to verify peer certificate"
  type        = bool
  default     = false
}

variable "ssl_verify_depth" {
  description = "SSL verification depth"
  type        = number
  default     = 5
}

variable "trusted_ca_ids" {
  description = "List of trusted certificate authority IDs"
  type        = list(string)
  default     = null
}

# Connection Configuration
variable "connection_idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
}

# Tagging Variables
variable "freeform_tags" {
  description = "Free-form tags for the load balancer"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags for the load balancer"
  type        = map(string)
  default     = {}
}

# WAF Configuration Variables
variable "enable_waf" {
  description = "Whether to enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_rate_limit_requests_per_minute" {
  description = "Number of requests allowed per minute for rate limiting"
  type        = number
  default     = 100
}

variable "waf_allowed_paths" {
  description = "List of allowed URL paths (default blocks all except these)"
  type        = list(string)
  default     = ["/ords/r/marinedataregister", "/"]
}

variable "waf_block_response_code" {
  description = "HTTP response code for blocked requests"
  type        = number
  default     = 403
}

variable "waf_block_response_message" {
  description = "Response message for blocked requests"
  type        = string
  default     = "Access Denied: This resource is not available."
}

# IP Filtering Variables
variable "allowed_ipv6_cidr" {
  description = "List of allowed IPv6 CIDR blocks"
  type        = list(string)
  default     = ["2400:a844:4088::/48"]
}

variable "allowed_ipv4_cidr" {
  description = "List of allowed IPv4 CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}