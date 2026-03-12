resource "aws_cloudfront_function" "no_index" {
  name    = "no-index"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite request which request a folder without trailing index.js"
  code    = file("${path.module}/files/no_index.js")
}
