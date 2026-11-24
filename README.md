# UGREEN CM960 (AIC8800M80X2P) Linux Wi-Fi 驱动安装器

针对绿联 **UGREEN CM960**（芯片 **AIC8800M80X2P / AIC8800D80X2**，PCIe 接口，`VID:PID = a69c:8d90`）的 Linux 内核驱动编译与安装脚本。

> 官方 SDK 主要面向 Android / 板级开发板，普通 Linux 发行版（Debian / Ubuntu / 树莓派 / ARM 设备等）默认无法直接使用这块网卡。本仓库把官方 SDK 中的 PCIe fullmac 驱动与固件整理出来，并提供一键安装脚本 `install.sh`。

## 硬件信息

| 项目 | 值 |
| --- | --- |
| 设备 | UGREEN CM960 |
| 芯片 | AIC8800M80X2P（AIC8800D80X2） |
| 接口 | PCIe（USB-C 形态） |
| VID:PID | `a69c:8d90` |
| Wi-Fi | 802.11ax（Wi-Fi 6），2.4G + 5G，2x2 |
| 内核模块 | `aic8800D80_fdrv` |

## 目录结构

```
.
├── install.sh                          # 一键编译安装脚本
└── src/PCIE/driver_fw/
    ├── driver/
    │   ├── aic8800d80x2/aic8800_fdrv/  # CM960 (8800D80X2) PCIe fullmac 驱动源码
    │   ├── aic8800/aic8800_fdrv/       # 8800D80 驱动源码
    │   └── deb/                        # deb 打包参考
    ├── fw/
    │   ├── aic8800D80X2/               # CM960 所需固件
    │   └── aic8800D80/                 # 8800D80 固件
    └── flash/                          # flash 烧写工具与说明
```

## 使用方式

```bash
sudo bash install.sh
```

脚本会自动完成：

1. 检查 `root` 权限与 `make` / `gcc` 工具链；
2. 检查当前内核的 `linux-headers`；
3. 编译内核模块 `aic8800D80_fdrv`；
4. 安装模块到 `/lib/modules/$(uname -r)/kernel/drivers/net/wireless/aic8800D80/`；
5. 安装固件到 `/lib/firmware/aic8800D80X2/`；
6. 执行 `depmod`、写入 `/etc/modules-load.d/aic8800.conf` 并 `modprobe` 加载。

## 前置条件

- `root` 权限；
- 编译工具：`sudo apt install -y build-essential`；
- 与当前内核匹配的头文件：`sudo apt install -y linux-headers-$(uname -r)`。

## 安装后验证

```bash
ip link            # 应出现 wlan0 之类的接口
dmesg | grep -i aic
nmcli dev status   # 网络管理器（若使用 NetworkManager）
```

## 故障排查

- **缺少内核头文件**：先执行 `sudo apt install -y linux-headers-$(uname -r) build-essential`。
- **`modprobe` 失败**：查看 `dmesg | tail -40`，确认固件是否位于 `/lib/firmware/aic8800D80X2/`。
- **内核升级后失效**：内核版本变化后需重新运行 `sudo bash install.sh`（或使用 DKMS 管理）。

## 源码来源与许可

- 驱动源码来自 [radxa-pkg/aic8800](https://github.com/radxa-pkg/aic8800)（AIC8800 官方 SDK，PCIe fullmac 驱动）。
- 内核模块声明为 GPL 许可（`MODULE_LICENSE("GPL")`）。
- 固件（`fw/` 下的 `.bin`）版权归爱科微半导体（Aicsemi）所有。

## 免责声明

本项目仅用于整理与简化安装流程，驱动与固件均来自上游 SDK。请在遵守上游许可与当地法规的前提下使用。
