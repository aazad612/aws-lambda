resource "aws_key_pair" "default" {
  key_name   = "${var.project_prefix}-key"
  public_key = file("~/.ssh/my-aws-key.pub") # path to your public SSH key
}