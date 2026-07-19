# Образ для cronjob-ов бэкапа: клиенты БД и инструменты доступа, которые раньше
# каждый job ставил себе сам через `apk add` при каждом запуске.
#
# Дело не столько в скорости, сколько в надёжности: установка на старте делала
# бэкап зависимым от доступности зеркала Alpine — недоступно зеркало, и job
# падал на `set -euo pipefail`, не сняв дамп.
#
# База — голый alpine, а не postgres:18-alpine: из образа СУБД использовался
# ровно один pg_dump, а сервер, initdb и их зависимости ехали мёртвым грузом.
FROM alpine:3.23

# postgresql18-client — pg_dump/psql. Мажор должен совпадать с сервером или быть
#                       новее: pg_dump отказывается снимать дамп с БД, версия
#                       которой выше его собственной. У вас postgres 18.
# kubectl             — port-forward до postgres в удалённых кластерах (coin, vpn)
# openssh-client      — бэкапы, которые ходят за дампом по ssh (codex, monitoring,
#                       clickhouse)
# curl                — запросы к ClickHouse по HTTP. Родной клиент не ставим:
#                       у ClickHouse клиент и сервер это один монолитный бинарь
#                       на ~490 МБ, а HTTP-интерфейс отдаёт тот же FORMAT Native.
#
# coreutils намеренно нет: скриптам бэкапа хватает busybox-версий date/gzip/tar.
RUN apk add --no-cache postgresql18-client kubectl openssh-client curl