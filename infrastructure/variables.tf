variable "aws_region" {
  type    = string
  default = "ap-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "user_password" {
  type      = string
  sensitive = true
}

variable "ssh_ingress_cidr_blocks" {
  type    = list(string)
  default = ["1.2.3.4/32", "5.6.7.8/32"]
}

variable "fqdn" {
  type    = string
  default = "example.tld."
}

variable "id" {
  type    = string
  default = "ff"
}
