import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/service/cod_cli_runner.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';

/// 完全防溢出的CodePal标签页
class CodePalTabPage extends StatefulWidget {
  const CodePalTabPage({super.key});

  @override
  State<CodePalTabPage> createState() => _CodePalTabPageState();
}

class _CodePalTabPageState extends State<CodePalTabPage> {
  final _provider = ValueNotifier<String>('codex');
  final _titleCtrl = TextEditingController(text: '新会话');
  final _cwdCtrl = TextEditingController(text: Directory.current.path.replaceAll(r'\', '/'));
  final _argsCtrl = TextEditingController(text: 'resume');

  String? _selectedId;
  List<String> _logLines = const [];
  StreamSubscription<FileSystemEvent>? _logWatch;

  @override
  void dispose() {
    _provider.dispose();
    _titleCtrl.dispose();
    _cwdCtrl.dispose();
    _argsCtrl.dispose();
    _logWatch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listenable = CodSessionStore.listenable();
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 768;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: isCompact 
                ? _buildCompactLayout(listenable, constraints)
                : _buildWideLayout(listenable, constraints),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(ValueListenable<Box<CodSession>>? listenable, BoxConstraints constraints) {
    final leftPanelWidth = (constraints.maxWidth * 0.4).clamp(280.0, 400.0);
    
    return Row(
      children: [
        // 左侧面板 - 整体滚动
        SizedBox(
          width: leftPanelWidth,
          height: constraints.maxHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ValueListenableBuilder(
              valueListenable: listenable ?? ValueNotifier<Box<CodSession>>(Hive.box<CodSession>('temp')),
              builder: (context, box, child) {
                final sessions = CodSessionStore.all();
                return Column(
                  children: [
                    // 主要内容区域 - 整体滚动
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildCreateForm(constraints),
                            const Divider(height: 1),
                            _buildSessionsList(sessions, isScrollable: false),
                          ],
                        ),
                      ),
                    ),
                    // 日历组件 - 固定在底部
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                      ),
                      child: _buildCalendarWidget(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // 右侧内容
        Expanded(
          child: SizedBox(
            height: constraints.maxHeight,
            child: _selectedId == null ? _buildEmptyState() : _buildDetail(constraints),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(ValueListenable<Box<CodSession>>? listenable, BoxConstraints constraints) {
    return ValueListenableBuilder(
      valueListenable: listenable ?? ValueNotifier<Box<CodSession>>(Hive.box<CodSession>('temp')),
      builder: (context, box, child) {
        final sessions = CodSessionStore.all();

        if (_selectedId == null) {
          return Column(
            children: [
              // 主要内容 - 整体滚动
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCreateForm(constraints),
                      const Divider(height: 1),
                      _buildSessionsList(sessions, isScrollable: false),
                    ],
                  ),
                ),
              ),
              // 日历组件 - 固定在底部
              Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: _buildCalendarWidget(),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              // 返回按钮栏 - 固定高度
              _buildCompactHeader(constraints),
              // 详情内容 - 占用剩余空间
              Expanded(
                child: _buildDetail(constraints),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCompactHeader(BoxConstraints constraints) {
    return Container(
      height: 56,
      width: constraints.maxWidth,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedId = null),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回会话列表',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _getSessionTitle(),
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(BoxConstraints parentConstraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            '新建 / 恢复 CLI 会话',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Provider 选择器
          Text(
            '选择AI提供商',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<String>(
            valueListenable: _provider,
            builder: (context, selectedProvider, child) {
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildCompactChip('codex', 'Codex', selectedProvider, Icons.code),
                  _buildCompactChip('claude', 'Claude', selectedProvider, Icons.smart_toy),
                  _buildCompactChip('gemini', 'Gemini', selectedProvider, Icons.auto_awesome),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          // 表单字段 - 紧凑版本
          _buildCompactTextField(
            controller: _titleCtrl,
            label: '标题',
            icon: Icons.title,
          ),
          const SizedBox(height: 6),

          _buildCompactTextField(
            controller: _cwdCtrl,
            label: '工作目录',
            icon: Icons.folder_open,
          ),
          const SizedBox(height: 6),

          _buildCompactTextField(
            controller: _argsCtrl,
            label: '参数',
            icon: Icons.settings,
          ),

          const SizedBox(height: 8),

          // 按钮 - 垂直排列防止溢出
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _createAndRun,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('新建并运行', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _openLogDirectory,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('打开日志目录', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactChip(String value, String label, String selectedProvider, IconData icon) {
    final isSelected = selectedProvider == value;
    return InkWell(
      onTap: () => _provider.value = value,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      height: 48, // 固定高度
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<CodSession> sessions, {bool isScrollable = true}) {
    if (sessions.isEmpty) {
      return SizedBox(
        height: isScrollable ? null : 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('暂无会话', style: TextStyle(fontSize: 16)),
              SizedBox(height: 4),
              Text('创建您的第一个AI对话会话', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final sessionWidgets = sessions.map((session) {
      final isSelected = session.id == _selectedId;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 圆角设为8
        ),
        child: ListTile(
          selected: isSelected,
          dense: true,
          leading: _buildProviderAvatar(session.provider),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            '${session.provider} • ${session.status.name}\n${session.updatedAt.toLocal().toString().substring(0, 16)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          trailing: IconButton(
            onPressed: () => _deleteSession(session),
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: '删除会话',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          onTap: () => _selectSession(session),
        ),
      );
    }).toList();

    if (isScrollable) {
      return ListView(
        padding: const EdgeInsets.all(8),
        children: sessionWidgets,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sessionWidgets,
        ),
      );
    }
  }

  Widget _buildProviderAvatar(String provider) {
    Color color;
    IconData icon;
    
    switch (provider) {
      case 'claude':
        color = Colors.blue;
        icon = Icons.smart_toy;
        break;
      case 'gemini':
        color = Colors.green;
        icon = Icons.auto_awesome;
        break;
      case 'codex':
      default:
        color = Colors.grey;
        icon = Icons.code;
        break;
    }
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '选择或创建会话',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '创建一个新的AI对话会话或从左侧选择现有会话',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(BoxConstraints parentConstraints) {
    final session = _getSelectedSession();
    if (session == null) {
      return const Center(child: Text('会话不存在'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 会话信息头部 - 限制高度
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: parentConstraints.maxHeight * 0.3,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 会话标题行
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProviderAvatar(session.provider),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${session.provider} • ${session.status.name}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 详细信息
                _buildCompactInfoItem('目录', session.cwd.isEmpty ? '(默认)' : session.cwd),
                _buildCompactInfoItem('命令', '${session.command} ${session.args.join(" ")}'),
                _buildCompactInfoItem('日志', session.logPath),

                const SizedBox(height: 8),

                // 操作按钮
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildActionButton(
                      onPressed: () => CodCliRunner.run(session, onStdout: (_) => _reloadLog(session)),
                      icon: Icons.play_arrow,
                      label: '运行',
                      isPrimary: true,
                    ),
                    _buildActionButton(
                      onPressed: () => _reloadLog(session),
                      icon: Icons.refresh,
                      label: '刷新',
                    ),
                    _buildActionButton(
                      onPressed: () => _openLogFile(session),
                      icon: Icons.open_in_new,
                      label: '打开',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // 日志区域 - 占用剩余空间
        Expanded(
          child: Container(
            color: const Color(0xFF1E1E1E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日志标题
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: const Text(
                    '日志输出',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 日志内容
                Expanded(
                  child: _logLines.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无日志输出',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _logLines.length,
                          itemBuilder: (context, index) => SelectableText(
                            _logLines[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildCompactInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  CodSession? _getSelectedSession() {
    if (_selectedId == null) return null;
    try {
      return CodSessionStore.byId(_selectedId!);
    } catch (e) {
      setState(() => _selectedId = null);
      return null;
    }
  }

  String _getSessionTitle() {
    final session = _getSelectedSession();
    return session?.title ?? '会话详情';
  }

  Future<void> _openLogDirectory() async {
    try {
      await CodSessionStore.ensureDirs();
      final dir = CodSettingsStore.baseDir;
      if (Platform.isWindows) {
        Process.start('explorer', [dir]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开目录失败: $e')),
        );
      }
    }
  }

  // 操作方法
  Future<void> _createAndRun() async {
    try {
      final provider = _provider.value;
      final cli = CodSettingsStore.resolveCli(provider);
      final args = _argsCtrl.text.trim().isEmpty
          ? <String>[]
          : _argsCtrl.text.split(RegExp(r'\s+'));

      final session = await CodSessionStore.create(
        provider: provider,
        title: _titleCtrl.text.trim().isEmpty ? provider : _titleCtrl.text.trim(),
        cwd: _cwdCtrl.text.trim(),
        command: cli,
        args: args,
      );

      setState(() => _selectedId = session.id);
      await _reloadLog(session);
      await CodCliRunner.run(session, onStdout: (_) => _reloadLog(session));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建会话失败: $e')),
        );
      }
    }
  }

  Future<void> _selectSession(CodSession session) async {
    try {
      setState(() => _selectedId = session.id);
      await _reloadLog(session);
      _logWatch?.cancel();

      final file = File(session.logPath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      _logWatch = file
          .watch(events: FileSystemEvent.modify)
          .listen((_) => _reloadLog(session), onError: (_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择会话失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteSession(CodSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除会话 "${session.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CodSessionStore.remove(session.id);
        if (_selectedId == session.id) {
          setState(() {
            _selectedId = null;
            _logLines = const [];
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除会话失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _reloadLog(CodSession session) async {
    try {
      final file = File(session.logPath);
      if (await file.exists()) {
        final text = await file.readAsLines();
        if (mounted) {
          setState(() => _logLines = text);
        }
      } else {
        if (mounted) {
          setState(() => _logLines = const ['<暂无日志>']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logLines = ['<日志读取失败: $e>']);
      }
    }
  }

  Future<void> _openLogFile(CodSession session) async {
    try {
      final file = File(session.logPath);
      if (await file.exists()) {
        if (Platform.isWindows) {
          await Process.start('notepad.exe', [file.path]);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('日志文件不存在')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开日志文件失败: $e')),
        );
      }
    }
  }

  /// 日历组件 - 按照设计图实现
  Widget _buildCalendarWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日历头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Text(
                _getCurrentMonthText(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 日历网格
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cellSize = (availableWidth / 7).clamp(20.0, 35.0);
        
        return Column(
          children: [
            // 星期标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => SizedBox(
                        width: cellSize,
                        height: 20,
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            
            const SizedBox(height: 4),
            
            // 日期网格
            Expanded(
              child: _buildDateGrid(cellSize),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateGrid(double cellSize) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
    
    final weeks = <Widget>[];
    var currentDate = startDate;
    
    // 生成最多6周的日期
    for (int week = 0; week < 6; week++) {
      final weekDays = <Widget>[];
      
      for (int day = 0; day < 7; day++) {
        final isCurrentMonth = currentDate.month == _currentMonth.month;
        final isToday = currentDate.year == now.year && 
                       currentDate.month == now.month && 
                       currentDate.day == now.day;
        final hasSession = _hasSessionOnDate(currentDate);
        
        weekDays.add(
          GestureDetector(
            onTap: isCurrentMonth ? () => _onDateTapped(currentDate) : null,
            child: Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getDateColor(isCurrentMonth, isToday, hasSession),
                borderRadius: BorderRadius.circular(4),
                border: isToday 
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${currentDate.day}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasSession ? FontWeight.bold : FontWeight.normal,
                    color: _getDateTextColor(isCurrentMonth, isToday, hasSession),
                  ),
                ),
              ),
            ),
          ),
        );
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays,
        ),
      );
      
      // 如果当前行都不在当前月份，则停止生成
      if (currentDate.month != _currentMonth.month && week >= 4) {
        break;
      }
    }
    
    return Column(
      children: weeks,
    );
  }

  Color _getDateColor(bool isCurrentMonth, bool isToday, bool hasSession) {
    if (!isCurrentMonth) return Colors.transparent;
    
    if (hasSession) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    }
    
    if (isToday) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    }
    
    return Colors.transparent;
  }

  Color _getDateTextColor(bool isCurrentMonth, bool isToday, bool hasSession) {
    if (!isCurrentMonth) {
      return Colors.grey.withValues(alpha: 0.4);
    }
    
    if (hasSession) {
      return Theme.of(context).colorScheme.primary;
    }
    
    if (isToday) {
      return Theme.of(context).colorScheme.primary;
    }
    
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  }

  /// 日历状态管理
  DateTime _currentMonth = DateTime.now();

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  String _getCurrentMonthText() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _onDateTapped(DateTime date) {
    // 可以在这里添加点击日期的逻辑，比如筛选当天的会话
    if (kDebugMode) {
      debugPrint('Tapped on date: ${date.toString().substring(0, 10)}');
    }
  }

  bool _hasSessionOnDate(DateTime date) {
    final sessions = CodSessionStore.all();
    return sessions.any((session) {
      final sessionDate = session.updatedAt.toLocal();
      return sessionDate.year == date.year &&
             sessionDate.month == date.month &&
             sessionDate.day == date.day;
    });
  }
}