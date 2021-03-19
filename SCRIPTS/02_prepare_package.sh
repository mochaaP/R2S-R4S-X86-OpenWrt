#!/bin/bash

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/Os/O3/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# 默认开启 Irqbalance
sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
# GitHub Mirrors
rm -rf ./scripts/download.pl
rm -rf ./include/download.mk
wget -P scripts/ https://github.com/immortalwrt/immortalwrt/raw/master/scripts/download.pl
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/download.mk
wget -P include/ https://github.com/immortalwrt/immortalwrt/raw/master/include/package-immortalwrt.mk

### 必要的 Patches ###
# Patch arm64 型号名称
wget -P target/linux/generic/pending-5.4 https://github.com/immortalwrt/immortalwrt/raw/master/target/linux/generic/hack-5.4/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# Patch jsonc
patch -p1 < ../PATCH/new/package/use_json_object_new_int64.patch
# Patch dnsmasq
patch -p1 < ../PATCH/new/package/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/new/package/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/new/package/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch

### Fullcone-NAT 部分 ###
# Patch Kernel 以解决 FullCone 冲突
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
# Patch FireWall 以增添 FullCone 功能 
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/immortalwrt/immortalwrt/raw/master/package/network/config/firewall/patches/fullconenat.patch
# Patch LuCI 以增添 FullCone 开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_fullcone.patch
# FullCone 相关组件
cp -rf ../openwrt-lienol/package/network/fullconenat ./package/network/fullconenat

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
pushd target/linux/generic/hack-5.4
wget https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
popd
# Patch LuCI 以增添 Shortcut-FE 开关
patch -p1 < ../PATCH/new/package/luci-app-firewall_add_sfe_switch.patch
# Shortcut-FE 相关组件
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/lean/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/lean/fast-classifier
cp -f ../PATCH/duplicate/shortcut-fe ./package/base-files/files/etc/init.d

### 获取额外的基础软件包 ###
# AutoCore
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/autocore package/lean/autocore
#wget -qO - https://github.com/immortalwrt/immortalwrt/commit/13d6e338f1f7eba45e1aada749ac74fc391b9216.patch | patch -Rp1
rm -rf ./feeds/packages/utils/coremark
svn co https://github.com/immortalwrt/packages/trunk/utils/coremark feeds/packages/utils/coremark
# 更换 Nodejs 版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
rm -rf ./feeds/packages/lang/node-arduino-firmata
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
rm -rf ./feeds/packages/lang/node-cylon
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
rm -rf ./feeds/packages/lang/node-hid
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
rm -rf ./feeds/packages/lang/node-homebridge
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
rm -rf ./feeds/packages/lang/node-serialport
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
rm -rf ./feeds/packages/lang/node-serialport-bindings
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
rm -rf ./feeds/packages/lang/node-yarn
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-yarn feeds/packages/lang/node-yarn
ln -sf ../../../feeds/packages/lang/node-yarn ./package/feeds/packages/node-yarn
# R8168驱动
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/kernel/r8168 package/new/r8168
#patch -p1 < ../PATCH/new/main/r8168-fix_LAN_led-for_r4s-from_TL.patch
# UPX 可执行软件压缩
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/upx tools/upx
svn co https://github.com/immortalwrt/immortalwrt/branches/master/tools/ucl tools/ucl

### 获取额外的 LuCI 应用、主题和依赖 ###
# Argon 主题
git clone -b master --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/new/luci-theme-argon
wget -P ./package/new/luci-theme-argon/luasrc/view/themes/argon -N https://github.com/jerrykuku/luci-theme-argon/raw/9fdcfc866ca80d8d094d554c6aedc18682661973/luasrc/view/themes/argon/footer.htm
wget -P ./package/new/luci-theme-argon/luasrc/view/themes/argon -N https://github.com/jerrykuku/luci-theme-argon/raw/9fdcfc866ca80d8d094d554c6aedc18682661973/luasrc/view/themes/argon/header.htm
git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/new/luci-app-argon-config
# 定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
# Boost 通用即插即用
svn co https://github.com/ryohuang/slim-wrt/trunk/slimapps/application/luci-app-boostupnp package/new/luci-app-boostupnp
sed -i 's,api.ipify.org,myip.ipip.net/s,g' ./package/new/luci-app-boostupnp/root/usr/sbin/boostupnp.sh
rm -rf ./feeds/packages/net/miniupnpd
svn co https://github.com/openwrt/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
# ChinaDNS
git clone -b luci --depth 1 https://github.com/pexcn/openwrt-chinadns-ng.git package/new/luci-app-chinadns-ng
svn co https://github.com/xiaorouji/openwrt-passwall/trunk/chinadns-ng package/new/chinadns-ng
# 内存压缩
#wget -O- https://patch-diff.githubusercontent.com/raw/openwrt/openwrt/pull/2840.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/40f1d5.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/a83a0b.patch | patch -p1
wget -O- https://github.com/NoTengoBattery/openwrt/commit/6d5fb4.patch | patch -p1
mkdir ./package/new
cp -rf ../NoTengoBattery/feeds/luci/applications/luci-app-compressed-memory ./package/new/luci-app-compressed-memory
sed -i 's,include ../..,include $(TOPDIR)/feeds/luci,g' ./package/new/luci-app-compressed-memory/Makefile
cp -rf ../NoTengoBattery/package/system/compressed-memory ./package/system/compressed-memory
# CPU 控制相关
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
cp -rf ../PATCH/duplicate/luci-app-cpulimit ./package/lean/luci-app-cpulimit
svn co https://github.com/immortalwrt/packages/trunk/utils/cpulimit package/lean/cpulimit
# 回滚通用即插即用
#rm -rf ./feeds/packages/net/miniupnpd
#svn co https://github.com/coolsnowwolf/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
# OpenClash
git clone -b master --depth 1 https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
# qBittorrent 下载
svn co https://github.com/garypang13/openwrt-static-qb/trunk/qBittorrent-Enhanced-Edition package/lean/qBittorrent-Enhanced-Edition
sed -i 's/4.3.3.10/4.3.4.10/g' package/lean/qBittorrent-Enhanced-Edition/Makefile
svn co https://github.com/immortalwrt/immortalwrt/branches/master/package/lean/luci-app-qbittorrent package/lean/luci-app-qbittorrent
# 清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
# ServerChan 微信推送
git clone -b master --depth 1 https://github.com/tty228/luci-app-serverchan.git package/new/luci-app-serverchan
# SmartDNS
rm -rf ./feeds/packages/net/smartdns
mkdir package/new/smartdns
wget -P package/new/smartdns/ https://github.com/HiGarfield/lede-17.01.4-Mod/raw/master/package/extra/smartdns/Makefile
sed -i 's,files/etc/config,$(PKG_BUILD_DIR)/package/openwrt/files/etc/config,g' ./package/new/smartdns/Makefile
# 网易云音乐解锁
git clone --depth 1 https://github.com/immortalwrt/luci-app-unblockneteasemusic.git package/new/UnblockNeteaseMusic
# KMS 激活助手
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-vlmcsd package/lean/luci-app-vlmcsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vlmcsd package/lean/vlmcsd

### 最后的收尾工作 ###
# 最大连接数
sed -i 's/16384/65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 生成默认配置及缓存
rm -rf .config

exit 0
