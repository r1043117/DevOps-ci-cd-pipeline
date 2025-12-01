
# TERRAFORM PROVIDER CONFIGURATIE

# Dit bestand vertelt Terraform welke cloud provider we gebruiken.
# In ons geval is dat Amazon Web Services (AWS).

# Zie het als een "stuurprogramma" - net zoals je PC een driver
# nodig heeft om met je printer te praten, heeft Terraform een
# provider nodig om met AWS te communiceren.


# Hier geven we aan welke provider plugin Terraform moet downloaden.
# HashiCorp (de makers van Terraform) onderhouden de officiële AWS provider.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Download van HashiCorp's registry
      version = "~> 5.0"          # Gebruik versie 5.x (nieuwste stabiele)
    }
  }
}

# Hier configureren we de verbinding met AWS.
# Terraform gebruikt automatisch de credentials die je hebt ingesteld
# met 'aws configure' (opgeslagen in ~/.aws/credentials)
provider "aws" {
  region = var.aws_region  # De regio wordt ingesteld via een variabele (zie main.tf)
}
