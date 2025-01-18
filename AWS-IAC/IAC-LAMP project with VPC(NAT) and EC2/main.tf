variable "cidr_block" {
    description = "value_for_cidr" #variable for cidr block
    default = "192.168.0.0/16"
  
}

provider "aws" {           # Mention the provider
    region = "ap-south-1"
  
}

resource "aws_vpc" "vpc_app" {          # Create a vpc under one cidr
    cidr_block = var.cidr_block
    instance_tenancy = "default"
    tags = {
      Name="vpc_app"
    }
  
}

resource "aws_subnet" "publicapp_subnet" {   # create a public subnet 
    vpc_id = aws_vpc.vpc_app.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    tags = {
      Name= "publicapp_subnet"
    }
    depends_on = [ aws_vpc.vpc_app ]

  
}


resource "aws_subnet" "private_subnet" {   # create a private subnet 
    vpc_id = aws_vpc.vpc_app.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = false
    tags = {
      Name="private_subnet"
    }
    depends_on = [ aws_subnet.publicapp_subnet ]
  
}

resource "aws_internet_gateway" "igw_app" {    # create a internet gateway for the resourece to access internet
    vpc_id = aws_vpc.vpc_app.id
    tags = {
      Name="igw_app"
    }
    depends_on = [ aws_subnet.private_subnet ]
  
}
resource "aws_eip" "nat_ip" {               # create a elastic public ip for NAT gateway
    domain = "vpc"
    tags = {
      Name="nat_eip"
    }
    depends_on = [ aws_internet_gateway.igw_app ]
  
}

resource "aws_nat_gateway" "nat_priv" {    # Create a nat gateway for private subnet to access the internet under private sub
    tags = {
      Name= "nat_priv"
    }
    subnet_id = aws_subnet.publicapp_subnet.id
    connectivity_type = "public"
    allocation_id = aws_eip.nat_ip.id
    depends_on = [ aws_internet_gateway.igw_app ]

  
}

resource "aws_route_table" "public_rt" {        #create a public route and route to internet gateway
    vpc_id = aws_vpc.vpc_app.id
    route {
        gateway_id = aws_internet_gateway.igw_app.id
        cidr_block = "0.0.0.0/0"
    }
    tags = {
      Name= "public_rt"
    }
    depends_on = [ aws_nat_gateway.nat_priv ]
     
  
}

resource "aws_route_table" "private_rt" {  # Create a private route and route to NAT gateway
    tags = {
      Name="private_rt"
    }
    vpc_id = aws_vpc.vpc_app.id
    route {
        nat_gateway_id = aws_nat_gateway.nat_priv.id
        cidr_block = "0.0.0.0/0"
    }
    depends_on = [ aws_nat_gateway.nat_priv ]
  
}

resource "aws_route_table_association" "public" {  # Assosciate the public subnet 
    subnet_id = aws_subnet.publicapp_subnet.id
    route_table_id = aws_route_table.public_rt.id
   depends_on = [ aws_nat_gateway.nat_priv ]
  
}

resource "aws_route_table_association" "private" { # Associate the private subnet
    subnet_id = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private_rt.id
    depends_on = [ aws_nat_gateway.nat_priv ]
  
}

resource "aws_security_group" "public_sgw" {   # Create a security group for public instance
    name = "public_sgw"
    tags = {
      Name="public_sgw"
    }
    vpc_id = aws_vpc.vpc_app.id
    
  
}
resource "aws_security_group" "private_sgw" {  # Create a security group for private instance
    name = "private_sgw"
    tags = {
      Name="private_sgw"
    }
    vpc_id = aws_vpc.vpc_app.id
  
}

resource "aws_security_group_rule" "ingress_ssh_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sgw.id
}
resource "aws_security_group_rule" "ingress_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sgw.id
}

resource "aws_security_group_rule" "egress_allow_all_public" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_sgw.id
}

resource "aws_security_group_rule" "ingress_sql_private" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["192.168.1.0/24"]
  security_group_id = aws_security_group.private_sgw.id
}
resource "aws_security_group_rule" "ingress_ssh_private" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sgw.id
}

resource "aws_security_group_rule" "egress_allow_all_private" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private_sgw.id
}

resource "aws_instance" "web" {                   # Create a Public instance (for web) and associate with public subnet and sgw
    tags = {
      Name="Web"
    }
    ami = var.aws_ami
    instance_type = var.aws_instance_type
    subnet_id = aws_subnet.publicapp_subnet.id
    key_name = "appkey"
    vpc_security_group_ids = [aws_security_group.public_sgw.id]
    depends_on = [ aws_nat_gateway.nat_priv ]

    connection {                # connect to the public instance
    type = "ssh"
    user = "ec2-user"
    private_key = file("C:/Users/Pranesh/Downloads/appkey.pem")
    host = self.public_ip
    }

    provisioner "remote-exec" {     # by using provisioner install the req package for web server and php
        inline = [ 
        "echo 'machine connected'",
        "sudo yum install -y httpd php php-mysqlnd",
        "sudo systemctl start httpd",
        "sudo systemctl enable httpd",
        "sudo chown -R ec2-user:ec2-user /var/www/html"
    
     ]


}


    provisioner "file" {              # by using file provisioner copy the code from local to instance
    source = "E:/new2"
    destination = "/var/www/html"
    }

    provisioner "file" {               # by using file provisioner copy the keypair from local to public instance
    source = "E:/appkey.pem"
    destination = "/home/ec2-user/appkey.pem"
    }
    
}


resource "aws_instance" "database" {              # Create a Private instance (for database) and associate with private subnet and sgw
    tags = {
      Name="Database"
    }
    ami = var.aws_ami
    instance_type = var.aws_instance_type
    subnet_id = aws_subnet.private_subnet.id
    key_name = "appkey"
    vpc_security_group_ids = [aws_security_group.private_sgw.id]
    depends_on = [ aws_instance.web ]
    connection {                          # connect with the private instance through public instance using BASTION host, user, key
      type                = "ssh"  
      user                = "ec2-user"  
      private_key         = file("E:/appkey.pem")  
      host                = self.private_ip  
      bastion_host        = aws_instance.web.public_ip  
      bastion_user        = "ec2-user"  
      bastion_private_key = file("E:/appkey.pem")  
    }
    provisioner "remote-exec" {             # install the req mysql package
        inline = [
            "echo 'connected to machine'",
            "sudo yum install -y mariadb105-server",
            "sudo systemctl start mariadb",
            "sudo systemctl enable mariadb"
    ]

  }
}

     