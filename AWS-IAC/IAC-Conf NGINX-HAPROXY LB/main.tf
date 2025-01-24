provider "aws" {              # Mention the provider
    region = "ap-south-1"
  
}

resource "aws_vpc" "vpc_lb" {  # Create a vpc under one cidr
    tags = {
      Name="vpc_lb"
    }
    cidr_block = var.cidr_block
    instance_tenancy = "default"

  
}

resource "aws_subnet" "public_lb" {     # create a public subnet 
    tags = {
      Name= "public_lb"
    }
      vpc_id= aws_vpc.vpc_lb.id
      cidr_block= "172.16.1.0/24"
      availability_zone = "ap-south-1a"
      map_public_ip_on_launch = true
      depends_on = [ aws_vpc.vpc_lb ]
    
}

resource "aws_subnet" "private_lb" {    # create a private subnet
    tags = {
      Name= "private_lb"
    }
    vpc_id = aws_vpc.vpc_lb.id
    cidr_block = "172.16.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = false
    depends_on = [ aws_subnet.public_lb ]

  
}

resource "aws_internet_gateway" "igw_lb" {  # create a internet gateway for the resourece to access internet
    tags = {
      Name= "igw_lb"
    }
    vpc_id = aws_vpc.vpc_lb.id
    depends_on = [ aws_subnet.private_lb ]
  
}

resource "aws_eip" "eip_lb" {    # create a elastic public ip for NAT gateway
    tags = {
      Name= "eip_lb"
    }
    domain = "vpc"
    depends_on = [ aws_internet_gateway.igw_lb ]
  
}

resource "aws_nat_gateway" "nat_lb" {   # Create a nat gateway for private subnet to access the internet under private sub
    tags = {
      Name= "nat_lb"
    }
    subnet_id = aws_subnet.public_lb.id
    connectivity_type = "public"
    allocation_id = aws_eip.eip_lb.id
    depends_on = [ aws_internet_gateway.igw_lb ]
  
}

resource "aws_route_table" "public_rt_lb" {  #create a public route and route to internet gateway
    vpc_id = aws_vpc.vpc_lb.id
    tags = {
      Name= "public_rt_lb"
    }
    route {
       gateway_id = aws_internet_gateway.igw_lb.id
        cidr_block = "0.0.0.0/0"
        
    }
    depends_on = [ aws_nat_gateway.nat_lb ]
  
}

resource "aws_route_table" "private_rt_lb" {    # Create a private route and route to NAT gateway
    vpc_id = aws_vpc.vpc_lb.id
    tags = {
      Name= "private_rt_lb"
    }
    route {
        gateway_id = aws_nat_gateway.nat_lb.id
        cidr_block = "0.0.0.0/0"
    }
    depends_on = [ aws_route_table.public_rt_lb ]
  
}

resource "aws_route_table_association" "public" {     # Assosciate the public subnet
    route_table_id = aws_route_table.public_rt_lb.id
    subnet_id = aws_subnet.public_lb.id
    depends_on = [ aws_route_table.private_rt_lb ]
  
}
resource "aws_route_table_association" "private" {       # Assosciate the private subnet
    route_table_id = aws_route_table.private_rt_lb.id
    subnet_id = aws_subnet.private_lb.id
    depends_on = [ aws_route_table_association.public ]
  
}

resource "aws_security_group" "public_sgw" {    # Create a security group for public instance
    vpc_id = aws_vpc.vpc_lb.id
    name = "pub_sgw_lb"
    tags = {
      Name= "pub_sgw_lb"
    }
    depends_on = [ aws_route_table_association.private ]
  
}

resource "aws_security_group" "private_sgw" {    # Create a security group for private instance
    vpc_id = aws_vpc.vpc_lb.id
    name = "private_sgw_lb"
    tags = {
      Name= "private_sgw_lb"
    }
    depends_on = [ aws_security_group.public_sgw ]
  
}

resource "aws_security_group_rule" "ingress_ssh_lb_pub" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public_sgw.id
  
}

resource "aws_security_group_rule" "ingress_http_lb_pub" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public_sgw.id
  
}

resource "aws_security_group_rule" "egress_allow_lb_pub" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.public_sgw.id   
  
}

resource "aws_security_group_rule" "ingress_ssh_lb_priv" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.private_sgw.id
  
}

