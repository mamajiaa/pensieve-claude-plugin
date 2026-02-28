# 工具边界

每个工具有明确职责边界。路由到错误工具时，按此表重定向。

---

## 职责定位（一句话）

| 工具 | 职责 | 不负责 |
|------|------|--------|
| `/upgrade` | 版本同步 + 结构迁移 | 不给 PASS/FAIL，不做逐文件语义审查 |
| `/doctor` | 只读体检 + 合规报告 | 不改文件，不做迁移 |
| `/self-improve` | 沉淀经验到四类用户数据 | 不做迁移/体检 |
| `/init` | 初始化项目目录 + 种子化 | 不做迁移清理 |
| `/loop` | 拆解复杂任务 + 子代理循环执行 | 小任务直接完成，不开 loop |
| `/pipeline` | 只读查看图谱与 pipeline 列表 | 不改写/执行 pipeline |

---

## 路由速查

| 用户意图 | 正确工具 | 常见误路由 |
|----------|----------|-----------|
| 更新插件版本 / 迁移旧数据 / 清理旧路径 | `/upgrade` | `/init`, `/doctor` |
| 新项目首次接入 / 补齐种子文件 | `/init` | `/upgrade`（除非有旧数据） |
| 合规检查 / PASS-FAIL 分级报告 | `/doctor` | `/upgrade`, `/self-improve` |
| 沉淀经验 / 写 maxim / decision / pipeline | `/self-improve` | `/doctor`, `/upgrade` |
| 复杂任务拆解自动执行 | `/loop` | 直接执行（小任务） |
| 查看可用 pipelines 或图谱 | `/pipeline` | `/self-improve`（只读不改） |
| 执行某个具体 pipeline | `/loop`（加载 pipeline） | `/pipeline`（只列不执行） |

---

## 负面示例

| 用户说 | 不应 | 应转 |
|--------|------|------|
| "项目里有旧版 skills/pensieve/，顺手帮我迁移" | 继续 init | `/upgrade` |
| "先给我 PASS/FAIL 体检结论" | init 或 upgrade 给结论 | `/doctor` |
| "先跑 doctor，再决定要不要 upgrade" | 反序执行 | `/upgrade`（upgrade-first） |
| "边检查边帮我改" | doctor 修改文件 | 先 `/doctor` 报告，再手动修 |
| "先自动把这次会话都沉淀了，不用我确认" | 自动沉淀 | `/self-improve`（可直接写入） |
| "改 1 个文案文件，顺便 loop" | 开 loop | 直接完成 |
