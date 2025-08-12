cat > ~/infra-yc/terraform/variables.tf <<'EOF'
variable "cloud_id"  { type = string }
variable "folder_id" { type = string }

# путь к JSON-ключу сервисного аккаунта (Actions положит key.json рядом)
variable "service_account_key_file" {
  type    = string
  default = "key.json"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "ssh_user"        { type = string, default = "ubuntu" }
variable "ssh_public_key"  { type = string }
EOF
