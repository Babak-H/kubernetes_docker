data "aws_iam_policy" "ebs_csi_managed_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}