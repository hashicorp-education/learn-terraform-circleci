terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "hashicorp-rachel"

    workspaces {
      name = "learn-terraform-circleci"
    }
  }
}
provider "aws" {
  region = var.region
}

provider "template" {
}

resource "aws_iam_user" "circleci" {
  name = var.user
  path = "/system/"
}

resource "aws_iam_access_key" "circleci" {
  user = aws_iam_user.circleci.name
}

data "template_file" "circleci_policy" {
  template = file("circleci_s3_access.tpl.json")
  vars = {
    s3_bucket_arn = aws_s3_bucket.portfolio.arn
  }
}

resource "local_file" "circle_credentials" {
  filename = "tmp/circleci_credentials"
  content  = "${aws_iam_access_key.circleci.id}\n${aws_iam_access_key.circleci.secret}"
}

resource "aws_iam_user_policy" "circleci" {
  name   = "AllowCircleCI"
  user   = aws_iam_user.circleci.name
  policy = data.template_file.circleci_policy.rendered
}

resource "aws_s3_bucket" "app" {
  tags = {
    Name = "App Bucket"
  }

  bucket = "${var.app}.${var.label}"
  acl    = "public-read"

  website {
    index_document = "${var.app}.html"
    error_document = "error.html"
  }
  force_destroy = true

}

resource "aws_s3_bucket_object" "app" {
  acl          = "public-read"
  key          = "index.html"
  bucket       = aws_s3_bucket.app.id
  content      = file("${path.module}/assets/index.html")
  content_type = "text/html"

}

output "Endpoint" {
  value = aws_s3_bucket.app.website_endpoint
}
