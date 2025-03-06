variable "iam_role_name" {
  type        = string
  description = "Name of the IAM role for EBS CSI driver to use"
}

variable "kubernetes_oidc_url" {
  type        = string
  description = "URL of the OIDC provider of the EKS cluster that hosts EBS CSI driver"
}

variable "kubernetes_oidc_arn" {
  type        = string
  description = "arn of the OIDC provider of the EKS cluster that hosts EBS CSI driver"
}

variable "kubernetes_namespace" {
  type        = string
  description = "The k8s namespace where EBS CSI driver is in"
}

variable "kubernetes_serviceaccount" {
  type        = string
  description = "The k8s service account that EBS CSI driver uses"
}

variable "iam_role_permission_boundary_arn" {
  type        = string
  description = ""
}

variable "aws_account_id" {
  type        = string
  description = "ID of the AWS account that is calling the module, use data.aws_caller_identity.current.account_id"
}