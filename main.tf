resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
  
}

resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id

    }

}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
  
}


resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.RT.id
  
}

resource "aws_security_group" "sg" {    
    name = "security-gp"
    vpc_id = aws_vpc.main.id

    ingress {
        description = "HTTP from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
    tags = {
      name = "Web-security"
    }
    }

resource "aws_s3_bucket" "sohilterraformprojectfirst011" {
    bucket = "sohilterraformprojectfirst011"
    
}


resource "aws_instance" "web1" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.sg.id ]
    subnet_id = aws_subnet.sub1.id
    user_data = base64encode(file("userdata.sh"))

  
}

resource "aws_instance" "web2" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.sg.id ]
    subnet_id = aws_subnet.sub2.id
    user_data = base64encode(file("userdata1.sh"))
  
}

#create Application Load balancer

resource "aws_lb" "myalb" {
    name = "myalb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.sg.id ]
    
    subnets= [aws_subnet.sub1.id, aws_subnet.sub2.id]

}

resource "aws_lb_target_group" "tg" {

    name = "mytg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id
    health_check {
      path = "/"
      port = "traffic-port"

    }
  
}

resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.web1.id
    port = 80
  
}
resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.web2.id
    port = 80
  
}

resource "aws_lb_listener" "listener1" {
    load_balancer_arn = aws_lb.myalb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      target_group_arn = aws_lb_target_group.tg.arn
      type = "forward"
    }
  
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}
