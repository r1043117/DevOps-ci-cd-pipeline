
# TERRAFORM PROVIDER CONFIGURATIE

# Dit bestand vertelt Terraform welke cloud provider we gebruiken.
# In ons geval is dat Amazon Web Services (AWS).

# Zie het als een "stuurprogramma" - net zoals je PC een driver
# nodig heeft om met je printer te praten, heeft Terraform een
# provider nodig om met AWS te communiceren.


# Hier geven we aan welke provider plugins Terraform moet downloaden.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.0"
    }
  }
}


# Gandi API key variabele (voor DNS beheer)
variable "gandi_api_key" {
  description = "Gandi Personal Access Token voor DNS beheer"
  type        = string
  sensitive   = true
}

# Hier configureren we de verbinding met AWS.
# Terraform gebruikt automatisch de credentials die je hebt ingesteld
# met 'aws configure' (opgeslagen in ~/.aws/credentials)
provider "aws" {
  region = var.aws_region
}

# Gandi provider voor DNS beheer
provider "gandi" {
  personal_access_token = var.gandi_api_key
}
