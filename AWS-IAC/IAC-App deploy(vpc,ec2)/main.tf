
variable "cidr_range" {
    description = "Value of cidr range"
    default = "172.16.0.0/16"
  
}
provider "aws" {
    region = "ap-south-1"
  
}


resource "aws_vpc" "demo_vpc" {
  cidr_block       = var.cidr_range
  instance_tenancy = "default"

  tags = {
    Name = "vpcdemo"
  }
}
resource "aws_subnet" "pub_subnet" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "pub_igw"
  }
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_security_group" "sgw" {
  name        = "sgw_demovpc"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = {
    Name = "sgw_demovpc"
  }
  
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgw.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgw.id
}

resource "aws_security_group_rule" "egress_allow_all" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sgw.id
}

resource "aws_instance" "app" {
    ami = "ami-07b69f62c1d38b012"
    instance_type = "t2.micro"
    key_name = "Demovpc-key"
    vpc_security_group_ids = [aws_security_group.sgw.id]
    subnet_id = aws_subnet.pub_subnet.id
    tags = {
      Name = "Appdeploy"
    }
    

connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/Pranesh/Downloads/Demovpc-key.pem")
    host = self.public_ip

}

provisioner "remote-exec" {
    inline = [ 
        "echo 'machine connected'",
        "sudo yum install -y httpd",
        "sudo systemctl start httpd",
        "sudo systemctl enable httpd",
        "sudo chown -R ec2-user:ec2-user /var/www/html",
    
     ]


}

provisioner "file" {
    source = "E:/new"
    destination = "/var/www/html"
  
}
}