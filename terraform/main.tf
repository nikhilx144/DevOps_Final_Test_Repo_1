resource "aws_security_group" "test_sg" {
    name = "test_sg"
    description = "Security Group for the EC2 Instance"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
    }

    egress {
        from_port = 0
        to_port = 0
        # Together they mean any port
        protocol = "-1" # All possible protocols
        cidr_blocks = ["0.0.0.0/0"] # Allow all protocols (any port) from anywhere
    }
}

resource "aws_key_pair" "deployer_key" {
    key_name = "deployer_key"
    # public_key = file("${path.module}/id_rsa.pub")
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDS05RiC3iwF5ISZkuPbivKH8IifYyve5TXKPnlKDvpv4hd9+9gCqmCi7Hn40dgNzyfo0URaCVFVBDR9jmelRfgsQQ5qIcqX3Mam9xnmWufMjriji2v+N5qT8FONk4paHj4di3dzrV5Vb1rMUybOU4rIA+mhCezjsbShMtvsVGTOxJTol65UZn5SsrKcBsTgxvzAmEnm95hVOcFvz4QooxNwAFMjkFMaq0/9HpOFbvBjsDuDp7QH4eDgLTnINAfP4PWpeuBtoMXXLdspLw/RskNW/fds3/ivFMlaBLkTiN3MC3mUNMau4iTeCY7BfLtKsIhId1AznyMJXOIDKz+9SxSZl/yKgJwtXqpSXnt75fCIkbXxGacIru0Hd0jAwWx8ZVYF6zYjdY+uZ9epSQCgTGBBV8aXivltvnvUykCPX5zj4tGdJYq0Fgh2YK/BKzSUfQvuzui9uzk8Sc7uzLQ8dkkH1LaherfNx6u2iKETO/vBLiUmha9UXz4914t6+y5z9wNrAwkA825IP0DuFA5ccAGAs0q1vrkNmmIdHhlmhrnrPeW6w6Ifh/UifZWjfU8+0hx8paeRTnCcd/snnVpb8EZIH6F+D5Pc+bKS5wPOy7/GpKR5EK9CMs5zWA6saNxaItZoIEbClLMBSnduVFqx9/uG4+mCo/Lt7+WiXBi28Ua8w== nikhi@Nikhil"
}

resource "aws_instance" "web_server" {
    ami = var.ami_id
    instance_type = var.instance_type
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    key_name = aws_key_pair.deployer_key.key_name
    vpc_security_group_ids = [aws_security_group.test_sg.id]

    user_data = <<-EOF
                #!/bin/bash
                sudo dnf update -y
                sudo dnf install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -a -G docker ec2-user
                EOF

    tags = {
        Name = "DevOpsCICDPrac"
    }
}


# IAM Role that allows the EC2 service to assume it
resource "aws_iam_role" "ec2_role" {
    name = "ec2-ecr-access-role"
    
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

# Attaches ECR Read Only Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "ecr_read_only" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Creates an instance profile to attach the role to an EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2-ecr-access-profile"
    role = aws_iam_role.ec2_role.name
}