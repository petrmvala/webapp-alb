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

variable "ssh_key" {
  description = "SSH key to instances"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "min_size" {
  description = "Minimal number of instances in ASG to be operable"
  default     = 1
}

variable "max_size" {
  description = "Maximal number of instances in ASG"
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  default     = 2
}

