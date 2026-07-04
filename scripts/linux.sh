#!/usr/bin/env bash
#
# Split-boot для Raspberry Pi 5: boot остаётся на уже настроенной флешке
# (пользователь/SSH-ключ/Wi-Fi там уже прописаны через Raspberry Pi Imager
# заранее), root переезжает на чистый NVMe.
#
# Запускать НА САМОЙ Pi, загруженной с этой флешки.
#
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

confirm() {
    read -r -p "$(echo -e "${YELLOW}$1 [y/N]:${NC} ")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

if [[ $EUID -eq 0 ]]; then
    err "Не запускай напрямую через sudo/root. Запусти от обычного пользователя."
    exit 1
fi

echo "========================================================"
echo " Split-boot Raspberry Pi 5: root -> NVMe, boot остаётся на флешке"
echo "========================================================"
echo
warn "Этот скрипт УНИЧТОЖИТ все данные на NVMe диске."
warn "Boot-раздел флешки (user-data/network-config/ssh-ключ) НЕ трогается."
echo
df -h / || true
echo
if ! confirm "Ты сейчас загружен именно с флешки (не с NVMe)?"; then
    err "Останавливаюсь. Загрузись с флешки и запусти скрипт заново."
    exit 1
fi

# ── 1. Определение устройств ──────────────────────────────────────────
echo
info "Текущие блочные устройства:"
lsblk
echo
read -r -p "Устройство флешки, с которой сейчас загружены (например sda): " USB_DEV
read -r -p "Устройство NVMe (например nvme0n1): " NVME_DEV
USB_DEV="/dev/${USB_DEV#/dev/}"
NVME_DEV="/dev/${NVME_DEV#/dev/}"

if [[ ! -b "$USB_DEV" || ! -b "$NVME_DEV" ]]; then
    err "Одно из устройств не найдено: $USB_DEV или $NVME_DEV"
    exit 1
fi

USB_BOOT="${USB_DEV}1"
USB_ROOT="${USB_DEV}2"
NVME_BOOT="${NVME_DEV}p1"
NVME_ROOT="${NVME_DEV}p2"

info "Флешка (остаётся boot, не трогаем): boot=$USB_BOOT root=$USB_ROOT"
info "NVMe (станет root): boot=$NVME_BOOT (будет неиспользуемым) root=$NVME_ROOT"
echo
if ! confirm "Всё верно? Продолжаем?"; then
    exit 1
fi

# ── 2. Прошивка образа на NVMe (rpi-imager сам перезапишет всё, включая
#      partition table — отдельное затирание не требуется) ────────────────

# ── 3. Скачивание официального образа Ubuntu ────────────────────────────
echo
info "Определяю актуальную версию образа Ubuntu 24.04 (noble) для Raspberry Pi..."

RELEASE_INDEX="https://cdimage.ubuntu.com/releases/noble/release/"
IMG_FILENAME=$(wget -q -O - "$RELEASE_INDEX" \
    | grep -oE 'ubuntu-24\.04\.[0-9]+-preinstalled-server-arm64\+raspi\.img\.xz' \
    | sort -V | tail -n1 || true)

if [[ -z "$IMG_FILENAME" ]]; then
    warn "Не удалось автоматически определить имя файла образа с $RELEASE_INDEX"
    read -r -p "Введи имя файла образа вручную: " IMG_FILENAME
fi

IMG_URL="${RELEASE_INDEX}${IMG_FILENAME}"
IMG_XZ="$HOME/${IMG_FILENAME}"

info "Актуальный образ: $IMG_FILENAME"

if [[ -f "$IMG_XZ" ]]; then
    info "Файл образа уже существует: $IMG_XZ"
    if confirm "Перекачать заново?"; then
        rm -f "$IMG_XZ"
    fi
fi

if [[ ! -f "$IMG_XZ" ]]; then
    info "Скачиваю образ..."
    wget -c "$IMG_URL" -O "$IMG_XZ"
fi

info "Проверяю целостность архива..."
if ! xz -t "$IMG_XZ"; then
    err "Архив повреждён. Удали файл и запусти скрипт заново для перекачки:"
    err "  rm $IMG_XZ"
    exit 1
fi
ok "Образ скачан и цел."

# ── 4. Проверка/установка rpi-imager ─────────────────────────────────────
if ! command -v rpi-imager &> /dev/null; then
    info "rpi-imager не найден, устанавливаю..."
    sudo apt update
    sudo apt install -y rpi-imager
fi

# ── 5. Прошивка образа на NVMe ────────────────────────────────────────────
echo
warn "СЕЙЧАС БУДУТ УНИЧТОЖЕНЫ ВСЕ ДАННЫЕ НА $NVME_DEV"
sudo lsblk "$NVME_DEV"
if ! confirm "Точно прошиваем $NVME_DEV?"; then
    err "Остановлено пользователем."
    exit 1
fi
warn "Прошиваю $IMG_XZ на $NVME_DEV — это займёт несколько минут."
sudo rpi-imager --cli "$IMG_XZ" "$NVME_DEV"
ok "Образ прошит на NVMe."
sudo partprobe "$NVME_DEV" 2>/dev/null || true
sleep 2
lsblk "$NVME_DEV"

# ── 6. Расширение root — НЕ требуется вручную: cloud-init сам расширит
#      root-раздел на весь диск через growpart при первой загрузке NVMe.

# ── 7. Разведение labels, чтобы избежать конфликтов ───────────────────────
# Boot остаётся на флешке (sda1, уже с label system-boot - не трогаем).
# Root должен быть на NVMe -> он должен носить label "writable" (именно
# так ищет его root=LABEL=writable в cmdline.txt на флешке).
# Поэтому переименовываем ТЕКУЩИЙ root флешки во что-то другое,
# а NVMe root оставляем/делаем "writable".
echo
info "Развожу labels между устройствами..."
sudo e2label "$USB_ROOT" oldroot
sudo e2label "$NVME_ROOT" writable
sudo fatlabel "$NVME_BOOT" unused-boot
ok "Labels настроены:"
sudo blkid "$USB_BOOT" "$USB_ROOT" "$NVME_BOOT" "$NVME_ROOT"

# ── 8. Проверка cmdline.txt и fstab (без редактирования - должно уже сойтись) ─
echo
info "cmdline.txt на текущем boot (флешка, не менялся):"
sudo mount /dev/sda1 /boot/firmware
cat /boot/firmware/cmdline.txt
echo
info "Ожидаем строку root=LABEL=writable — теперь она однозначно указывает"
info "на NVMe ($NVME_ROOT), так как только он носит это имя."
echo
sudo mkdir -p /mnt/nvme_root
sudo mount "$NVME_ROOT" /mnt/nvme_root
info "fstab внутри нового root (NVMe):"
cat /mnt/nvme_root/etc/fstab
info "Ожидаем LABEL=system-boot для /boot/firmware — на флешке (sda1) он"
info "уникален (у nvme boot теперь unused-boot), так что должно совпасть."
sudo umount /mnt/nvme_root

# ── 9. Финал ───────────────────────────────────────────────────────────────
echo
echo "========================================================"
ok "Готово!"
echo "========================================================"
echo
info "После перезагрузки:"
info "  - boot останется с флешки ($USB_DEV, label system-boot) — без изменений"
info "  - root будет на NVMe ($NVME_DEV, label writable)"
echo
info "Проверка после загрузки:"
echo "  df -h /"
echo "  df -h /boot/firmware"
echo "  lsblk"
echo
if confirm "Перезагрузиться прямо сейчас?"; then
    sudo reboot
else
    info "Не забудь перезагрузиться вручную: sudo reboot"
fi
