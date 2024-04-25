variable "org_name" {}
variable "prj_name" {}
variable "user_csv" {}
variable "admin_csv" {}
variable "target_csv" {}
variable "host_catalog_name" {}
variable "window_host" {}
variable "window_ip" {}
variable "reader_user_role" {}
variable "admin_user_role" {}
variable "main_auth_method_id" {}
variable "main_user" {}
variable "main_password" {}
variable "hcp_boundary_addr" {}

locals {
  user   = csvdecode(file(var.user_csv))
  admin  = csvdecode(file(var.admin_csv))
  target = csvdecode(file(var.target_csv))
}