resource "aws_security_group_rule" "ingress_http_lb_priv" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.private_sgw.id
  
}

resource "aws_security_group_rule" "egress_allow_lb_priv" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.private_sgw.id   
  
}

resource "aws_instance" "nginx_pub" {       # Create a Public instance (for nginx/ha proxy) server and associate with public subnet and sgw
    tags = {
      Name= "nginx_server"
    }
    ami = var.aws_ami
    instance_type = var.aws_instance
    key_name = "appkey"
    subnet_id = aws_subnet.public_lb.id
    vpc_security_group_ids = [aws_security_group.public_sgw.id]
    depends_on = [ aws_security_group.private_sgw ]

    connection {                          # connect to the public instance
      type = "ssh"
      private_key = file("E:/appkey.pem")
      user = "ec2-user"
      host = self.public_ip
    }

    provisioner "remote-exec" {      # by using provisioner install the req package for Nginx nd HA proxy ( yum install haproxy)
        inline = [ 
            "echo 'machine connected' ",
            "sudo yum install nginx -y",
            "sudo systemctl start nginx",
            "sudo systemctl enable nginx"

         ]
      
    }
    provisioner "file" {               # by using file provisioner copy the keypair from local to public instance
    source = "E:/appkey.pem"
    destination = "/home/ec2-user/appkey.pem"
    }
  
}

resource "aws_instance" "web_lb_1" {   # Create a Private instance nginix web server and associate with private subnet and sgw
    tags = {
      Name= "web_lb_1"
    }
    ami = var.aws_ami
    instance_type = var.aws_instance
    key_name = "appkey"
    subnet_id = aws_subnet.private_lb.id
    vpc_security_group_ids = [aws_security_group.private_sgw.id]
    depends_on = [ aws_instance.nginx_pub ]

    connection {                    # connect with the private instance through public instance using BASTION host, user, key
      type = "ssh"
      user = "ec2-user"
      private_key = file("E:/appkey.pem") 
      host = self.private_ip
      bastion_host = aws_instance.nginx_pub.public_ip
      bastion_user = "ec2-user"
      bastion_private_key = file("E:/appkey.pem") 
      
    }

    provisioner "remote-exec" {      #install the req package for web server
        inline = [  
            "sudo yum install nginx -y",
            "sudo systemctl start nginx",
            "sudo systemctl enable nginx",
            "sudo chown -R ec2-user:ec2-user /usr/share/nginx/html "
         ]

      
    }

    provisioner "file" {        # by using file provisioner copy the code file to machine
        source = "E:/new"
        destination = "/usr/share/nginx/html" 
      
    }

    provisioner "remote-exec" {
        inline = [  
            "echo 'machine again' ",
            "sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/new"
         ]
      
    }
  


}

resource "aws_instance" "web_lb_2" {  # Create a Private instance nginix web server and associate with private subnet and sgw
    tags = {
      Name= "web_lb_2"
    }
    ami = var.aws_ami
    instance_type = var.aws_instance
    key_name = "appkey"
    subnet_id = aws_subnet.private_lb.id
    vpc_security_group_ids = [aws_security_group.private_sgw.id]
    depends_on = [ aws_instance.web_lb_1 ]

    connection {                        # connect with the private instance through public instance using BASTION host, user, key
      type = "ssh"
      user = "ec2-user"
      private_key = file("E:/appkey.pem") 
      host = self.private_ip
      bastion_host = aws_instance.nginx_pub.public_ip
      bastion_user = "ec2-user"
      bastion_private_key = file("E:/appkey.pem") 
    }
 
    provisioner "remote-exec" {         #install the req package for web server
        inline = [  
            "sudo yum install nginx -y",
            "sudo systemctl start nginx",
            "sudo systemctl enable nginx",
            "sudo chown -R ec2-user:ec2-user /usr/share/nginx/html "
         ]

      
    }

    provisioner "file" {      # by using file provisioner copy the code file to machine
        source = "E:/new"
        destination = "/usr/share/nginx/html" 
      
    }

    provisioner "remote-exec" {
        inline = [  
            "echo 'machine again' ",
            "sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/new"
         ]
      
    }

  }

  output "web_instance_private_ip1" {           # output the private ip of the  private instance 
  value = aws_instance.web_lb_1.private_ip
}
output "web_instance_private_ip2" {
  value = aws_instance.web_lb_2.private_ip
}

