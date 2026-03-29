# Task 022: ProjectSelector and Project Switching UI

**depends-on**: task-021

## Description

实现项目选择器和跨项目切换功能。

## Execution Context

**Task Number**: 22 of 25
**Phase**: Phase 5 — Project Management
**Prerequisites**: Task 021 MergeResolver 已完成

## BDD Scenario

```gherkin
Scenario: 用户切换到不同的 git 项目
  Given 用户当前管理的是项目 "flutter_server_box"
  When 用户点击项目选择器
  Then 系统显示项目列表
  When 用户选择 "backend_api"
  Then 系统切换到该项目
  And 工作区显示该项目最新的 Swarm 会话或空状态
```

```gherkin
Scenario: 切换项目时存在运行中的任务
  Given 用户当前项目的 Swarm 会话中有运行中的 Agent 任务
  When 用户尝试切换到其他项目
  Then 系统显示警告并提供选项: 切换（后台继续）/ 全部停止后切换 / 取消
```

**Spec Source**: `test/agent_swarm.feature` (E-1, E-1 edge-case)

## Files to Modify/Create

- Create: `lib/swarm/widget/project_selector.dart`
- Create: `lib/swarm/service/project_discovery_service.dart`

## Steps

### Step 1: Create ProjectDiscoveryService
```dart
class ProjectDiscoveryService {
  /// 扫描常用目录下的 git 仓库
  Future<List<GitProject>> discoverProjects();

  /// 验证路径是否是 git 仓库
  Future<bool> isGitRepository(String path);

  /// 获取项目的 git 状态摘要
  Future<GitProjectStatus> getStatus(String path);
}

class GitProject {
  final String name;
  final String path;
  final String currentBranch;
  final int worktreeCount;
  final String? lastCommit;
}

class GitProjectStatus {
  final String branch;
  final bool hasUncommittedChanges;
  final List<String> uncommittedFiles;
}
```

### Step 2: Create ProjectSelector Widget
- 顶部下拉菜单或侧边栏面板
- 显示当前项目名称 + git 图标
- 点击展开：项目列表 + 添加新项目按钮
- 添加新项目：文本输入路径或文件夹选择器

### Step 3: Implement Switching Logic
- 切换前检查运行中的任务
- 如果有运行中任务，显示警告对话框
- 切换时重新加载 `SwarmSessionStore.all()` 过滤新项目

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/widget/project_selector.dart lib/swarm/service/project_discovery_service.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/project_selector.dart lib/swarm/service/project_discovery_service.dart
```

## Success Criteria

- ProjectSelector 显示当前项目和可用项目列表
- 项目切换正确刷新会话列表
- 运行中任务切换警告正确显示
- 添加新项目路径验证正确
