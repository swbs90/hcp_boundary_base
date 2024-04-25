provider "boundary" {
  addr                            = var.hcp_boundary_addr
  auth_method_id                  = var.main_auth_method_id # changeme
  password_auth_method_login_name = var.main_user           # changeme
  password_auth_method_password   = var.main_password       # changeme
}