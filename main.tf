provider "aws" {
    region = var.region  
}

#vpc
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}
#public_ip
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}
#Security Group
resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.main.id
    name="web-sg"
    description = "Allow Http 5000"
    

    ingress{
        to_port = 5000
        from_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        to_port = 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }  
}

#IAM role for codebuild
resource "aws_iam_role" "codebuild_role" {
    name="ci-cd-codebuild-role"
    assume_role_policy = jsonencode({
        Version="2012-10-17",
        Statement=[{
            Effect="Allow",
            Principal={
                Service="codebuild.amazonaws.com"
            },
            Action="sts:AssumeRole"
        }]
    })  
}
resource "aws_iam_role_policy_attachment" "codebuild_attach" {
    role=aws_iam_role.codebuild_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  
}

#IAM role for codepipeline
resource "aws_iam_role" "codepipeline_role" {
    name="ci-cd-codepipeline-role"
    assume_role_policy = jsonencode({
        Version="2012-10-17",
        Statement=[{
            Effect="Allow",
            Principal={
                Service="codepipeline.amazonaws.com"
            },
            Action="sts:AssumeRole"
        }]
    })  
}
resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
    role = aws_iam_role.codepipeline_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  
}
#S3 artifacts
resource "aws_s3_bucket" "artifacts_bucket" {
    bucket = "ci-cd-artifacts-${random_id.bucket_suffix.hex}"
}
#resource "aws_s3_bucket_acl" "bucket_acl" {
    #bucket=aws_s3_bucket.artifacts_bucket.id
    #acl="private"  
#}
resource "random_id" "bucket_suffix" {
    byte_length = 4  
}

#EC2 Instance
resource "aws_instance" "web" {
    ami="ami-0b09ffb6d8b58ca91"
    instance_type = "t3.micro"
    key_name = var.key_name
    subnet_id                   = aws_subnet.public.id
    vpc_security_group_ids      = [aws_security_group.web_sg.id]

    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                yum install python3 git -y
                pip3 install flask
                EOF
    
    tags={
        Name="CI-CD-EC2"
    }  
}



