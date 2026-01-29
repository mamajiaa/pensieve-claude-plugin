# 安装指南

Pensieve 分为两部分安装：**插件**（提供 hooks）和 **Skill**（提供能力）。

> **为什么分开？**
>
> - 插件：提供 Stop Hook（自动循环）和 SessionStart Hook（资源注入）
> - Skill：提供 pipelines、maxims、decisions 等内容，调用时无命名空间前缀
>
> 这样 Skill 可以用 `/pensieve` 直接调用，而不是 `/pensieve-plugin:pensieve`。

## 快速安装

### 1. 安装插件（hooks）

在 `.claude/settings.json` 中添加：

```json
{
  "plugins": [
    {
      "source": {
        "type": "url",
        "url": "https://github.com/kingkongshot/Pensieve"
      }
    }
  ]
}
```

### 2. 安装 Skill

```bash
# 克隆仓库到临时目录
git clone https://github.com/kingkongshot/Pensieve.git /tmp/pensieve

# 复制 skill 到项目
mkdir -p .claude/skills
cp -r /tmp/pensieve/skill .claude/skills/pensieve

# 清理
rm -rf /tmp/pensieve
```

### 3. 重启 Claude Code

说 `loop` 验证安装成功。

---

## 用户级安装

如果你想在所有项目中使用：

在 `~/.claude/settings.json` 中添加插件：

```json
{
  "plugins": [
    {
      "source": {
        "type": "url",
        "url": "https://github.com/kingkongshot/Pensieve"
      }
    }
  ]
}
```

安装 Skill 到用户级：

```bash
git clone https://github.com/kingkongshot/Pensieve.git /tmp/pensieve
mkdir -p ~/.claude/skills
cp -r /tmp/pensieve/skill ~/.claude/skills/pensieve
rm -rf /tmp/pensieve
```

---

## 面向 LLM 智能体

如果你是 LLM 智能体，帮用户执行以下步骤：

1. 克隆仓库并复制 skill：
```bash
git clone https://github.com/kingkongshot/Pensieve.git /tmp/pensieve
mkdir -p .claude/skills
cp -r /tmp/pensieve/skill .claude/skills/pensieve
rm -rf /tmp/pensieve
```

2. 配置 settings.json（如果不存在则创建）：
```bash
cat > .claude/settings.json << 'EOF'
{
  "plugins": [
    {
      "source": {
        "type": "url",
        "url": "https://github.com/kingkongshot/Pensieve"
      }
    }
  ]
}
EOF
```

3. 提醒用户重启 Claude Code

---

## 更新

### Git 方式

```bash
cd .claude/plugins/pensieve
git pull

# 同步 skill 更新
cp -r .claude/plugins/pensieve/skill/* .claude/skills/pensieve/
```

### Submodule 方式

```bash
git submodule update --remote .claude/plugins/pensieve

# 同步 skill 更新
cp -r .claude/plugins/pensieve/skill/* .claude/skills/pensieve/
```

---

## 卸载

1. 删除插件：`rm -rf .claude/plugins/pensieve`
2. 删除 skill：`rm -rf .claude/skills/pensieve`
3. 从 `.claude/settings.json` 中移除插件配置

---

## 验证安装

安装成功后：

1. 重启 Claude Code
2. 说 `loop`，应该触发 Loop Pipeline
3. 检查 `/help` 中是否有 `pensieve` skill

---

## 常见问题

### 安装后没有反应？

1. 确认已重启 Claude Code
2. 检查 `.claude/settings.json` 配置正确
3. 确认 `.claude/skills/pensieve/SKILL.md` 存在

### Hook 没有触发？

1. 检查 `hooks/hooks.json` 是否存在
2. 确认脚本有执行权限：`chmod +x .claude/plugins/pensieve/hooks/*.sh`

### Skill 未加载？

1. 确认复制到了正确位置：`.claude/skills/pensieve/`
2. 检查 `SKILL.md` 文件存在
