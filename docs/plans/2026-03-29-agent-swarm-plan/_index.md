# Agent Swarm Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** 实现 Agent Swarm 多 Agent 并行管理系统——Superset.sh 风格的多 agent 编排能力，集成到 flutter_server_box 中。

**Architecture:** 纯 Flutter 实现，分 5 阶段渐进式构建：
- Phase 1: Worktree 管理基础设施（git worktree subprocess）
- Phase 2: 增强终端（xterm.dart + stdin 命令注入）
- Phase 3: Swarm 编排引擎（依赖 DAG + 并发控制）
- Phase 4: Diff + Merge 集成（git diff/merge subprocess）
- Phase 5: 项目管理增强（跨项目 + 会话历史）

**Tech Stack:** Flutter/Dart, Hive, xterm.dart (computer 包), subprocess git worktree, highlight 包

**Design Support:**
- [BDD Specs](../2026-03-29-agent-swarm-design/bdd-specs.md)
- [Architecture](../2026-03-29-agent-swarm-design/architecture.md)
- [Best Practices](../2026-03-29-agent-swarm-design/best-practices.md)
- [Gherkin Feature](../test/agent_swarm.feature)

## Execution Plan

```yaml
tasks:
  # Foundation
  - id: "001"
    subject: "Setup Swarm project structure"
    slug: "setup-swarm-structure"
    type: "impl"
    depends-on: []
  - id: "002"
    subject: "Add AppTab.swarm enum and Hive registration"
    slug: "register-swarm-apptab-hive"
    type: "impl"
    depends-on: ["001"]

  # Phase 1: Worktree Management
  - id: "003"
    subject: "WorktreeService unit tests"
    slug: "worktree-service-test"
    type: "test"
    depends-on: ["002"]
  - id: "004"
    subject: "WorktreeService implementation"
    slug: "worktree-service-impl"
    type: "impl"
    depends-on: ["003"]
  - id: "005"
    subject: "Worktree model + Store implementation"
    slug: "worktree-model-store-impl"
    type: "impl"
    depends-on: ["004"]
  - id: "006"
    subject: "Worktree manager page UI"
    slug: "worktree-manager-page-impl"
    type: "impl"
    depends-on: ["005"]

  # Phase 2: Enhanced Terminal
  - id: "007"
    subject: "CodCliRunner.injectCommand extension"
    slug: "cli-runner-inject-impl"
    type: "impl"
    depends-on: ["006"]
  - id: "008"
    subject: "SwarmTerminalPanel widget tests"
    slug: "terminal-panel-test"
    type: "test"
    depends-on: ["007"]
  - id: "009"
    subject: "SwarmTerminalPanel widget implementation"
    slug: "terminal-panel-impl"
    type: "impl"
    depends-on: ["008"]
  - id: "010"
    subject: "AgentStatusCard widget implementation"
    slug: "agent-status-card-impl"
    type: "impl"
    depends-on: ["009"]
  - id: "011"
    subject: "SwarmMultiTerminal layout widget"
    slug: "multi-terminal-layout-impl"
    type: "impl"
    depends-on: ["010"]

  # Phase 3: Swarm Orchestration
  - id: "012"
    subject: "SwarmOrchestrator core engine tests"
    slug: "orchestrator-core-test"
    type: "test"
    depends-on: ["011"]
  - id: "013"
    subject: "SwarmOrchestrator core engine implementation"
    slug: "orchestrator-core-impl"
    type: "impl"
    depends-on: ["012"]
  - id: "014"
    subject: "AgentInstance + AgentTask + SwarmSession models"
    slug: "swarm-models-impl"
    type: "impl"
    depends-on: ["013"]
  - id: "015"
    subject: "SwarmSessionStore implementation"
    slug: "swarm-session-store-impl"
    type: "impl"
    depends-on: ["014"]
  - id: "016"
    subject: "SwarmTab entry and SwarmDashboard layout"
    slug: "swarm-tab-dashboard-impl"
    type: "impl"
    depends-on: ["015"]
  - id: "017"
    subject: "NewSwarmDialog and NewAgentDialog"
    slug: "swarm-dialogs-impl"
    type: "impl"
    depends-on: ["016"]
  - id: "018"
    subject: "Swarm integration tests"
    slug: "swarm-integration-test"
    type: "test"
    depends-on: ["017"]

  # Phase 4: Diff + Merge
  - id: "019"
    subject: "MergeService implementation"
    slug: "merge-service-impl"
    type: "impl"
    depends-on: ["018"]
  - id: "020"
    subject: "DiffViewer widget implementation"
    slug: "diff-viewer-impl"
    type: "impl"
    depends-on: ["019"]
  - id: "021"
    subject: "MergeResolver widget implementation"
    slug: "merge-resolver-impl"
    type: "impl"
    depends-on: ["020"]

  # Phase 5: Project Management
  - id: "022"
    subject: "ProjectSelector and project switching UI"
    slug: "project-selector-impl"
    type: "impl"
    depends-on: ["021"]
  - id: "023"
    subject: "Session auto-save and restore flow"
    slug: "session-persist-impl"
    type: "impl"
    depends-on: ["022"]
  - id: "024"
    subject: "Export report feature"
    slug: "export-report-impl"
    type: "impl"
    depends-on: ["023"]
  - id: "025"
    subject: "Error handling and edge case UI"
    slug: "error-ui-impl"
    type: "impl"
    depends-on: ["024"]
```

