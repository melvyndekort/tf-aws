locals {
  contact = {
    contact_type   = "PERSON"
    first_name     = "Melvyn"
    last_name      = "de Kort"
    email          = "melvyn@mdekort.nl"
    address_line_1 = "Dahliastraat 47"
    zip_code       = "4613 DS"
    city           = "Bergen op Zoom"
    country_code   = "NL"
    phone_number   = "+31.641381489"
  }
}

resource "aws_route53domains_registered_domain" "mdekort" {
  domain_name   = "mdekort.nl"
  auto_renew    = true
  transfer_lock = false # not supported in NL

  admin_privacy      = true
  registrant_privacy = true
  tech_privacy       = true

  admin_contact {
    contact_type   = local.contact.contact_type
    first_name     = local.contact.first_name
    last_name      = local.contact.last_name
    email          = local.contact.email
    address_line_1 = local.contact.address_line_1
    zip_code       = local.contact.zip_code
    city           = local.contact.city
    country_code   = local.contact.country_code
    phone_number   = local.contact.phone_number
  }

  registrant_contact {
    contact_type   = local.contact.contact_type
    first_name     = "de"
    last_name      = "Kort Melvyn"
    email          = local.contact.email
    address_line_1 = local.contact.address_line_1
    zip_code       = local.contact.zip_code
    city           = local.contact.city
    country_code   = local.contact.country_code
    phone_number   = local.contact.phone_number
  }

  tech_contact {
    contact_type   = local.contact.contact_type
    first_name     = local.contact.first_name
    last_name      = local.contact.last_name
    email          = local.contact.email
    address_line_1 = local.contact.address_line_1
    zip_code       = local.contact.zip_code
    city           = local.contact.city
    country_code   = local.contact.country_code
    phone_number   = local.contact.phone_number
  }

  name_server {
    name = "dean.ns.cloudflare.com"
  }

  name_server {
    name = "marissa.ns.cloudflare.com"
  }
}
