provider "aws" {         #creating provider with alias name for mumbai
    alias = "mumbai"
    region = "ap-south-1"

  
}

provider "aws" {      #creating provider with alias name for singapore
    alias = "singapore"
    region = "ap-southeast-1"
  
}

resource "aws_vpc" "mumbai_vpc" { #creating vpc for webserver instances in mumbai
    tags = {
      Name= "Mumbai_vpc"

    }
    provider = aws.mumbai
    cidr_block = var.cidr_block_mumbai
    instance_tenancy = "default"
    
}

resource "aws_vpc" "mumbai_server_git" {  #creating vpc for instance contain webpage in mumbai
    tags = {
      Name= "mumbai_servergit_vpc"
    }
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    provider = aws.mumbai
  
}

resource "aws_vpc" "singapore_vpc" { #creating vpc for webserver instances in singapore
    tags = {
      Name= "singapore_vpc"
    }
    provider = aws.singapore
    cidr_block = var.cidr_block_singapore
    instance_tenancy = "default"
  
}

resource "aws_subnet" "git_server_pub_sub" {  #creating public subnet for instance contain webpage
    vpc_id = aws_vpc.mumbai_server_git.id
    provider = aws.mumbai
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
    depends_on = [ aws_vpc.mumbai_server_git]
  
}

resource "aws_subnet" "git_pub_sub1" {   #creating public subnet for instance contain websever in az1 mumbai
    vpc_id = aws_vpc.mumbai_vpc.id
    provider = aws.mumbai
    cidr_block = "172.16.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"
    depends_on = [ aws_subnet.git_server_pub_sub ]
  
}

resource "aws_subnet" "git_pub_sub2" { #creating public subnet for instance contain webserver in az2 mumbai
    vpc_id = aws_vpc.mumbai_vpc.id
    provider = aws.mumbai
    cidr_block = "172.16.3.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"
    depends_on = [ aws_subnet.git_pub_sub1 ]
  
}

resource "aws_subnet" "git_pub_singapore_sub1" { #creating public subnet for instance contain webserver in az1 singapore
    provider = aws.singapore
    vpc_id = aws_vpc.singapore_vpc.id
    cidr_block = "192.168.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-southeast-1a"
    depends_on = [ aws_vpc.singapore_vpc ]
  
}

resource "aws_subnet" "git_pub_singapore_sub2" {  #creating public subnet for instance contain webserver in az2 singapore
    provider = aws.singapore
    vpc_id = aws_vpc.singapore_vpc.id
    cidr_block = "192.168.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-southeast-1b"
    depends_on = [ aws_subnet.git_pub_singapore_sub1]
  
}

resource "aws_internet_gateway" "igw_mumbai_git" { #creating internet gateway for instances
    tags = {
      Name= "igw_mumbai_git"

    }
    vpc_id = aws_vpc.mumbai_vpc.id
    provider = aws.mumbai
    depends_on = [ aws_subnet.git_pub_sub2 ]
  
}
resource "aws_internet_gateway" "igw_git" {
    vpc_id = aws_vpc.mumbai_server_git.id
    provider = aws.mumbai
    depends_on = [ aws_subnet.git_server_pub_sub ]
  
}

resource "aws_internet_gateway" "igw_singapore_git" {
    tags = {
      Name= "igw_singapore_git"
    }
    vpc_id = aws_vpc.singapore_vpc.id
    provider = aws.singapore
    depends_on = [ aws_subnet.git_pub_singapore_sub2 ]
  
}

resource "aws_route_table" "pub_git" {    #creating route table and adding the igw route to the RT
    vpc_id = aws_vpc.mumbai_server_git.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_git.id
    }
    provider = aws.mumbai
    depends_on = [ aws_internet_gateway.igw_git ]
  

}

resource "aws_route_table" "pub_mum_git_rt" {
    vpc_id = aws_vpc.mumbai_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_mumbai_git.id
    }
    provider = aws.mumbai
    tags = {
      Name="pub_mum_git_rt"
    }
    depends_on = [ aws_internet_gateway.igw_mumbai_git ]

  
}

