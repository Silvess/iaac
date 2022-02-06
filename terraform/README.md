# Описание выполнения домашнего задания к занятию “Тестирование инфраструктурного кода на Terraform”

## Цель работы
Создать тесты, проверяющие корректно ли созданы ресурсы при помощи терраформ-манифестов.

Ожидается проверка:

* наличия IP Load balancer-а в state-е терраформа
* возможности подключения по ssh к одной из виртуальных машин
* возможности подключения к базе данных (это задание “со звездочкой”)

## Создание тестов

Первые две проверки выполнены в соответствии с инструкциями по выполнению домашнего задания ([ссылка](https://hackmd.io/@otus/B1TK3dUMK "Инструкция по выполнению домашнего задания")).

### Проверка возможности подключения к созданной базе данных

Дополним output.tf указанием переменных `database_user`, `database_pass` и `database_name`. 
Финальный вид output.tf:
```hcl
output "load_balancer_public_ip" {
  description = "Public IP address of load balancer"
  value = tolist(tolist(yandex_lb_network_load_balancer.wp_lb.listener).0.external_address_spec).0.address
}

output "vm_linux_public_ip_address" {
  description = "Virtual machine IP"
  value = yandex_compute_instance.wp-app[0].network_interface[0].nat_ip_address
}

output "database_host_fqdn" {
  description = "DB hostname"
  value = local.dbhosts
}

output "database_user" {
  description = "User of the created DB"
  value = local.dbuser
}

output "database_name" {
  description = "Name of the created DB"
  value = local.dbname
}

output "database_pass" {
  description = "Password of the created DB"
  sensitive = true
  value = local.dbpassword
}
```
В **end2end_test.go** в блок `import` допишем необходимые для взаимодействия с БД пакеты: 

``` Go
import (
	...

	"database/sql"
	_ "github.com/go-sql-driver/mysql"
)
```
В тело функции `test_structure.RunTestStage()` добавим следующие строки: 

``` Go
	test_structure.RunTestStage(t, "validate", func() {
		...

		// test db connection
		dbHostname := terraform.Output(t, terraformOptions, "database_host_fqdn")
		dbName := terraform.Output(t, terraformOptions, "database_name")
		dbUser := terraform.Output(t, terraformOptions, "database_user")
		dbPass := terraform.Output(t, terraformOptions, "database_pass")

		//db, err := sql.Open("mysql", "username:password@tcp(127.0.0.1:3306)/test")
		db, err := sql.Open("mysql", dbUser+":"+dbPass+"@tcp("+dbHostname+":3306)/"+dbName)
		if err != nil {
			t.Fatalf("Cannot connect to database: %v", err)
		}

		defer db.Close()
	})
```
`dbHostname`, `dbName`, `dbUser`, `dbPass` - переменные, значения которых получаем из output переменных Terraform. 

`db, err := sql.Open()' - вызов функции установки соединения с БД.

По завершению, не забываем закрыть соединение к БД: `defer db.Close()`.

