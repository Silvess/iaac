# Описание выполнения домашнего задания к занятию “Переиспользование кода Ansible и работа с ролями”

## Цель работы
Разработать ansible-роль для установки WordPress с использованием инфраструктуры, поднятой при помощи манифестов терраформа.

## Подготовительный этап
На одном уровне с каталогом terraform создадим каталог *ansible* с необходиммой структурой подкаталогов.
В нем создадим файл *ansible.cfg* с описанием настроек Ansible.

### Корректировка манифестов терраформ

Для проверки состояния узлов в `attached_target_group` в файле *lb.tf* блок healthcheck заменен на следующий:

```hcl
    healthcheck {
      name = "tcp"
      tcp_options {
        port = 80
      }
    }
```
### Автоматизация формирования inventory и списка переменных группы хостов wp-app
В качестве решения задания (*) был выбран следующий путь.
Для автоматизации формирования файла инвентори и списка переменных группы хостов **wp-app** используем возможности локального провайдера terraform.
Создадим шаблоны для автоматического создания инвентори и списка переменных группы: файл-шаблон *inventory.tmpl*
```hcl
[wp-app]
%{ for index, group in ansible_group_wp-app ~}
${ hostname_wp-app[index]} ansible_host=${ hostaddr_wp-app[index]}
%{ endfor ~}
```
и файл-шаблон *wp-app.tmpl*
```hcl
wordpress_db_name: ${ wordpress_db_name}
wordpress_db_user: ${ wordpress_db_user}
wordpress_db_password: ${ wordpress_db_password}
wordpress_db_host: ${ wordpress_db_host}
```

В блок локальных переменных в *db.tf* добавим две переменные (они понадобятся для формирования списка переменных ansible):

```hcl
locals {
  ...
  cluster_id = yandex_mdb_mysql_cluster.wp_mysql.id
  cluster_master_fqdn = "c-${local.cluster_id}.rw.mdb.yandexcloud.net"
}
```
Создадим файл *ansible-inv-vars.tf* с описанием создания ресурсов (файлов):
```hcl
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
     ansible_group_wp-app = yandex_compute_instance.wp-app[*].labels.ansible-group
     hostaddr_wp-app = yandex_compute_instance.wp-app[*].network_interface[0].nat_ip_address
     hostname_wp-app = yandex_compute_instance.wp-app[*].name
    }
  )
  filename = "../ansible/environments/prod/inventory"
}

resource "local_file" "ansible_groupvars_wp-app" {
  content = templatefile("wp-app.tmpl",
    {
     wordpress_db_name = local.dbname
     wordpress_db_user = local.dbuser
     wordpress_db_password = local.dbpassword
     wordpress_db_host = local.cluster_master_fqdn
    }
  )
  filename = "../ansible/environments/prod/group_vars/wp-app"
}
```
Таким образом, получим автоматическое создание и наполнение *inventory* и *group_vars/wp-app* средствами terraform.

