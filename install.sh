#!/usr/bin/env bash
#
# UGREEN CM960 (AIC8800M80X2P / a69c:8d90) PCIe Wi-Fi driver installer
# Driver source: radxa-pkg/aic8800 (official AIC8800 SDK, PCIe fullmac driver)
# Firmware dir used by driver: /lib/firmware/aic8800D80X2
#
set -euo pipefail

DRV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/PCIE/driver_fw/driver/aic8800d80x2/aic8800_fdrv"
FW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src/PCIE/driver_fw/fw/aic8800D80X2"
KDIR="/lib/modules/$(uname -r)/build"
MODULE_NAME="aic8800D80_fdrv"
KVER="$(uname -r)"
MODDEST="/lib/modules/${KVER}/kernel/drivers/net/wireless/aic8800D80"
FW_DEST="/lib/firmware/aic8800D80X2"

if [[ $EUID -ne 0 ]]; then
  echo "请用 root 运行: sudo bash $0" >&2
  exit 1
fi

for tool in make gcc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "缺少编译工具 ${tool}，请先安装: sudo apt install -y build-essential" >&2
    exit 1
  fi
done

echo "==> 检查内核头文件: ${KDIR}"
if [[ ! -f "${KDIR}/Makefile" ]]; then
  echo "缺少内核头文件。请先安装与当前内核匹配的 headers:" >&2
  echo "  sudo apt install -y linux-headers-\$(uname -r) build-essential" >&2
  exit 1
fi

echo "==> 编译模块 (kernel ${KVER})"
cd "${DRV_DIR}"
make clean >/dev/null 2>&1 || true
make -j"$(nproc)" KDIR="${KDIR}"

echo "==> 安装模块到 ${MODDEST}"
mkdir -p "${MODDEST}"
install -p -m 644 "${MODULE_NAME}.ko" "${MODDEST}/"

echo "==> 安装固件到 ${FW_DEST}"
mkdir -p "${FW_DEST}"
install -p -m 644 "${FW_DIR}"/* "${FW_DEST}/"

echo "==> 更新模块依赖并加载"
depmod -a "${KVER}"
echo "${MODULE_NAME}" > /etc/modules-load.d/aic8800.conf

modprobe cfg80211 || true
if modprobe "${MODULE_NAME}"; then
  echo "==> 已加载 ${MODULE_NAME}"
else
  echo "!! modprobe 失败，请查看 dmesg:" >&2
  dmesg | tail -40 >&2
  exit 1
fi

echo
echo "完成。可用以下命令查看状态:"
echo "  ip link            # 应出现 wlan0 之类接口"
echo "  dmesg | grep -i aic"
echo "  nmcli dev status   # 网络管理器"
