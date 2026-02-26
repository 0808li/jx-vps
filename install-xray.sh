#!/usr/bin/env bash
# =============================================
# 用途：安装 xray 到 /etc/argox 并创建 systemd 服务
# 注意：请确认你真的要使用 root 运行 xray
# =============================================

set -euo pipefail

# ==================== 主要变量 ====================
INSTALL_DIR="/etc/argox"
XRAY_BIN="${INSTALL_DIR}/xray"
CONFIG_FILE="${INSTALL_DIR}/xr.json"
SERVICE_FILE="/etc/systemd/system/xray.service"

# ==================== 开始执行 ====================

echo "正在创建安装目录..."
mkdir -p "${INSTALL_DIR}"

echo "进入安装目录..."
cd "${INSTALL_DIR}" || { echo "无法进入 ${INSTALL_DIR}"; exit 1; }

echo "正在下载 xray..."
# 如果你确定这个链接长期有效，可以直接用
wget -O xray "https://github.com/0808li/jx-vps/releases/download/vps/xray" || {
    echo "下载失败，请检查网络或链接是否仍然有效"
    exit 1
}

echo "赋予 xray 执行权限..."
chmod +x "${XRAY_BIN}"

# ==================== 配置文件（这里仅创建空文件，你需要后续手动编辑） ====================
echo "创建空的 xr.json 文件（请稍后手动编辑）..."
touch "${CONFIG_FILE}"
chmod 600 "${CONFIG_FILE}"

cat <<'EOF'
请注意：
  配置文件 /etc/argox/xr.json 目前是空的！
  你需要手动编辑它，填入有效的 Xray 配置（vmess/vless/trojan/...）

  示例命令：
  nano /etc/argox/xr.json
  或
  vi  /etc/argox/xr.json

按 Enter 键继续创建 systemd 服务...
EOF

read -r

# ==================== 创建 systemd 服务文件 ====================
echo "创建 systemd 服务文件..."

cat > "${SERVICE_FILE}" << 'EOF'
[Unit]
Description=Xray Service (custom installation)
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/etc/argox/xray run -c /etc/argox/xr.json
Restart=on-failure
RestartPreventExitStatus=23 254
LimitNOFILE=1048576
StandardOutput=null
StandardError=null

# 安全加固建议（可选，根据需求注释或删除）
# NoNewPrivileges=true
# PrivateTmp=true
# ProtectSystem=strict
# ProtectHome=yes
# PrivateDevices=yes

[Install]
WantedBy=multi-user.target
EOF

# ==================== 重新加载 systemd 并提示下一步 ====================
echo "重新加载 systemd daemon..."
systemctl daemon-reload

echo ""
echo "安装基本步骤已完成！"
echo ""
echo "接下来你需要："
echo "1. 编辑配置文件："
echo "   nano /etc/argox/xr.json"
echo ""
echo "2. 启动并设置开机自启（在配置正确后执行）："
echo "   systemctl enable --now xray"
echo ""
echo "3. 查看运行状态："
echo "   systemctl status xray"
echo ""
echo "4. 查看日志："
echo "   journalctl -u xray -ef"
echo ""

exit 0