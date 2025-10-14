variable "name" {}
variable "cidr_block" {}
variable "azs" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

variable "tags" {
  type    = map(string)
  default = {}
}
