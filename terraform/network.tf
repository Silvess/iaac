resource "yandex_vpc_network" "wp-network" {
  name = "wp-network"
}

resource "yandex_vpc_subnet" "wp-subnet" {
  count = length(var.zones)
  v4_cidr_blocks = [cidrsubnet("10.0.0.0/8",8,count.index + 1)]
  zone           = var.zones[count.index]
  network_id     = yandex_vpc_network.wp-network.id
}