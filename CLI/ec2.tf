resource "aws_instance" "test_ami" {
  ami           = "ami-0c031a79ffb01a803" # ubuntu 20.04 (64bit, x86)
  instance_type = "t3.micro"
  tags = {
    Name = "myUbuntu"
  }
}