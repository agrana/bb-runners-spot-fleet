resource "aws_iam_instance_profile" "runner_profile" {
  name = "builder_instance_role"
  role = aws_iam_role.builderrole.name
}

resource "aws_iam_role" "builderrole" {
  name = "builder_instance_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ssmaccess" {
  name = "ssm_access_for_instances"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : # "Arn pattern for your parameters"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : # "Arn pattern for your parameters"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : # Your kms key used to decrypt encrypt parameters
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm-policy-attach" {
  name       = "SSM Instance Attach"
  roles      = [aws_iam_role.builderrole.name]
  policy_arn = aws_iam_policy.ssmaccess.arn
}
