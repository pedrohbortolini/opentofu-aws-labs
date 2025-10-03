## DATA SOURCES

data "aws_availability_zones" "my_az" {}

## RESOURCES


##VPC

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.3.0.0/16"

  # This sets the tenancy to shared hardware.
  # Note: Since "default" is the default value, this line is optional.
  instance_tenancy = "default"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {

  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.3.1.0/24"
  availability_zone = data.aws_availability_zones.my_az.names[0]

  tags = {
    Name = "${var.project_name}-public-subnet"
  }

}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "${var.project_name}-igw" }


}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main_public_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

}


##EC2

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "main_sg" {
  tags   = { Name = "${var.project_name}-sg" }
  vpc_id = aws_vpc.main_vpc.id

  egress  {

    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}


resource "aws_security_group_rule" "allow_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.main_sg.id
  description       = "Allow SSH Access"

}

resource "aws_security_group_rule" "allow_http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.main_sg.id
  description       = "Allow HTTP Access"

}


resource "aws_instance" "web" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/userdata.sh")
  associate_public_ip_address = true



  tags = {
    Name = "${var.project_name}-web"
  }
}


## KMS

resource "aws_kms_key" "s3_key" {
  description             = "KMS key for ${var.project_name} S3"
  deletion_window_in_days = 10
  tags = {
    Name = "${var.project_name}"
  }
}


resource "aws_kms_alias" "alias" {
  name          = "alias/${var.project_name}-s3-key"
  target_key_id = aws_kms_key.s3_key.id
}

##s3

resource "aws_s3_bucket" "site_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {

  bucket = aws_s3_bucket.site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}


## IAM

resource "aws_iam_role" "ec2_role" {

  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


resource "aws_iam_policy" "s3_kms_policy" {
  name   = "${var.project_name}-s3-kms-policy"
  policy = data.aws_iam_policy_document.s3_kms_policy.json
}

data "aws_iam_policy_document" "s3_kms_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.site_bucket.arn,
      "${aws_s3_bucket.site_bucket.arn}/*"
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.s3_key.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_kms_policy.arn
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}