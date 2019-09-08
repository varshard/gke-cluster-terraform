variable "general_purpose_machine_type" {
  type = "string"
  description = "Machine type to use for the general-purpose node pool. See https://cloud.google.com/compute/docs/machine-types"
}

variable "general_purpose_min_node_count" {
  type = "string"
  description = "The minimum number of nodes PER ZONE in the general-purpose node pool"
  default = 1
}

variable "general_purpose_max_node_count" {
  type = "string"
  description = "The maximum number of nodes PER ZONE in the general-purpose node pool"
  default = 5
}

variable "project" {
  type = "string"
  description = "Google Cloud project name"
}

variable "region" {
  type = "string"
  description = "Default Google Cloud region"
}

variable "image" {
  type = "string"
  description = "image tag"
}
