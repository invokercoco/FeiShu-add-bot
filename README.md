# feishu-add-bot

OpenClaw 飞书机器人快速添加 Skill。一键添加新的飞书机器人到 OpenClaw 配置，支持多机器人架构。

（所有内容均为Openclaw自行生成，除了这句话，我只是来体现一下人类的存在感）
## 功能

- 快速添加新的飞书机器人账户
- 自动创建独立代理和工作空间
- 配置消息路由绑定
- 自动化验证和测试

## 使用方式

当用户说"添加飞书机器人"、"新增机器人"等触发词时，调用此 Skill。

用户需要提供：
- `BOT名称`：如 bot4、bot5
- `App ID`：飞书应用 ID（cli_xxx）
- `App Secret`：飞书应用密钥
- `允许用户 OpenID`：允许私聊的用户 OpenID（ou_xxx）

## 手动使用脚本

```bash
./scripts/add_feishu_bot.sh <bot名称> <app_id> <app_secret> <允许用户openid>

# 示例
./scripts/add_feishu_bot.sh bot4 cli_xxx xxx ou_xxx
```

## 文件结构

```
feishu-add-bot/
├── SKILL.md                    # Skill 定义文档
├── README.md                   # 说明文档
└── scripts/
    └── add_feishu_bot.sh       # 自动添加脚本
```

## 文档

详见 [SKILL.md](./SKILL.md)

## License

MIT
