data "aws_iam_policy_document" "ssm_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name}-profile"
  role = aws_iam_role.ssm_role.name
}