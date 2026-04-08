#!/bin/bash
# 添加飞书机器人脚本
# 用法: ./add_feishu_bot.sh <bot名称> <app_id> <app_secret> <允许用户openid>

set -e

BOT_NAME=$1
APP_ID=$2
APP_SECRET=$3
ALLOWED_USER=$4

if [ -z "$BOT_NAME" ] || [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ] || [ -z "$ALLOWED_USER" ]; then
    echo "用法: ./add_feishu_bot.sh <bot名称> <app_id> <app_secret> <允许用户openid>"
    echo "示例: ./add_feishu_bot.sh bot4 cli_xxx xxx ou_xxx"
    exit 1
fi

CONFIG_FILE="/home/dking/.openclaw/openclaw.json"
SECRETS_FILE="/home/dking/.openclaw/credentials/lark.secrets.json"
WORKSPACE_DIR="/home/dking/.openclaw/workspace-${BOT_NAME}"

echo "=== 添加飞书机器人: ${BOT_NAME} ==="

# 1. 读取当前配置
python3 << EOF
import json

# 读取 openclaw.json
with open('${CONFIG_FILE}', 'r') as f:
    config = json.load(f)

# 1.1 添加账户配置
config['channels']['feishu']['accounts']['${BOT_NAME}'] = {
    "appId": "${APP_ID}",
    "appSecret": {
        "source": "file",
        "provider": "lark-secrets",
        "id": "/lark/appSecrets/${BOT_NAME}"
    },
    "dmPolicy": "allowlist",
    "allowFrom": ["${ALLOWED_USER}"],
    "groupPolicy": "allowlist",
    "groupAllowFrom": ["${ALLOWED_USER}"]
}

# 1.2 添加代理配置
config['agents']['list'].append({
    "id": "${BOT_NAME}-agent",
    "name": "${BOT_NAME}-agent",
    "workspace": "/home/dking/.openclaw/workspace-${BOT_NAME}"
})

# 1.3 添加绑定配置
config['bindings'].append({
    "type": "route",
    "agentId": "${BOT_NAME}-agent",
    "match": {
        "channel": "feishu",
        "accountId": "${BOT_NAME}"
    }
})

# 保存
with open('${CONFIG_FILE}', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

print("✓ openclaw.json 已更新")
EOF

# 2. 更新 secrets 文件
python3 << EOF
import json

with open('${SECRETS_FILE}', 'r') as f:
    secrets = json.load(f)

if 'appSecrets' not in secrets:
    secrets['appSecrets'] = {}

secrets['appSecrets']['${BOT_NAME}'] = '${APP_SECRET}'

with open('${SECRETS_FILE}', 'w') as f:
    json.dump(secrets, f, indent=2, ensure_ascii=False)

print("✓ lark.secrets.json 已更新")
EOF

# 3. 创建工作空间
mkdir -p "${WORKSPACE_DIR}/memory"
echo "✓ 工作空间已创建: ${WORKSPACE_DIR}"

# 4. 复制基础文件
cp /home/dking/.openclaw/workspace/SOUL.md "${WORKSPACE_DIR}/" 2>/dev/null || true
cp /home/dking/.openclaw/workspace/AGENTS.md "${WORKSPACE_DIR}/" 2>/dev/null || true
cp /home/dking/.openclaw/workspace/USER.md "${WORKSPACE_DIR}/" 2>/dev/null || true
cp /home/dking/.openclaw/workspace/TOOLS.md "${WORKSPACE_DIR}/" 2>/dev/null || true
cp /home/dking/.openclaw/workspace/HEARTBEAT.md "${WORKSPACE_DIR}/" 2>/dev/null || true
echo "✓ 基础文件已复制"

# 5. 验证配置
python3 -m json.tool "${CONFIG_FILE}" > /dev/null && echo "✓ JSON 语法正确"

# 6. 重启网关
echo ""
echo "=== 重启网关 ==="
openclaw gateway restart

sleep 3

# 7. 检查状态
echo ""
echo "=== 检查日志 ==="
journalctl --user -u openclaw-gateway.service -n 20 --no-pager | grep -E "feishu\[${BOT_NAME}|error|failed" || true

echo ""
echo "=== 完成! ==="
echo "机器人 ${BOT_NAME} 已添加"
echo ""
echo "后续步骤:"
echo "1. 在飞书开放平台配置 Webhook: http://公网IP:18789/lark/webhook/${BOT_NAME}"
echo "2. 配置事件订阅: message.*, im.chat.*, im.message.*"
echo "3. 发布应用版本"