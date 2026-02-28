# 项目级目录约定

详细的结构迁移历史与判定规则见 `tools/doctor/migrations/README.md`（单一事实源）。

---

## 当前目标结构

唯一活跃根目录：`<project>/.claude/skills/pensieve/`

```
.claude/skills/pensieve/
  maxims/      # 团队准则（每条准则一个独立文件）
  decisions/   # 决策记录（ADR，日期-结论命名）
  knowledge/   # 外部参考知识（每个主题一个子目录/content.md）
  pipelines/   # 项目级 pipelines（必须 run-when-*.md 命名）
  loop/        # loop 运行产物（每次 loop 一个日期-slug 目录）
```

## 关键种子文件

初始化时由 `/init` 种子化（幂等，不覆盖已有）：

- `pipelines/run-when-reviewing-code.md` — 代码审查流程
- `pipelines/run-when-committing.md` — 提交流程
- `knowledge/taste-review/content.md` — 审查知识库
- `maxims/*.md` — 初始准则（从模板种子化）

## 自动维护文件

- `SKILL.md` — 项目级路由 + 图谱（工具自动更新）
- `_pensieve-graph.md` — 链接图谱

## 历史路径（deprecated）

以下路径为旧版本遗留，迁移后应清理：

- `<project>/skills/pensieve/` — 旧系统+用户数据混合目录
- `<project>/.claude/pensieve/` — 早期用户数据目录
