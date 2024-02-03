locals {
  entries = { for acl in var.acls : acl.name => acl.entries }
}
