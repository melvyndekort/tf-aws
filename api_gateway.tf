resource "aws_acm_certificate" "api" {
  domain_name       = "api.mdekort.nl"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_dns_record" "api_cert_validate" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.terraform_remote_state.tf_cloudflare.outputs.mdekort_zone_id
  name    = trim(each.value.name, ".")
  type    = each.value.type
  ttl     = 60
  content = trim(each.value.record, ".")
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in cloudflare_dns_record.api_cert_validate : record.name]
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = aws_acm_certificate.api.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.api.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "cloudflare_dns_record" "mdekort_api" {
  zone_id = data.terraform_remote_state.tf_cloudflare.outputs.mdekort_zone_id
  name    = "api"
  type    = "CNAME"
  ttl     = 1
  proxied = true
  content = aws_api_gateway_domain_name.api.regional_domain_name
}

data "aws_iam_policy_document" "cloudwatch_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api-gateway-cloudwatch-logs"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume.json
}

data "aws_iam_policy" "cloudwatch" {
  name = "AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.id
  policy_arn = data.aws_iam_policy.cloudwatch.arn
}

resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
