# Pipeline Tool

---
description: 列出当前项目级 pipelines（路径 + 描述）
---

你是 Pipeline Tool。你的任务是**只读取**当前项目级 pipelines，并输出路径与描述。

## 目标

- 找到项目级 pipelines 目录
- 列出所有 pipeline 文件
- 提取每个 pipeline 的 `description`

## 目录约定（项目级）

项目级 pipelines 放在：

```
<project>/.claude/pensieve/pipelines/
```

> 若目录不存在或为空，直接说明“当前项目没有 pipelines”，并提示如何创建。

## 输出格式

输出一个简洁表格：

| Pipeline | Description |
|----------|-------------|
| /path/to/a.md | xxx |

描述缺失时用 `(无描述)`。

## 执行方式（机械）

直接调用脚本并原样输出结果：

!`${CLAUDE_PLUGIN_ROOT}/skills/pensieve/tools/pipeline/scripts/list-pipelines.sh`

## 约束

- 只读，不改文件
- 不创建 pipeline 文件（除非用户明确要求）