resource "aws_route_table" "pub_rt_singapore" {
    vpc_id = aws_vpc.singapore_vpc.id 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_singapore_git.id
    }
    provider = aws.singapore
    tags = {
      Name= "pub_sing_git_rt"
    }
    depends_on = [ aws_internet_gateway.igw_singapore_git ]
     
  
}

resource "aws_route_table_association" "server_git_asso" { #associating the public subnet in rt for instance contain webpage
    route_table_id = aws_route_table.pub_git.id
    subnet_id = aws_subnet.git_server_pub_sub.id
    depends_on = [ aws_route_table.pub_git ]
    provider = aws.mumbai
  
}
 
resource "aws_route_table_association" "mum_web1" {  #associating the 1nd subnet in rt mumbai
    route_table_id = aws_route_table.pub_mum_git_rt.id
    subnet_id = aws_subnet.git_pub_sub1.id
    depends_on = [ aws_route_table.pub_mum_git_rt ]
    provider = aws.mumbai
  
}

resource "aws_route_table_association" "mum_web2" { #associating the 2nd subnet in rt mumbai
    route_table_id = aws_route_table.pub_mum_git_rt.id
    subnet_id = aws_subnet.git_pub_sub2.id
    provider = aws.mumbai
    depends_on = [ aws_route_table.pub_mum_git_rt ]
  
}

resource "aws_route_table_association" "sig_web1" {  #associating the 1nd subnet in rt singapore
    route_table_id = aws_route_table.pub_rt_singapore.id
    subnet_id = aws_subnet.git_pub_singapore_sub1.id
    provider = aws.singapore
    depends_on = [ aws_route_table.pub_rt_singapore ]
  
}

resource "aws_route_table_association" "sig_web2" { #associating the 2nd subnet in rt singapore
    route_table_id = aws_route_table.pub_rt_singapore.id
    subnet_id = aws_subnet.git_pub_singapore_sub2.id
    provider = aws.singapore
    depends_on = [ aws_route_table.pub_rt_singapore ]
  
}

resource "aws_security_group" "server_git" {    # Create a security group for instance contain webpage
    vpc_id = aws_vpc.mumbai_server_git.id
    name = "server_git"
    tags = {
      Name= "server_git"
    }
    depends_on = [ aws_route_table_association.server_git_asso ]
    provider = aws.mumbai
}

resource "aws_security_group" "web_git" {    # Create a security group for mumbai region instance
    vpc_id = aws_vpc.mumbai_vpc.id
    name = "web_git"
    tags = {
      Name= "web_git"
    }
    depends_on = [ aws_route_table_association.mum_web2 ]
    provider = aws.mumbai
}

resource "aws_security_group" "web_sig_git" {    # Create a security group for singapore region instance
    vpc_id = aws_vpc.singapore_vpc.id
    name = "web_sig_git"
    tags = {
      Name= "web_sig_git"
    }
    depends_on = [ aws_route_table_association.sig_web2 ]
    provider = aws.singapore
}


resource "aws_security_group_rule" "ingress_ssh_git_server" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.server_git.id
    provider = aws.mumbai
  
}

resource "aws_security_group_rule" "ingress_http_git_server" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.server_git.id
    provider = aws.mumbai
  
}

resource "aws_security_group_rule" "egress_allow_git_sever" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.server_git.id 
    provider = aws.mumbai 
  
}

resource "aws_security_group_rule" "ingress_ssh_web_mumbai" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_git.id
    provider = aws.mumbai
  
}

resource "aws_security_group_rule" "ingress_http_web_mumbai" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_git.id
    provider = aws.mumbai
}

resource "aws_security_group_rule" "egress_allow_web_mumbai" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.web_git.id
    provider = aws.mumbai
  
}

resource "aws_security_group_rule" "ingress_ssh_web_sing" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_sig_git.id
    provider = aws.singapore
  
}

resource "aws_security_group_rule" "ingress_http_web_sing" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.web_sig_git.id
    provider = aws.singapore
  
}

resource "aws_security_group_rule" "egress_allow_web_sing" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.web_sig_git.id 
    provider = aws.singapore  
  
}

