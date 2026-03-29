# Task 024: Export Report Feature

**depends-on**: task-023

## Description

实现导出 Swarm 会话报告功能——生成 Markdown 格式的会话报告并保存到文件系统。

## Execution Context

**Task Number**: 24 of 25
**Phase**: Phase 5 — Project Management
**Prerequisites**: Task 023 会话持久化已完成

## BDD Scenario

```gherkin
Scenario: 用户导出 Swarm 会话报告
  Given 用户已打开一个已完成的 Swarm 会话
  When 用户点击会话菜单中的"导出报告"
  Then 系统生成 Markdown 格式的报告
  And 文件保存到用户指定的位置
```

**Spec Source**: `test/agent_swarm.feature` (E-5)

## Files to Modify/Create

- Create: `lib/swarm/service/report_export_service.dart`

## Steps

### Step 1: Create ReportExportService
```dart
class ReportExportService {
  /// 导出 Markdown 报告
  static Future<String> exportMarkdown(SwarmSession session);

  /// 导出到文件
  static Future<File> exportToFile(
    SwarmSession session,
    String outputPath,
  );
}
```

### Step 2: Implement Markdown Report Format
报告应包含：
```
# Swarm Session: {title}

## 会话概览
- 项目: {rootPath}
- 创建时间: {createdAt}
- 总运行时长: {duration}

## 任务列表
| 任务 | 类型 | 状态 | 运行时长 | 分支 |
| ... | ... | ... | ... | ... |

## 变更汇总
{每个 agent 的变更文件列表}

## 终端日志摘要
{关键事件时间线}

## 合并状态
{各分支是否已合并到 main}
```

### Step 3: Add Export Button
- 在 `SwarmSession` 的卡片或菜单中添加「导出报告」按钮
- 使用 `file_picker` 包让用户选择保存路径
- 保存后显示 toast 通知

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/service/report_export_service.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/service/report_export_service.dart
```

## Success Criteria

- 导出的 Markdown 报告格式完整
- 包含所有必要章节（概览、任务、变更、日志、合并状态）
- 文件保存到用户指定路径
- 保存后有成功通知
