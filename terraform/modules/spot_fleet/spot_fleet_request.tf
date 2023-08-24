
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  cidr_block        = cidrsubnet(var.private_cidr_start, 4, count.index)
  vpc_id            = var.vpc_id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "private-build-runners-${count.index}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = {
    Name = "bitbucket-build-runners-private"
  }

}

resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

data "template_file" "userdata" {
  count    = length(data.aws_availability_zones.available.names)
  template = file("${path.module}/templates/userdata.sh")
  vars = {
    count = count.index
  }
}
resource "aws_key_pair" "initial_key" {
  key_name   = "build_runners_initial_key"
  public_key = # "Initial pubkey to access instances"
}
resource "aws_spot_fleet_request" "build_runners" {
  iam_fleet_role      = "arn:aws:iam::111111111111:role/aws-ec2-spot-fleet-tagging-role"
  allocation_strategy = "diversified"
  fleet_type          = "request"
  target_capacity     = 3

  launch_specification {
    instance_type            = "r6a.xlarge"
    ami                      = "ami-009b16df9fcaac611"
    subnet_id                = aws_subnet.private[1].id
    iam_instance_profile_arn = aws_iam_instance_profile.runner_profile.arn
    key_name                 = aws_key_pair.initial_key.key_name
    user_data                = data.template_file.userdata[0].rendered

    root_block_device {
      volume_size = "128"
      volume_type = "gp2"
    }

    tags = {
      Name = "build-runners-0"
    }

  }

  launch_specification {
    instance_type            = "r6a.xlarge"
    ami                      = "ami-009b16df9fcaac611"
    iam_instance_profile_arn = aws_iam_instance_profile.runner_profile.arn
    subnet_id                = aws_subnet.private[1].id
    key_name                 = aws_key_pair.initial_key.key_name
    user_data                = data.template_file.userdata[1].rendered
    root_block_device {
      volume_size = "128"
      volume_type = "gp3"
    }
    tags = {
      Name = "build-runners-1"
    }

  }

  launch_specification {
    instance_type            = "r6a.xlarge"
    ami                      = "ami-009b16df9fcaac611"
    iam_instance_profile_arn = aws_iam_instance_profile.runner_profile.arn
    subnet_id                = aws_subnet.private[2].id
    key_name                 = aws_key_pair.initial_key.key_name
    user_data                = data.template_file.userdata[2].rendered

    root_block_device {
      volume_size = "128"
      volume_type = "gp3"
    }
    tags = {
      Name = "build-runners-2"
    }
  }
}