resource "aws_instance" "git_server" {  #instance to push the webpage to github
    tags = {
      Name= "git_server"
    }
    provider = aws.mumbai
    ami = var.aws_ami
    instance_type = var.aws_instance
    key_name = "appkey"
    subnet_id = aws_subnet.git_server_pub_sub.id
    vpc_security_group_ids = [aws_security_group.server_git.id]
    depends_on = [ aws_security_group.server_git ]

    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("E:/appkey.pem")
      host = self.public_ip
    }

    provisioner "remote-exec" { 
        inline = [  
            "echo 'machine connected'",
            "sudo yum install git -y",
            "sudo git config --global user.name 'Pranesh110' ",
            "sudo git config --global user.mail 'mail2pranesh0@gmail.com'"
         ]
      
    }
  
}

resource "aws_instance" "web_1_lb" {   #creatin instance containing web1 in az1
    provider = aws.mumbai
    tags = {
      Name= "web_1_lb_az1"
      
    }
      ami= var.aws_ami
      instance_type= var.aws_instance
      key_name = "appkey"
      subnet_id = aws_subnet.git_pub_sub1.id
      vpc_security_group_ids = [aws_security_group.web_git.id]
      depends_on = [ aws_security_group.web_git ]

      connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("E:/appkey.pem")
        host = self.public_ip
      }

      provisioner "remote-exec" {  #by using provisioner installing req package of git and httpd
        inline = [  
            "echo 'machine connected web1'",
            "sudo yum install httpd git -y",
            "sudo systemctl start httpd",
            "sudo systemctl enable httpd",
            "sudo chown -R ec2-user:ec2-user /var/www/html",
            "sudo git config --global user.name 'Pranesh110' ",
            "sudo git config --global user.mail 'mail2pranesh0@gmail.com'"
            
         ]
        
}
}

resource "aws_instance" "web_1_az2" {  #creatin instance containing web1 in az 2
    provider = aws.mumbai
    tags = {
      Name= "web_1_lb_az2"
      
    }
      ami= var.aws_ami
      instance_type= var.aws_instance
      key_name = "appkey"
      subnet_id = aws_subnet.git_pub_sub2.id
      vpc_security_group_ids = [aws_security_group.web_git.id]
      depends_on = [ aws_instance.web_1_lb ]

      connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("E:/appkey.pem")
        host = self.public_ip
      }

      provisioner "remote-exec" {  #by using provisioner installing req package of git and httpd
        inline = [  
            "echo 'machine connected web1-az2'",
            "sudo yum install httpd git -y",
            "sudo systemctl start httpd",
            "sudo systemctl enable httpd",
            "sudo chown -R ec2-user:ec2-user /var/www/html",
            "sudo git config --global user.name 'Pranesh110'",
            "sudo git config --global user.mail 'mail2pranesh0@gmail.com'"
            
         ]
        
}
}
resource "aws_instance" "web_2_az1" { #creatin instance containing web2 in az 1
    provider = aws.singapore
    tags = {
      Name= "web_2_lb_az1"
      
    }
      ami= var.aws_ami_si
      instance_type= var.aws_instance
      key_name = "lab"
      subnet_id = aws_subnet.git_pub_singapore_sub1.id
      vpc_security_group_ids = [aws_security_group.web_sig_git.id]
      depends_on = [ aws_security_group.web_sig_git]

      connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("E:/lab.pem")
        host = self.public_ip
      }

      provisioner "remote-exec" {  #by using provisioner installing req package of git and httpd
        inline = [  
            "echo 'machine connected web2'",
            "sudo yum install httpd git -y",
            "sudo systemctl start httpd",
            "sudo systemctl enable httpd",
            "sudo chown -R ec2-user:ec2-user /var/www/html",
            "sudo git config --global user.name 'Pranesh110' ",
            "sudo git config --global user.mail 'mail2pranesh0@gmail.com'"
            
         ]
        
}
}

