#!/bin/bash

# 建议先安装依赖：
# apk add --no-cache bash curl wget unzip grep coreutils

set -e

XRAY_DIR="/usr/local/etc/xray"
XRAY_BIN="$XRAY_DIR/xray"
XRAY_CONF_FILE="$XRAY_DIR/config.json"
XRAY_GEOSITE="$XRAY_DIR/geosite.dat"
XRAY_GEOIP="$XRAY_DIR/geoip.dat"
RENEW_DIR="$HOME/renewX"
XRAY_INIT="/etc/init.d/xray"

# ===== 函数：下载最新 geosite / geoip =====
update_geo() {
    echo "Updating geosite / geoip files..."
    mkdir -p "$RENEW_DIR"
    cd "$RENEW_DIR"

    local geosite_url geoip_url
    geosite_url=$(curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest \
        | grep browser_download_url | grep geosite | cut -d'"' -f4 | head -n 1)
    geoip_url=$(curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest \
        | grep browser_download_url | grep geoip | cut -d'"' -f4 | head -n 1)

    if [ -z "$geosite_url" ] || [ -z "$geoip_url" ]; then
        echo "ERROR: Failed to fetch geosite/geoip URLs."
        return 1
    fi

    mkdir -p "$XRAY_DIR"

    wget -q "$geosite_url" -O "$XRAY_GEOSITE"
    wget -q "$geoip_url"   -O "$XRAY_GEOIP"

    echo "geosite / geoip updated in $XRAY_DIR."
}

# ===== 函数：从 GitHub 安装或升级 Xray Core =====
install_or_upgrade_xray_core() {
    mkdir -p "$RENEW_DIR"
    cd "$RENEW_DIR"

    echo "Fetching latest Xray release info..."
    wget -q https://api.github.com/repos/XTLS/Xray-core/releases/latest -O latest

    local tag xver arch_choice xray_url
    tag=$(grep "tag_name" latest | cut -d'"' -f4)

    if [ -x "$XRAY_BIN" ]; then
        xver=$("$XRAY_BIN" --version | awk 'FNR == 1 {print $2}')
        echo "Current Xray version: $xver"
    else
        xver=""
        echo "Xray not installed yet (no $XRAY_BIN)."
    fi

    echo "Latest Xray tag: $tag"
    echo

    # 已安装且是最新就不更新 core
    if [ -n "$xver" ] && [[ "$tag" == *"$xver"* ]]; then
        echo "You already have the latest Xray [$xver]."
        return 0
    fi

    echo "1) linux-64"
    echo "2) linux-arm64"
    echo -n "Choose architecture [1-2]: "
    read arch_choice

    if [ "$arch_choice" = "1" ]; then
        xray_url=$(grep browser_download_url latest | grep linux-64 | cut -d'"' -f4 | head -n 1)
    elif [ "$arch_choice" = "2" ]; then
        xray_url=$(grep browser_download_url latest | grep linux-arm64 | cut -d'"' -f4 | head -n 1)
    else
        echo "Invalid choice, exit."
        exit 1
    fi

    if [ -z "$xray_url" ]; then
        echo "ERROR: Failed to get Xray download URL."
        exit 1
    fi

    echo "Downloading Xray from: $xray_url"
    wget -q "$xray_url" -O xray_latest.zip

    echo "Unzipping..."
    unzip -o xray_latest.zip >/dev/null

    if [ ! -f xray ]; then
        echo "ERROR: xray binary not found after unzip."
        exit 1
    fi

    mkdir -p "$XRAY_DIR"
    chmod +x xray
    mv xray "$XRAY_BIN"

    echo "Xray core installed to $XRAY_BIN"
}

# ===== 函数：如果没服务，则生成 /etc/init.d/xray 和默认 config.json =====
ensure_xray_service() {
    # 1) /etc/init.d/xray
    if [ ! -x "$XRAY_INIT" ]; then
        echo "Creating OpenRC service at $XRAY_INIT ..."
        cat > "$XRAY_INIT" <<EOF
#!/sbin/openrc-run

name="xray"
description="Xray core service"

command="$XRAY_BIN"
command_args="-config $XRAY_CONF_FILE"
command_user="root"

pidfile="/run/xray.pid"
command_background="yes"

depend() {
    need net
}
EOF
        chmod +x "$XRAY_INIT"
    else
        echo "OpenRC service $XRAY_INIT already exists, skip creating."
    fi

    # 2) 默认 config.json
    if [ ! -d "$XRAY_DIR" ]; then
        mkdir -p "$XRAY_DIR"
    fi

    if [ ! -f "$XRAY_CONF_FILE" ]; then
        echo "Creating default Xray config at $XRAY_CONF_FILE ..."
        cat > "$XRAY_CONF_FILE" <<'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [],
  "outbounds": []
}
EOF
    else
        echo "Config file $XRAY_CONF_FILE already exists, skip creating default."
    fi

    # 3) 开机启动
    if command -v rc-update >/dev/null 2>&1; then
        rc-update add xray default >/dev/null 2>&1 || true
    fi
}

# ========================= 主逻辑 =========================

# 1) 安装/升级 Core（基于 $XRAY_BIN 是否存在）
if [ ! -x "$XRAY_BIN" ]; then
    echo "Xray is not installed under $XRAY_DIR. Install now? [y/n]"
    read ans
    case "$ans" in
        [Yy]*)
            echo "Installing Xray core from GitHub..."
            install_or_upgrade_xray_core
            ;;
        *)
            echo "Exit."
            exit 0
            ;;
    esac
else
    echo "Xray binary exists at $XRAY_BIN."
    echo "Do you want to check and upgrade Xray core if needed? [y/n]"
    read ans
    case "$ans" in
        [Yy]*)
            install_or_upgrade_xray_core
            ;;
        *)
            echo "Skip upgrading Xray core."
            ;;
    esac
fi

# 2) 确保 OpenRC service + config.json 存在
ensure_xray_service

# 3) geosite / geoip
echo
echo "Do you want to update geosite / geoip data files? [y/n]"
read ans_geo
case "$ans_geo" in
    [Yy]*)
        update_geo
        ;;
    *)
        echo "Skip updating geosite / geoip."
        ;;
esac

# 4) 用 service 重启 xray
echo
echo "Restarting Xray via: service xray restart"
if command -v service >/dev/null 2>&1; then
    service xray restart || echo "WARNING: service xray restart failed."
    sleep 1
    service xray status || true
else
    echo "WARNING: 'service' command not found. Please restart Xray manually:"
    echo "  service xray restart"
fi

echo "Done."