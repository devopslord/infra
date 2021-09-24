terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/new-relic-rules/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "newrelic" {
  api_key = var.newrelic_api_key
  version = "~> 1.16"
}

module "new_relic" {
  source = "../../modules/pantheon-nr/"

  slack_webhook_url = "https://hooks.slack.com/services/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"
}
