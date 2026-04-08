---
name: feishu-add-bot
description: 快速添加新的飞书机器人并配置绑定关系。支持一键拓展机器人数量，不会出错。
trigger: 添加飞书机器人|新增飞书机器人|创建飞书机器人|添加bot|新增bot
---

# 添加飞书机器人技能

## 功能说明
一键添加新的飞书机器人到 OpenClaw 配置，包括：
1. 账户配置（App ID、App Secret、权限策略）
2. 代理配置（独立工作空间）
3. 绑定配置（消息路由）

## 输入参数
用户需要提供：
- `BOT名称`：如 bot4、bot5
- `App ID`：飞书应用 ID（cli_xxx）
- `App Secret`：飞书应用密钥
- `允许用户 OpenID`：允许私聊的用户 OpenID（ou_xxx）

## 执行步骤

### 1. 更新 openclaw.json

需要修改三个部分：

#### 1.1 添加账户配置（channels.feishu.accounts）
在 `accounts` 对象中添加新账户：
```json
"BOT名称": {
  "appId": "cli_xxx",
  "appSecret": {
    "source": "file",
    "provider": "lark-secrets",
    "id": "/lark/appSecrets/BOT名称"
  },
  "dmPolicy": "allowlist",
  "allowFrom": ["ou_xxx"],
  "groupPolicy": "allowlist",
  "groupAllowFrom": ["ou_xxx"]
}
```

#### 1.2 添加代理配置（agents.list）
在 `agents.list` 数组末尾添加：
```json
{
  "id": "BOT名称-agent",
  "name": "BOT名称-agent",
  "workspace": "/home/dking/.openclaw/workspaces/BOT名称"
}
```

#### 1.3 添加绑定配置（顶层 bindings）
在 `bindings` 数组末尾添加：
```json
{
  "type": "route",
  "agentId": "BOT名称-agent",
  "match": {
    "channel": "feishu",
    "accountId": "BOT名称"
  }
}
```

### 2. 更新 lark.secrets.json

添加 App Secret 到 secrets 文件：
```json
{
  "appSecrets": {
    "bot1": "xxx",
    "bot2": "xxx",
    "bot3": "xxx",
    "BOT名称": "App Secret"
  }
}
```

### 3. 创建工作空间

```bash
mkdir -p /home/dking/.openclaw/workspaces/BOT名称
mkdir -p /home/dking/.openclaw/workspaces/BOT名称/memory
```

复制基础文件到工作空间：
- SOUL.md
- AGENTS.md
- USER.md
- TOOLS.md
- HEARTBEAT.md

### 4. 验证配置

```bash
# 验证 JSON 语法
python3 -m json.tool /home/dking/.openclaw/openclaw.json

# 重启网关
openclaw gateway restart

# 检查日志
journalctl --user -u openclaw-gateway.service -n 30 --no-pager
```

### 5. 配置飞书开放平台

在飞书开放平台配置：
- Webhook URL: `http://公网IP:18789/lark/webhook/BOT名称`
- 事件订阅：message.*,im.chat.*,im.message.*
- 发布应用版本

## 重要提示

1. **OpenID 格式**：必须是 32 字符，如 `ou_4cd5e72446bd326d692fb6210fe34539`
2. **Bindings 位置**：必须在顶层 `bindings`，不是 `channels.feishu.bindings`
3. **字段名大小写**：使用 `accountId`（小写 d），不是 `accountID`
4. **验证生效**：查看日志确认 `dispatching to agent` 显示正确的 agent 名称

## 常见问题与解决方案

### 1. 网关启动失败 - SecretRef 错误

**错误信息**：
```
SecretRefResolutionError: JSON pointer segment "BOT名称" does not exist.
```

**排查步骤**：
1. 检查 `lark.secrets.json` 文件结构
2. App Secret 必须存储在 `lark.appSecrets.BOT名称`，不是顶层 `appSecrets`
3. 确认文件格式：
   ```json
   {
     "lark": {
       "appSecrets": {
         "bot1": "xxx",
         "BOT名称": "App Secret"
       }
     }
   }
   ```

### 2. 机器人无响应 - 用户不在 allowlist

**错误信息**：
```
feishu[BOT名称]: sender ou_xxx not in DM allowlist
```

**解决方案**：
1. 确认 `allowFrom` 和 `groupAllowFrom` 包含正确的用户 OpenID
2. 用户提供的 OpenID 可能有两个（不同机器人或不同账户）
3. 将两个 OpenID 都加入 allowlist
4. 重启网关让配置生效：`openclaw gateway restart`

### 3. 工作空间缺少 IDENTITY.md

**问题**：新创建的工作空间可能缺少 IDENTITY.md 文件

**解决方案**：复制模板文件
```bash
cp /home/dking/.openclaw/workspaces/bot1/IDENTITY.md /home/dking/.openclaw/workspaces/BOT名称/
```

### 4. 查看机器人的 OpenID

机器人也有自己的 OpenID，可用于识别或配置。

**查看方式**：查看日志中 `bot open_id resolved` 行
```
feishu[BOT名称]: bot open_id resolved: ou_xxx
```

### 5. 验证配置正确性

配置完成后，发送测试消息，检查日志确认：
- ✅ `received from ou_xxx in oc_xxx (p2p)` - 收到消息
- ✅ `dispatching to agent (session=agent:BOT名称-agent:...)` - 正确路由
- ✅ `reply completed` - 成功回复

如果看到 `not in DM allowlist`，说明用户 OpenID 未正确配置。

## 快速使用脚本

也可以使用脚本一键添加：
```bash
~/.openclaw/extensions/openclaw-lark/skills/feishu-add-bot/scripts/add_feishu_bot.sh <bot名称> <app_id> <app_secret> <允许用户openid>

# 示例
~/.openclaw/extensions/openclaw-lark/skills/feishu-add-bot/scripts/add_feishu_bot.sh bot4 cli_xxx xxx ou_xxx
```

脚本会自动完成：
- 更新 openclaw.json（账户、代理、绑定）
- 更新 lark.secrets.json
- 创建工作空间并复制基础文件
- 验证 JSON 语法
- 重启网关


## 所有内容均为Openclaw自行生成（除了这句话）
人类来提现存在感了
