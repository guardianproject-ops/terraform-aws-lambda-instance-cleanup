variable "regions" {
  type        = list
  description = "List of regions to check for instances in"
}

variable "schedule" {
  type        = string
  default     = "rate(1 hour)"
  description = "CloudWatch Events rule schedule using cron or rate expression"
}

#variable "limit_tag" {
#  type        = string
#  description = "The tag key which must be applied to instances"
#}

variable "limit_tags" {
  type        = map
  description = "The tag key which must be applied to instances"
  default     = { "CI" = ["true"] }
}
variable "max_age_minutes" {
  type        = number
  description = "Instances older than this value will be terminated"
}

#variable "limit_tag_values" {
#  type        = list
#  description = "List of valid values accepted for tag"
#}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `stage`, `name`, and `attributes`"
}

variable "namespace" {
  type        = string
  description = "Namespace, your org"
}

variable "stage" {
  type        = string
  description = "Environment (e.g. dev, prod, test)"
}

variable "name" {
  type        = string
  description = "Name  (e.g. `app` or `database`)"
}
variable "attributes" {
  type        = list
  default     = []
  description = "Additional attributes (e.g., `one', or `two')"
}

variable "tags" {
  type        = map
  default     = {}
  description = "Additional tags (e.g. map(`Visibility`,`Public`)"
}