resource "aws_instance" "web_2_az2" { #creatin instance containing web2 
    provider = aws.singapore
    tags = {
      Name= "web_2_lb_az2"
      
    }
      ami= var.aws_ami_si
      instance_type= var.aws_instance
      key_name = "lab"
      subnet_id = aws_subnet.git_pub_singapore_sub2.id
      vpc_security_group_ids = [aws_security_group.web_sig_git.id]
      depends_on = [ aws_instance.web_2_az1]

      connection {
        type = "ssh"
        user = "ec2-user"
        private_key = file("E:/lab.pem")
        host = self.public_ip
      }

      provisioner "remote-exec" {   #by using provisioner installing req package of git and httpd
        inline = [  
            "echo 'machine connected web2'",
            "sudo yum install httpd git -y",
            "sudo systemctl start httpd",
            "sudo systemctl enable httpd",
            "sudo chown -R ec2-user:ec2-user /var/www/html",
            "sudo git config --global user.name 'Pranesh110' ",
            "sudo git config --global user.mail 'mail2pranesh0@gmail.com'"
            
         ]
        
}
}

resource "aws_security_group" "sgw_lb_sing" {    # Create a security group for lb singapore
    vpc_id = aws_vpc.singapore_vpc.id
    name = "sgw_lb_sing"
    tags = {
      Name= "sgw_lb_sing"
    }
    depends_on = [ aws_instance.web_2_az2 ]
    provider = aws.singapore
}


resource "aws_security_group_rule" "ingress_http_lb_server" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sgw_lb_sing.id
    provider = aws.singapore
  
}

resource "aws_security_group_rule" "egress_allow_lb_sever" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.sgw_lb_sing.id
    provider = aws.singapore
  
}

resource "aws_security_group" "lb_mumbai" {    # Create a security group for lb mumbai
    vpc_id = aws_vpc.mumbai_vpc.id
    name = "sgw_lb_mumbai"
    tags = {
      Name= "sgw_lb_mumbai"
    }
    depends_on = [ aws_instance.web_1_az2 ]
    provider = aws.mumbai
}



resource "aws_security_group_rule" "ingress_http_lb_mumbai" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lb_mumbai.id
    provider = aws.mumbai
  
}

resource "aws_security_group_rule" "egress_allow_lb_mumb" {
    type = "egress"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    security_group_id = aws_security_group.lb_mumbai.id
    provider = aws.mumbai 
  
}

resource "aws_elb" "mumbai_lb" {  #creating a Load balancer on mumbai region
    name = "mumbai-lb"
    provider = aws.mumbai
    internal = false
    security_groups = [aws_security_group.lb_mumbai.id]
    subnets = [aws_subnet.git_pub_sub1.id, aws_subnet.git_pub_sub2.id]
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 300

    listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    health_check {
      target = "HTTP:80/web1/web1.html/"
      interval = 5
      timeout = 2
      healthy_threshold = 2
      unhealthy_threshold = 2

    }
  
}

resource "aws_elb_attachment" "web1_az1" { #attach the instance to the lb
    provider = aws.mumbai
    elb = aws_elb.mumbai_lb.id
    instance= aws_instance.web_1_lb.id
    
  
}

resource "aws_elb_attachment" "web1_az2" { #attach the instance to the lb
    provider = aws.mumbai
    elb = aws_elb.mumbai_lb.id
    instance = aws_instance.web_1_az2.id
  
}

resource "aws_elb" "sing_lb" {  #creating a Load balancer on singapore region
    provider = aws.singapore
    name = "lb-singapore"
    internal = false
    security_groups = [ aws_security_group.sgw_lb_sing.id ]
    subnets = [ aws_subnet.git_pub_singapore_sub1.id, aws_subnet.git_pub_singapore_sub2.id ]
    cross_zone_load_balancing = true
    connection_draining = true
    connection_draining_timeout = 300

    listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    health_check {
      target = "HTTP:80/web2/web2.html/"
      interval = 5
      timeout = 2
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}

resource "aws_elb_attachment" "web2_az1_lb" { #attach the instance to the lb
    provider = aws.singapore
    elb = aws_elb.sing_lb.id
    instance = aws_instance.web_2_az1.id
  
}

resource "aws_elb_attachment" "web2_az2_lb" { #attach the instance to the lb
    provider = aws.singapore
    elb = aws_elb.sing_lb.id
    instance = aws_instance.web_2_az2.id
  
}










