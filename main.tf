resource "boundary_scope" "org" {
  name                     = var.org_name
  description              = "My first scope!"
  scope_id                 = "global"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = var.prj_name
  description            = "My first scope!"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_auth_method" "password" {
  scope_id = boundary_scope.org.id
  type     = "password"
}

resource "boundary_account_password" "user_pwd" {
  for_each       = { for rule in local.user : rule.key => rule }
  auth_method_id = boundary_auth_method.password.id
  login_name     = each.value.login_name
  password       = each.value.password
}

resource "boundary_account_password" "admin_pwd" {
  for_each       = { for rule in local.admin : rule.key => rule }
  auth_method_id = boundary_auth_method.password.id
  login_name     = each.value.login_name
  password       = each.value.password
}

resource "boundary_user" "user" {
  for_each    = { for rule in local.user : rule.key => rule }
  name        = each.value.name
  description = each.value.description
  account_ids = [boundary_account_password.user_pwd[each.key].id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_user" "admin" {
  for_each    = { for rule in local.admin : rule.key => rule }
  name        = each.value.name
  description = each.value.description
  account_ids = [boundary_account_password.admin_pwd[each.key].id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_host_catalog_static" "static" {
  name        = var.host_catalog_name
  description = "My first host catalog!"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host" "first" {
  type            = "static"
  name            = var.window_host
  description     = "My first host!"
  address         = var.window_ip
  host_catalog_id = boundary_host_catalog_static.static.id
}

resource "boundary_host_set_static" "rdp" {
  host_catalog_id = boundary_host_catalog_static.static.id
  host_ids = [
    boundary_host.first.id,
  ]
}

resource "boundary_target" "rdp" {
  for_each     = { for rule in local.target : rule.key => rule }
  name         = each.value.target_name
  description  = each.value.description
  type         = each.value.type
  default_port = each.value.default_port
  scope_id     = boundary_scope.project.id
  host_source_ids = [
    boundary_host_set_static.rdp.id
  ]
  egress_worker_filter  = "\"${each.value.egress_tag_value}\" in \"${each.value.egress_tag_key}\""
  ingress_worker_filter = "\"${each.value.ingress_tag_value}\" in \"${each.value.ingress_tag_key}\""
}

resource "boundary_role" "reader_user" {
  name          = var.reader_user_role
  description   = "A reader_user role"
  principal_ids = [for _, user in boundary_user.user : user.id]
  grant_strings = concat(
    ["type=target;actions=list"],
    [for rdp_instance in values(boundary_target.rdp) : "ids=${rdp_instance.id};actions=read"]
  )
  scope_id = boundary_scope.project.id
}

resource "boundary_role" "admin_user" {
  name          = var.admin_user_role
  description   = "A admin_user_user role"
  principal_ids = [for _, user in boundary_user.admin : user.id]
  grant_strings = concat(
    ["ids=*;type=*;actions=*"]
  )
  scope_id = boundary_scope.project.id
}
