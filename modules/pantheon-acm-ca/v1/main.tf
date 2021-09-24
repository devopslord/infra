resource "aws_acmpca_certificate_authority" "main" {
  certificate_authority_configuration {
    key_algorithm     = var.key_algorithm
    signing_algorithm = var.signing_algorithm

    subject {
      common_name         = var.subject[0].common_name
      country             = var.subject[0].country
      locality            = var.subject[0].locality
      organizational_unit = var.subject[0].organizational_unit
      organization        = var.subject[0].organization
      state               = var.subject[0].state
    }
  }
  type                            = "ROOT"
  permanent_deletion_time_in_days = 30

  revocation_configuration {
    crl_configuration {
      expiration_in_days = var.expiration_in_days
    }
  }
}