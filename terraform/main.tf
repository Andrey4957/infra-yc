cat > ~/infra-yc/terraform/main.tf <<'EOF'
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.126"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id

  # В Actions будем использовать ключ сервисного аккаунта (YC_SA_KEY_JSON),
  # здесь путь к нему придёт как переменная.
  service_account_key_file = var.service_account_key_file
}

# Сеть и подсеть
resource "yandex_vpc_network" "net" {
  name = "net-auto"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet-auto"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# Образ Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# Виртуальная машина
resource "yandex_compute_instance" "vm" {
  name        = "tf-vm-a"
  platform_id = "standard-v1"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true               # даём публичный IP
  }

  metadata = {
    # Передаём публичный ключ: "пользователь:ключ"
    "ssh-keys" = "${var.ssh_user}:${var.ssh_public_key}"
  }
}
EOF
