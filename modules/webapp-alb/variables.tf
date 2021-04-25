# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "Tags which all the resources should have"
  type        = map(string)
}

variable "target_port" {
  description = "Port on which the webserver is running"
  type        = number
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "terminate_ssl" {
  description = "True for HTTP between ALB and EC2, false for HTTPS (certificate needed)"
  default     = true
}

