#!/bin/bash
clear

### 基础部分 ###
# 使用 O2 级别的优化
sed -i 's/Os/O2 -Wl,--gc-sections/g' include/target.mk
wget -qO - https://github.com/openwrt/openwrt/commit/8249a8c.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/66fa343.patch | patch -p1
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# 默认开启 Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
# 维多利亚的秘密
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
wget -P scripts/ https://github.com/immortalwrt/immortalwrt/raw/master/scripts/download.pl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/download.mk
sed -i '/unshift/d' scripts/download.pl
sed -i '/mirror02/d' scripts/download.pl
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# Nginx
sed -i "s/client_max_body_size 128M/client_max_body_size 2048M/g" feeds/packages/net/nginx-util/files/uci.conf.template

### 必要的 Patches ###
cp -f ../PATCH/backport/290-remove-kconfig-CONFIG_I8K.patch ./target/linux/generic/hack-5.10/290-remove-kconfig-CONFIG_I8K.patch
# TCP optimizations
cp -rf ../PATCH/backport/TCP/* ./target/linux/generic/backport-5.10/
wget -P target/linux/generic/hack-5.10/ https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.10/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# SSL
rm -rf ./package/libs/mbedtls
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/libs/mbedtls package/libs/mbedtls
rm -rf ./package/libs/openssl
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/libs/openssl package/libs/openssl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/openssl-engine.mk
# wolfssl
#rm -rf ./package/libs/wolfssl
#svn export https://github.com/coolsnowwolf/lede/trunk/package/libs/wolfssl package/libs/wolfssl
# OPENSSL
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/11895.patch
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/14578.patch
wget -P package/libs/openssl/patches/ https://github.com/openssl/openssl/pull/16575.patch
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
### Fullcone-NAT 部分 ###
# Patch Kernel 以解决 FullCone 冲突
pushd target/linux/generic/hack-5.10
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.10/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添 FullCone 功能
# FW4
rm -rf ./package/network/config/firewall4
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/network/config/firewall4 package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
rm -rf ./package/libs/libnftnl
svn export https://github.com/wongsyrone/lede-1/trunk/package/libs/libnftnl package/libs/libnftnl
rm -rf ./package/network/utils/nftables
svn export https://github.com/wongsyrone/lede-1/trunk/package/network/utils/nftables package/network/utils/nftables
# FW3
mkdir -p package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/openwrt-21.02/package/network/config/firewall/patches/100-fullconenat.patch
wget -qO- https://github.com/msylgj/R2S-R4S-OpenWrt/raw/master/PATCHES/001-fix-firewall3-flock.patch | patch -p1
# Patch LuCI 以增添 FullCone 开关
patch -p1 <../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone PKG
git clone --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone package/new/nft-fullcone
#svn export https://github.com/coolsnowwolf/lede/trunk/package/network/services/fullconenat package/lean/openwrt-fullconenat
svn export https://github.com/Lienol/openwrt/trunk/package/network/fullconenat package/lean/openwrt-fullconenat
#pushd package/lean/openwrt-fullconenat
#patch -p2 <../../../../PATCH/firewall/fullcone6.patch
#popd

### 获取额外的基础软件包 ###
# 更换为 ImmortalWrt Uboot 以及 Target
rm -rf ./target/linux/rockchip
svn export https://github.com/coolsnowwolf/lede/trunk/target/linux/rockchip target/linux/rockchip
#svn export -r 5010 https://github.com/coolsnowwolf/lede/trunk/target/linux/rockchip target/linux/rockchip
#rm -rf ./target/linux/rockchip/image/armv8.mk
#wget -P target/linux/rockchip/image/ https://github.com/coolsnowwolf/lede/raw/3211a97/target/linux/rockchip/image/armv8.mk
rm -rf ./target/linux/rockchip/Makefile
wget -P target/linux/rockchip/ https://github.com/openwrt/openwrt/raw/openwrt-22.03/target/linux/rockchip/Makefile
rm -rf ./target/linux/rockchip/patches-5.10
svn export https://github.com/orangepi-xunlong/openwrt/trunk/target/linux/rockchip/patches-5.10 target/linux/rockchip/patches-5.10

rm -rf ./package/firmware/linux-firmware/intel.mk
wget -P package/firmware/linux-firmware/ https://github.com/coolsnowwolf/lede/raw/master/package/firmware/linux-firmware/intel.mk
rm -rf ./package/firmware/linux-firmware/Makefile
wget -P package/firmware/linux-firmware/ https://github.com/coolsnowwolf/lede/raw/master/package/firmware/linux-firmware/Makefile

#mkdir -p target/linux/rockchip/files-5.10
#cp -rf ../PATCH/files-5.10 ./target/linux/rockchip/

rm -rf ./package/boot/uboot-rockchip
svn export https://github.com/coolsnowwolf/lede/trunk/package/boot/uboot-rockchip package/boot/uboot-rockchip
#svn export -r 5010 https://github.com/coolsnowwolf/lede/trunk/package/boot/uboot-rockchip package/boot/uboot-rockchip
sed -i '/r2c-rk3328:arm-trusted/d' package/boot/uboot-rockchip/Makefile

svn export https://github.com/coolsnowwolf/lede/trunk/package/boot/arm-trusted-firmware-rockchip-vendor package/boot/arm-trusted-firmware-rockchip-vendor
#svn export -r 5010 https://github.com/coolsnowwolf/lede/trunk/package/boot/arm-trusted-firmware-rockchip-vendor package/boot/arm-trusted-firmware-rockchip-vendor

rm -rf ./package/kernel/linux/modules/video.mk
wget -P package/kernel/linux/modules/ https://github.com/immortalwrt/immortalwrt/raw/master/package/kernel/linux/modules/video.mk

echo '
# CONFIG_SHORTCUT_FE is not set
# CONFIG_PHY_ROCKCHIP_NANENG_COMBO_PHY is not set
# CONFIG_PHY_ROCKCHIP_SNPS_PCIE3 is not set
' >>./target/linux/rockchip/armv8/config-5.10

# Dnsmasq
#git clone -b mine --depth 1 https://git.openwrt.org/openwrt/staging/ldir.git
rm -rf ./package/network/services/dnsmasq
#cp -rf ./ldir/package/network/services/dnsmasq ./package/network/services/
svn export https://github.com/openwrt/openwrt/trunk/package/network/services/dnsmasq package/network/services/dnsmasq

# LRNG
#cp -rf ../PATCH/LRNG/* ./target/linux/generic/hack-5.10/
# R4S超频到 2.2/1.8 GHz
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/mmc.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r2s.bootscript
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/nanopi-r4s.bootscript
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg
# AutoCore
#svn export -r 219750 https://github.com/immortalwrt/immortalwrt/branches/master/package/emortal/autocore package/lean/autocore
#sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/lean/autocore/files/generic/luci-mod-status-autocore.json
#sed -i '/"$threads"/d' package/lean/autocore/files/x86/autocore
rm -rf ./feeds/packages/utils/coremark
svn export https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
# luci-app-irqbalance
svn export https://github.com/QiuSimons/OpenWrt-Add/trunk/luci-app-irqbalance package/new/luci-app-irqbalance
# 更换 Nodejs 版本
rm -rf ./feeds/packages/lang/node
# R8168驱动
# git clone -b master --depth 1 https://github.com/BROBIRD/openwrt-r8168.git package/new/r8168
# patch -p1 <../PATCH/r8168/r8168-fix_LAN_led-for_r4s-from_TL.patch
# R8152驱动
svn export https://github.com/immortalwrt/immortalwrt/branches/master/package/kernel/r8152 package/new/r8152
# r8125驱动
svn export https://github.com/coolsnowwolf/lede/trunk/package/lean/r8125 package/new/r8125
# igb-intel驱动
svn export https://github.com/coolsnowwolf/lede/trunk/package/lean/igb-intel package/new/igb-intel
# igc-backport
# cp -rf ../PATCH/igc-files-5.10 ./target/linux/x86/files-5.10
# UPX 可执行软件压缩
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn export https://github.com/Lienol/openwrt/trunk/tools/ucl tools/ucl
svn export https://github.com/Lienol/openwrt/trunk/tools/upx tools/upx

### 获取额外的 LuCI 应用、主题和依赖 ###
# 广告过滤 AdGuard
#svn export https://github.com/Lienol/openwrt/trunk/package/diy/luci-app-adguardhome package/new/luci-app-adguardhome
#git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/new/luci-app-adguardhome
#rm -rf ./feeds/packages/net/adguardhome
#svn export https://github.com/openwrt/packages/trunk/net/adguardhome feeds/packages/net/adguardhome
#sed -i '/\t)/a\\t$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/AdGuardHome' ./feeds/packages/net/adguardhome/Makefile
#sed -i '/init/d' feeds/packages/net/adguardhome/Makefile
# CPU 控制相关
svn export -r 19495 https://github.com/immortalwrt/luci/trunk/applications/luci-app-cpufreq feeds/luci/applications/luci-app-cpufreq
ln -sf ../../../feeds/luci/applications/luci-app-cpufreq ./package/feeds/luci/luci-app-cpufreq
sed -i 's,1608,1800,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/10-cpufreq
sed -i 's,2016,2208,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/10-cpufreq
sed -i 's,1512,1608,g' feeds/luci/applications/luci-app-cpufreq/root/etc/uci-defaults/10-cpufreq
# OpenClash
#wget -qO - https://github.com/openwrt/openwrt/commit/efc8aff.patch | patch -p1
#git clone --single-branch --depth 1 -b dev https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
svn export https://github.com/vernesong/OpenClash/branches/dev/luci-app-openclash package/new/luci-app-openclash
# 最大连接数
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 生成默认配置及缓存
rm -rf .config

echo '
CONFIG_RESERVE_ACTIVEFILE_TO_PREVENT_DISK_THRASHING=y
CONFIG_RESERVE_ACTIVEFILE_KBYTES=65536
CONFIG_RESERVE_INACTIVEFILE_TO_PREVENT_DISK_THRASHING=y
CONFIG_RESERVE_INACTIVEFILE_KBYTES=65536

#CONFIG_RANDOM_DEFAULT_IMPL=y
#CONFIG_LRNG=y
#CONFIG_LRNG_SHA256=y
#CONFIG_LRNG_RCT_CUTOFF=31
#CONFIG_LRNG_APT_CUTOFF=325
#CONFIG_LRNG_CPU=y
#CONFIG_LRNG_CPU_FULL_ENT_MULTIPLIER=1
#CONFIG_LRNG_CPU_ENTROPY_RATE=8
#CONFIG_LRNG_DRNG_CHACHA20=y
#CONFIG_LRNG_DFLT_DRNG_CHACHA20=y

CONFIG_NFSD=y

' >>./target/linux/generic/config-5.10
#exit 0