## Task File References

- [Task 001: Setup Swarm project structure](./task-001-setup-swarm-structure.md)
- [Task 002: Add AppTab.swarm enum and Hive registration](./task-002-register-swarm-apptab-hive.md)
- [Task 003: WorktreeService unit tests](./task-003-worktree-service-test.md)
- [Task 004: WorktreeService implementation](./task-004-worktree-service-impl.md)
- [Task 005: Worktree model + Store implementation](./task-005-worktree-model-store-impl.md)
- [Task 006: Worktree manager page UI](./task-006-worktree-manager-page-impl.md)
- [Task 007: CodCliRunner.injectCommand extension](./task-007-cli-runner-inject-impl.md)
- [Task 008: SwarmTerminalPanel widget tests](./task-008-terminal-panel-test.md)
- [Task 009: SwarmTerminalPanel widget implementation](./task-009-terminal-panel-impl.md)
- [Task 010: AgentStatusCard widget implementation](./task-010-agent-status-card-impl.md)
- [Task 011: SwarmMultiTerminal layout widget](./task-011-multi-terminal-layout-impl.md)
- [Task 012: SwarmOrchestrator core engine tests](./task-012-orchestrator-core-test.md)
- [Task 013: SwarmOrchestrator core engine implementation](./task-013-orchestrator-core-impl.md)
- [Task 014: AgentInstance + AgentTask + SwarmSession models](./task-014-swarm-models-impl.md)
- [Task 015: SwarmSessionStore implementation](./task-015-swarm-session-store-impl.md)
- [Task 016: SwarmTab entry and SwarmDashboard layout](./task-016-swarm-tab-dashboard-impl.md)
- [Task 017: NewSwarmDialog and NewAgentDialog](./task-017-swarm-dialogs-impl.md)
- [Task 018: Swarm integration tests](./task-018-swarm-integration-test.md)
- [Task 019: MergeService implementation](./task-019-merge-service-impl.md)
- [Task 020: DiffViewer widget implementation](./task-020-diff-viewer-impl.md)
- [Task 021: MergeResolver widget implementation](./task-021-merge-resolver-impl.md)
- [Task 022: ProjectSelector and project switching UI](./task-022-project-selector-impl.md)
- [Task 023: Session auto-save and restore flow](./task-023-session-persist-impl.md)
- [Task 024: Export report feature](./task-024-export-report-impl.md)
- [Task 025: Error handling and edge case UI](./task-025-error-ui-impl.md)

## BDD Coverage

All 38 BDD scenarios from `test/agent_swarm.feature` are mapped:

| Module | Scenarios | Covered by Tasks |
|--------|-----------|-----------------|
| A: Swarm Tab Basic | A-1 ~ A-6 | 001, 002, 016, 017, 025 |
| B: Agent Lifecycle | B-1 ~ B-8 | 007, 008, 009, 010, 011, 012, 013, 017, 018, 025 |
| C: Worktree Isolation | C-1 ~ C-5 | 003, 004, 005, 006, 013 |
| D: Diff & Merge | D-1 ~ D-6 | 019, 020, 021 |
| E: Project Management | E-1 ~ E-6 | 022, 023, 024 |
| F: Error Handling | F-1 ~ F-7 | 004, 013, 025 |

## Dependency Chain

```
001 (setup)
  └─→ 002 (apptab+hive)
        └─→ 003 (worktree test)
              └─→ 004 (worktree svc)
                    └─→ 005 (worktree model+store)
                          └─→ 006 (worktree page)
                                └─→ 007 (cli runner inject)
                                      └─→ 008 (terminal test)
                                            └─→ 009 (terminal panel)
                                                  └─→ 010 (status card)
                                                        └─→ 011 (multi-terminal)
                                                              └─→ 012 (orchestrator test)
                                                                    └─→ 013 (orchestrator core)
                                                                          └─→ 014 (swarm models)
                                                                                └─→ 015 (session store)
                                                                                      └─→ 016 (tab+dashboard)
                                                                                            └─→ 017 (dialogs)
                                                                                                  └─→ 018 (integration test)
                                                                                                        └─→ 019 (merge service)
                                                                                                              └─→ 020 (diff viewer)
                                                                                                                    └─→ 021 (merge resolver)
                                                                                                                          └─→ 022 (project selector)
                                                                                                                                └─→ 023 (session persist)
                                                                                                                                      └─→ 024 (export report)
                                                                                                                                            └─→ 025 (error UI)
```

**Analysis**:
- Linear dependency chain — each phase builds on the previous
- Phase 1 (003-006) provides infrastructure for Phase 2 (007-011)
- Phase 2 (terminal) enables Phase 3 (orchestrator + UI)
- Phase 3 UI enables Phase 4 (diff/merge)
- Phase 4 enables Phase 5 (project management)
- No cycles, clean sequential dependency

---

## Execution Handoff

**Plan complete and saved to `docs/plans/2026-03-29-agent-swarm-plan/`. Execution options:**

**1. Orchestrated Execution (Recommended)** - Load `superpowers:executing-plans` skill using the Skill tool.

**2. BDD-Focused Execution** - Load `superpowers:behavior-driven-development` skill for specific scenarios.
