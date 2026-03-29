# Task 001: Setup Swarm Project Structure

**depends-on**: none

## Description

创建 Agent Swarm 模块的目录结构和基础配置文件。确保 `lib/swarm/` 目录下的所有子目录已创建，并配置 Hive type adapter 注册。

## Execution Context

**Task Number**: 1 of 25
**Phase**: Foundation
**Prerequisites**: None

## Files to Modify/Create

- Create: `lib/swarm/model/` directory
- Create: `lib/swarm/store/` directory
- Create: `lib/swarm/service/` directory
- Create: `lib/swarm/widget/` directory
- Create: `lib/swarm/widget/blocks/` directory
- Create: `lib/swarm/view/` directory
- Create: `lib/view/page/swarm/` directory
- Create: `.codecore/swarm/sessions/` directory

## Steps

### Step 1: Create Directory Structure
- 在 `lib/swarm/` 下创建 model、store、service、widget（含 blocks 子目录）、view 五个目录
- 在 `lib/view/page/` 下创建 swarm 子目录
- 在项目根目录下创建 `.codecore/swarm/sessions/` 目录（用于存储 agent 日志）

### Step 2: Verify Directory Creation
- 确认所有目录已创建且可访问
- 确认 `.codecore/swarm/sessions/` 在 .gitignore 中（如需要）

## Verification Commands

```bash
# Verify directories exist
ls lib/swarm/model/
ls lib/swarm/store/
ls lib/swarm/service/
ls lib/swarm/widget/
ls lib/swarm/widget/blocks/
ls lib/swarm/view/
ls lib/view/page/swarm/
```

## Success Criteria

- 所有目录已创建
- 目录结构符合 architecture.md 中的分层设计
