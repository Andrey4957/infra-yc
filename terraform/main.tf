cat > terraform/main.tf <<'HCL'
data "yandex_vpc_network" "default" {
  name = "default"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet-auto"
  zone           = var.zone
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

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
  }

  metadata = {
    "ssh-keys" = "${var.ssh_user}:${var.ssh_public_key}"
  }
}
HCL
