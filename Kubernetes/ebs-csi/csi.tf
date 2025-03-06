resource "aws_iam_role" "ebs_csi_driver" {
  name = var.iam_role_name
  path = "/"
  permissions_boundary = var.iam_role_permission_boundary_arn
  
  assume_role_policy = jsondecode({
    version = "2012-10-17"
    statement = [
        Effect = "Allow",
        Action = "sts:AssumeRoleWithWebIdentity",
        Principal = {
            Federated = var.kubernetes_oidc_arn
        }
        Condition = {
            StringEquals = {
                "${replace(var.kubernetes_oidc_url, "https://", "")}:sub" = "system:serviceaccount:${var.kubernetes_namespace}:${var.kubernetes_serviceaccount}"
                "${replace(var.kubernetes_oidc_url, "https://", "")}:aud" = "sts.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.ebs_csi_driver.name
    policy_arn = data.aws_iam_policy.ebs_csi_managed_policy.arn
}

resource "aws_iam_role_policy" "ebs_csi_driver" {
  name   = "${var.iam_role_name}-kms-policy"
  role   = aws_iam_role.ebs_csi_driver.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": ["arn:aws:kms:eu-west-2:${var.aws_account_id}:key/*"],
      "Condition": {
        "Bool": {
          "kms:GrantIsForAWSResource": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": ["arn:aws:kms:eu-west-2:${var.aws_account_id}:key/*"]
    }
  ]
}
EOF
}