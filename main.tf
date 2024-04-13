variable "use_case" {
  default = "tf-aws-ec2_autopatch"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_resourcegroups_group" "example" {
  name        = "tf-rg-example-${random_string.suffix.result}"
  description = "Resource group for example resources"

  resource_query {
    query = <<JSON
    {
      "ResourceTypeFilters": [
        "AWS::AllSupported"
      ],
      "TagFilters": [
        {
          "Key": "Owner",
          "Values": ["John Ajera"]
        },
        {
          "Key": "UseCase",
          "Values": ["${var.use_case}"]
        }
      ]
    }
    JSON
  }

  tags = {
    Name    = "tf-rg-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_iam_role" "ec2-ssm" {
  name = "tf-iam-role-ec2-ssm-example-${random_string.suffix.result}"
  path = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "tf-iam-role-ec2-ssm-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

data "aws_iam_policy" "ec2-ssm" {
  name = "AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ec2-ssm" {
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = data.aws_iam_policy.ec2-ssm.arn
}

resource "aws_iam_instance_profile" "ec2-ssm" {
  name = "tf-iam-instance-profile-example-${random_string.suffix.result}"
  role = aws_iam_role.ec2-ssm.name

  tags = {
    Name    = "tf-iam-instance-profile-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

data "aws_ami" "amzn2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "tf-vpc-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name    = "tf-ig-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name    = "tf-rt-public"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"

  tags = {
    Name    = "tf-subnet-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_instance" "server1" {
  ami                  = data.aws_ami.amzn2.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.example.id
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm.name
  user_data = templatefile("external/bootstrap.tpl", {
    FQDN = "tf-ec2-server1-example-${random_string.suffix.result}"
  })

  tags = {
    Name       = "tf-ec2-server1-example-${random_string.suffix.result}"
    Owner      = "John Ajera"
    UseCase    = var.use_case
    PatchGroup = "amzn2-production"
  }
}

resource "aws_instance" "server2" {
  ami                  = data.aws_ami.amzn2.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.example.id
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm.name
  user_data = templatefile("external/bootstrap.tpl", {
    FQDN = "tf-ec2-server2-example-${random_string.suffix.result}"
  })

  tags = {
    Name       = "tf-ec2-server2-example-${random_string.suffix.result}"
    Owner      = "John Ajera"
    UseCase    = var.use_case
    PatchGroup = "amzn2-production"
  }
}

resource "aws_instance" "server3" {
  ami                  = data.aws_ami.amzn2.id
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.example.id
  iam_instance_profile = aws_iam_instance_profile.ec2-ssm.name
  user_data = templatefile("external/bootstrap.tpl", {
    FQDN = "tf-ec2-server3-example-${random_string.suffix.result}"
  })

  tags = {
    Name       = "tf-ec2-server3-example-${random_string.suffix.result}"
    Owner      = "John Ajera"
    UseCase    = var.use_case
    PatchGroup = "amzn2-production"
  }
}

resource "aws_ssm_patch_baseline" "amzn2" {
  name             = "tf-patch-baseline-amzn2-example-${random_string.suffix.result}"
  description      = "Patch Baseline for Amazon Linux 2 Provided by AWS."
  operating_system = "AMAZON_LINUX_2"

  approval_rule {
    approve_after_days  = 7
    compliance_level    = "UNSPECIFIED"
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  approval_rule {
    approve_after_days  = 7
    compliance_level    = "UNSPECIFIED"
    enable_non_security = false

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }

  global_filter {
    key    = "PRODUCT"
    values = ["AmazonLinux2"]
  }
}

resource "aws_ssm_patch_group" "example" {
  baseline_id = aws_ssm_patch_baseline.amzn2.id
  patch_group = "amzn2-production"
}

resource "aws_ssm_maintenance_window" "example" {
  name                       = "tf-amzn2-production-maint-window-example-${random_string.suffix.result}"
  schedule                   = "cron(0 0 ? * SUN *)"
  duration                   = 1
  cutoff                     = 0
  allow_unassociated_targets = false
  enabled                    = true

  tags = {
    Name    = "tf-amzn2-production-maint-window-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_ssm_maintenance_window_target" "example" {
  window_id     = aws_ssm_maintenance_window.example.id
  name          = "tf-amzn2-production-patching-target-example-${random_string.suffix.result}"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:PatchGroup"
    values = ["amzn2-production"]
  }
}

data "aws_iam_role" "ssm-patch-manager" {
  name = "AWSServiceRoleForAmazonSSM"
}

resource "aws_cloudwatch_log_group" "ssm-logs" {
  name = "/aws/vendedlogs/ssm/example-${random_string.suffix.result}"

  tags = {
    Name    = "tf-log-group-sfn-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_s3_bucket" "example" {
  bucket        = "tf-s3-bucket-ec2-autopatch-example-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name    = "tf-s3-bucket-ec2-autopatch-example-${random_string.suffix.result}"
    Owner   = "John Ajera"
    UseCase = var.use_case
  }
}

resource "aws_ssm_maintenance_window_task" "ssm-patch-install" {
  name      = "tf-amzn2-production-patching-example-${random_string.suffix.result}"
  window_id = aws_ssm_maintenance_window.example.id

  task_arn         = "AWS-RunPatchBaseline"
  task_type        = "RUN_COMMAND"
  service_role_arn = data.aws_iam_role.ssm-patch-manager.arn

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.example.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment          = "Amazon Linux 2 Patch Baseline Install"
      timeout_seconds  = 3600
      document_version = "$LATEST"

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.ssm-logs.id
        cloudwatch_output_enabled = true
      }
      
      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      output_s3_bucket = "tf-s3-bucket-ec2-autopatch-example-${random_string.suffix.result}"
      output_s3_key_prefix = "ssm-patch-install/"
    }
  }

  cutoff_behavior = "CANCEL_TASK"
  max_concurrency = 1
  max_errors      = 3
  priority        = 1
}

resource "aws_ssm_association" "ssm-patch-scan" {
  name             = "AWS-RunPatchBaseline"
  association_name = "tf-ssm-agent-update-example-${random_string.suffix.result}"

  schedule_expression = "cron(0 12 * * ? *)"
  max_concurrency     = 1
  max_errors          = 3

  parameters = {
    Operation = "Scan"
  }

  targets {
    key    = "tag:PatchGroup"
    values = ["amzn2-production"]
  }

  output_location {
    s3_bucket_name = "tf-s3-bucket-ec2-autopatch-example-${random_string.suffix.result}"
    s3_key_prefix  = "ssm-patch-scan/"
  }

  depends_on = [
    aws_s3_bucket.example
  ]
}

resource "aws_ssm_association" "ssm-agent-update" {
  name                = "AWS-UpdateSSMAgent"
  association_name    = "tf-ssm-agent-update-example-${random_string.suffix.result}"
 
  schedule_expression = "cron(0 0 ? * SAT *)"
  max_concurrency     = 1
  max_errors          = 3

  targets {
    key    = "tag:PatchGroup"
    values = ["amzn2-production"]
  }

  output_location {
    s3_bucket_name = "tf-s3-bucket-ec2-autopatch-example-${random_string.suffix.result}"
    s3_key_prefix  = "ssm-agent-update/"
  }

  depends_on = [
    aws_s3_bucket.example
  ]
}
