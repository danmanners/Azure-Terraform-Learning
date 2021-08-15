// Terraform Region
variable "tf-region" {
    description = "Region to operate resources in."
}

// Resource Tags
variable "tags" {
    description = "Required tags"
}

variable "global-tags" {
    description = "Additional tags; optional."
    default = {}
}