# Agent Swarm BDD Specifications

行为规范源文件位于 `test/agent_swarm.feature`（Gherkin 格式）。

## 概览

- **6 大功能模块，38 个场景**
- **1039 行 Gherkin 规范**
- **标记体系**：@happy-path (19), @critical (12), @edge-case (15), @error-case (10)

## 模块 A: Swarm Tab 基本功能

| 场景 | 标签 | 描述 |
|------|------|------|
| A-1 | @happy-path @critical | 创建新的 Agent Swarm 会话 |
| A-2 | @happy-path @critical | 创建 Swarm 时选择关联项目 |
| A-3 | @happy-path | 查看 Swarm 会话详情 |
| A-4 | @edge-case | 同时存在多个 Swarm 会话 |
| A-5 | @happy-path | 搜索和过滤 Swarm 会话 |
| A-6 | @happy-path | 删除 Swarm 会话 |

## 模块 B: Agent 生命周期

| 场景 | 标签 | 描述 |
|------|------|------|
| B-1 | @happy-path @critical | 启动新的 Agent 任务（选择类型、目录、参数） |
| B-2 | @happy-path @critical | 自动创建 git worktree 分支 |
| B-3 | @happy-path @critical | 实时显示 Agent 输出 |
| B-4 | @happy-path @critical | 向运行中的 Agent 注入命令 |
| B-5 | @happy-path | 优雅停止 Agent 任务 |
| B-6 | @happy-path @critical | 强制终止 Agent 任务 |
| B-7 | @edge-case | Agent 任务完成的自动状态变化 |
| B-8 | @edge-case | Agent 进程崩溃的自动状态变化 |

## 模块 C: Worktree 隔离

| 场景 | 标签 | 描述 |
|------|------|------|
| C-1 | @happy-path @critical | 自动为每个 Agent 创建独立的 worktree |
| C-2 | @happy-path | worktree 分支命名规范 |
| C-3 | @happy-path | Agent 完成后保留 worktree 选项 |
| C-4 | @happy-path | Agent 完成后删除 worktree 选项 |
| C-5 | @happy-path | worktree 列表管理 |

## 模块 D: Diff 和合并

| 场景 | 标签 | 描述 |
|------|------|------|
| D-1 | @happy-path @critical | 查看单个 Agent 的变更 diff |
| D-2 | @happy-path | 汇总查看 Swarm 中所有 Agent 的变更 |
| D-3 | @happy-path @critical | 执行 git merge 到主分支 |
| D-4 | @edge-case | 批量合并多个 Agent 的变更 |
| D-5 | @edge-case | 执行 git rebase |
| D-6 | @edge-case | 冲突检测和解决 |

## 模块 E: 项目管理

| 场景 | 标签 | 描述 |
|------|------|------|
| E-1 | @happy-path | 切换管理不同 git 项目 |
| E-2 | @happy-path | 同一项目内的多 Agent 协作 |
| E-3 | @happy-path | 自动保存 Swarm 会话历史 |
| E-4 | @happy-path | 恢复历史 Swarm 会话 |
| E-5 | @happy-path | 导出 Swarm 会话报告 |
| E-6 | @edge-case | 打开会话时工作目录不存在 |

## 模块 F: 错误和边界情况

| 场景 | 标签 | 描述 |
|------|------|------|
| F-1 | @error-case | git worktree 冲突处理 |
| F-2 | @error-case | Agent 进程僵死（超时强制终止） |
| F-3 | @error-case | Agent/Codex/Gemini CLI 命令不存在 |
| F-4 | @error-case | 工作目录不存在 |
| F-5 | @error-case | 磁盘空间不足 |
| F-6 | @error-case | 内存使用超限 |
| F-7 | @error-case | git 仓库损坏 |

## 测试策略

### 单元测试（Service 层）
- `WorktreeService`: git worktree 命令解析、异常处理
- `SwarmOrchestrator`: 并发控制、依赖解析、状态机转换
- `MergeService`: diff 解析、冲突检测

### Widget 测试
- `SwarmTerminalPanel`: 命令注入、多终端布局切换
- `AgentStatusCard`: 状态展示、颜色/图标映射
- `DiffViewer`: diff 渲染、滚动、大文件处理

### 集成测试
- 端到端 Swarm 会话创建和执行流程
- Worktree 生命周期（创建→运行→完成/删除）
- Diff + Merge 完整流程

### Mock 策略
- Mock `dart:io` Process 类用于 git 命令测试
- Mock `dart:io` Process 用于 agent 进程测试
- 使用内存 Hive box 替代持久化存储用于测试
