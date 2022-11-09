terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.2.1"
    }
  }
  required_version = ">= 1"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Env     = "testing"
      Project = "${var.id}-mac-metal-test"
      Name    = "${var.id}-mac-metal-test"
    }
  }
}
