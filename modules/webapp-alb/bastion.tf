resource "aws_instance" "bastion" {
  instance_type          = "t2.micro"
  key_name               = "pokus"
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.public_to_bastion.id]

  tags = var.tags
}
