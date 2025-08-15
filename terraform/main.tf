# terraform/main.tf

# Сеть "default"
data "yandex_vpc_network" "default" {
  name = "default"
}

# Новая подсеть с НЕпересекающимся CIDR
resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet-auto-02"              # новое имя
  zone           = var.zone
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.20.0.0/24"]              # новый CIDR (не 10.10.0.0/24)
}

# Security Group с новым именем
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg-02"                       # новое имя
  network_id = data.yandex_vpc_network.default.id

  ingress {
    protocol       = "TCP"
    from_port      = 22
    to_port        = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    from_port      = 80
    to_port        = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Образ Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# ВМ с новым именем
resource "yandex_compute_instance" "vm" {
  name        = "tf-vm-a-04"                     # новое имя
  platform_id = "standard-v1"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
    auto_delete = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    "ssh-keys" = "${var.ssh_user}:${var.ssh_public_key}"
  }
}
