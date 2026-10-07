# ESPHome

Конфиги устройств хранятся в git. Секреты — тоже в git, но зашифрованные
через SOPS (тот же механизм, что уже используется для `k8s/secrets`, но
со своим отдельным age-ключом `key.txt` — секреты esphome и k8s не делят
один ключ).

## Структура

- `config/*.yaml` — конфиги устройств, обычный открытый YAML (не секрет сам
  по себе, только ссылается на секреты через `!secret`)
- `secrets/.sops.yaml` — правило SOPS с публичным age-ключом esphome
- `secrets/secrets.enc.yaml` — зашифрованный SOPS, единственный источник
  правды, живёт в git
- `key.txt` — приватный age-ключ, **в git не попадает** (`.gitignore`)
- `config/secrets.yaml` — расшифрованная рабочая копия, которую реально
  читает ESPHome-контейнер; **в git не попадает** (`.gitignore`),
  генерируется командой ниже

## Правка секретов

```sh
make edit-secrets
```
Открывает `secrets.enc.yaml` расшифрованным в редакторе, при сохранении сам
шифрует обратно — на диске в открытом виде не остаётся ни на секунду дольше,
чем открыт редактор.

## Перед компиляцией/прошивкой

```sh
make decrypt-secrets
```
Кладёт актуальную расшифрованную копию в `config/secrets.yaml` — именно туда
смотрит примонтированная в ESPHome-контейнер директория `config/`.

## Запуск дашборда (на pi)

```bash
docker run -d --name esphome \
  -v /opt/esphome/config:/config \
  -p 6052:6052 \
  --device=/dev/ttyUSB0 \
  --network host \
  ghcr.io/esphome/esphome
```
`/opt/esphome/config` на pi — это и есть склонированный из git `esphome/config/`
(после `make decrypt-secrets`, чтобы `secrets.yaml` там реально лежал).
