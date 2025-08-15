# Используем существующую сеть "default"
data "yandex_vpc_network" "default" {
  name = "default"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet-auto"
  zone           = var.zone
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# Разрешим SSH и HTTP (чтобы Ansible и nginx не упирались в фаервол)
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = data.yandex_vpc_network.default.id

  ingress { protocol = "TCP" port = 22 v4_cidr_blocks = ["0.0.0.0/0"] }
  ingress { protocol = "TCP" port = 80 v4_cidr_blocks = ["0.0.0.0/0"] }
  egress  { protocol = "ANY" from_port = 0 to_port = 65535 v4_cidr_blocks = ["0.0.0.0/0"] }
}

# Образ Ubuntu LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_instance" "vm" {
  name        = "tf-vm-a"
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
