import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/service/cod_cli_runner.dart';
import 'package:server_box/codecore/service/cod_conversation_parser.dart';
import 'package:server_box/codecore/service/cod_history_importer.dart';
import 'package:server_box/codecore/service/cod_launcher.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';
import 'package:server_box/codecore/widget/cod_embedded_terminal.dart';
import 'package:server_box/view/page/codecore/widgets/cod_config_panel.dart';

/// 支持历史导入、对话流展示、内置终端、Resume功能
class CodePalTabPage extends StatefulWidget {
  const CodePalTabPage({super.key});

  @override
  State<CodePalTabPage> createState() => _CodePalTabPageState();
}

class _CodePalTabPageState extends State<CodePalTabPage> {
  final _provider = ValueNotifier<String>('claude');
  final _titleCtrl = TextEditingController(text: '新会话');
  final _cwdCtrl =
      TextEditingController(text: Directory.current.path.replaceAll(r'\', '/'));
  final _argsCtrl = TextEditingController(text: 'resume');
  final _searchCtrl = TextEditingController();
  final _conversationSearchCtrl = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedId;
  List<ConversationMessage> _conversation = const [];
  StreamSubscription<FileSystemEvent>? _logWatch;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Filter state
  String _selectedProject = 'All';
  String _sortBy = 'Recent';
  String _calendarTab = 'Last Updated';

  // UI state
  bool _showEnvironmentContext = false;
  bool _showTaskInstructions = false;
  bool _showTerminal = false;

  // CLI availability state
  Map<String, AvailabilityCheck> _cliAvailability = {};
  bool _isImporting = false;

  // 项目分类
  final List<Map<String, dynamic>> _projects = [
    {'name': 'All', 'icon': Icons.folder_outlined, 'color': Colors.orange},
    {'name': 'Claude', 'icon': Icons.smart_toy, 'color': Colors.orange},
    {'name': 'Codex', 'icon': Icons.code, 'color': Colors.blue},
    {'name': 'Gemini', 'icon': Icons.auto_awesome, 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _checkCliAvailability();
  }

  Future<void> _checkCliAvailability() async {
    try {
      final availability = await CodLauncher.checkAllCliAvailability();
      if (mounted) {
        setState(() => _cliAvailability = availability);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    _titleCtrl.dispose();
    _cwdCtrl.dispose();
    _argsCtrl.dispose();
    _searchCtrl.dispose();
    _conversationSearchCtrl.dispose();
    _scrollController.dispose();
    _logWatch?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: isCompact ? _buildCompactLayout() : _buildThreeColumnLayout(),
      ),
    );
  }

  /// 三栏布局 - 完美还原设计图
  Widget _buildThreeColumnLayout() {
    return Row(
      children: [
        // 第一栏：左侧项目导航栏 (固定宽度)
        _buildLeftSidebar(),

        // 第二栏：中间会话列表
        SizedBox(
          width: 420,
          child: _buildMiddleColumn(),
        ),

        // 第三栏：右侧详情面板
        Expanded(
          child: _selectedId != null
              ? _buildRightDetailPanel()
              : _buildEmptyDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return ValueListenableBuilder(
      valueListenable: CodSessionStore.listenable() ??
          ValueNotifier<Box<CodSession>>(Hive.box<CodSession>('temp')),
      builder: (context, box, child) {
        if (_selectedId == null) {
          return _buildMiddleColumn();
        } else {
          return Column(
            children: [
              _buildCompactHeader(),
              Expanded(child: _buildRightDetailPanel()),
            ],
          );
        }
      },
    );
  }

  /// 左侧导航栏
  Widget _buildLeftSidebar() {
    final sessions = CodSessionStore.all();

    return Container(
      width: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：Projects + 添加按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Projects',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.grey.shade500, size: 18),
                  onPressed: _showNewProjectDialog,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),

          // 项目列表
          ..._projects.map((project) {
            final isSelected = _selectedProject == project['name'];
            final count =
                _getProjectSessionCount(sessions, project['name'] as String);
            final total = sessions.length;

            return InkWell(
              onTap: () =>
                  setState(() => _selectedProject = project['name'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF2D2D2D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: project['color'] as Color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        project['name'] as String,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$count/$total',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.more_horiz,
                          color: Colors.grey.shade600, size: 14),
                    ],
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // 底部日历
          _buildSidebarCalendar(),
        ],
      ),
    );
  }

  /// 侧边栏日历
  Widget _buildSidebarCalendar() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      child: Column(
        children: [
          // 月份导航
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.grey, size: 16),
                  onPressed: () => setState(() => _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
                Expanded(
                  child: Text(
                    _getMonthYearString(_focusedDay),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 16),
                  onPressed: () => setState(() => _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1)),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                ),
              ],
            ),
          ),

          // Created / Last Updated 切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _buildCalendarTab('Created'),
                const SizedBox(width: 4),
                _buildCalendarTab('Last Updated'),
              ],
            ),
          ),

          const SizedBox(height: 6),
          _buildMiniCalendarGrid(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(String label) {
    final isSelected = _calendarTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _calendarTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade500,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCalendarGrid() {
    final sessions = CodSessionStore.all();
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    final sessionDays = <int>{};
    for (final session in sessions) {
      final date =
          _calendarTab == 'Created' ? session.createdAt : session.updatedAt;
      if (date.year == _focusedDay.year && date.month == _focusedDay.month) {
        sessionDays.add(date.day);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          // 星期标题
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
          // 日期网格
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 18));
                }

                final isToday = _isToday(
                    DateTime(_focusedDay.year, _focusedDay.month, dayNumber));
                final isSelected = _selectedDay?.day == dayNumber &&
                    _selectedDay?.month == _focusedDay.month &&
                    _selectedDay?.year == _focusedDay.year;
                final hasSession = sessionDays.contains(dayNumber);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDay = null;
                        } else {
                          _selectedDay = DateTime(
                              _focusedDay.year, _focusedDay.month, dayNumber);
                        }
                      });
                    },
                    child: Container(
                      height: 18,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue
                            : isToday
                                ? Colors.blue.withOpacity(0.3)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border: hasSession && !isSelected
                            ? Border.all(
                                color: Colors.orange.withOpacity(0.5), width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            color: isSelected || isToday
                                ? Colors.white
                                : Colors.grey.shade400,
                            fontSize: 9,
                            fontWeight: hasSession
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  /// 中间会话列表栏
  Widget _buildMiddleColumn() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          right: BorderSide(color: Color(0xFF2D2D2D)),
        ),
      ),
      child: Column(
        children: [
          _buildMiddleHeader(),
          // 排序工具栏
          _buildSortToolbar(),
          // 会话列表
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: CodSessionStore.listenable() ??
                  ValueNotifier<Box<CodSession>>(Hive.box<CodSession>('temp')),
              builder: (context, box, child) {
                final sessions = _getFilteredSessions();
                return _buildSessionList(sessions);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 中间栏头部
  Widget _buildMiddleHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
      ),
      child: Row(
        children: [
          // CodePal Logo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.code, color: Colors.orange, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'CodePal',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // 搜索框
          Expanded(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search title or comment',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 导入历史按钮
          IconButton(
            icon: _isImporting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade500,
                    ),
                  )
                : Icon(Icons.history, color: Colors.grey.shade500, size: 18),
            onPressed: _isImporting ? null : _importHistorySessions,
            tooltip: '导入历史',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // 刷新按钮
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade500, size: 18),
            onPressed: _checkCliAvailability,
            tooltip: '刷新CLI状态',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // 配置按钮
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey.shade500, size: 18),
            onPressed: _showConfigDialog,
            tooltip: 'CLI配置管理',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 排序工具栏
  Widget _buildSortToolbar() {
    final sessions = CodSessionStore.all();
    final totalDuration = _calculateTotalDuration(sessions);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
      ),
      child: Row(
        children: [
          // 排序选项 - 使用 Expanded 包裹 SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildSortButtons()),
            ),
          ),
          const SizedBox(width: 8),
          // 统计信息
          Icon(Icons.timer_outlined, color: Colors.grey.shade600, size: 12),
          const SizedBox(width: 2),
          Text(totalDuration,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          const SizedBox(width: 8),
          Icon(Icons.chat_bubble_outline,
              color: Colors.grey.shade600, size: 12),
          const SizedBox(width: 2),
          Text('${sessions.length}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }

  List<Widget> _buildSortButtons() {
    final sortOptions = ['Recent', 'Duration', 'Activity', 'A-Z', 'Size'];

    return sortOptions.map((option) {
      final isSelected = _sortBy == option;
      return Padding(
        padding: const EdgeInsets.only(right: 3),
        child: InkWell(
          onTap: () => setState(() => _sortBy = option),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade500,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 会话列表 - 时间线布局
  Widget _buildSessionList(List<CodSession> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyState();
    }

    final groupedSessions = _groupSessionsByDate(sessions);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedSessions.length,
      itemBuilder: (context, index) {
        final entry = groupedSessions.entries.elementAt(index);
        final dateLabel = entry.key;
        final dateSessions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期分组标题
            _buildDateHeader(dateLabel, dateSessions),
            // 时间线会话卡片
            ...dateSessions.asMap().entries.map((e) =>
                _buildTimelineSessionCard(e.value,
                    isLast: e.key == dateSessions.length - 1)),
          ],
        );
      },
    );
  }

  /// 日期分组头部
  Widget _buildDateHeader(String dateLabel, List<CodSession> sessions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${sessions.length}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _calculateGroupDuration(sessions),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// 时间线会话卡片
  Widget _buildTimelineSessionCard(CodSession session, {bool isLast = false}) {
    final isSelected = session.id == _selectedId;
    final duration = session.updatedAt.difference(session.createdAt);
    final durationStr = _formatDuration(duration);
    final timeStr = _formatTime(session.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧时间线
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: isSelected ? Colors.orange : Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // 时间线连接器
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.orange
                      : _getProviderColor(session.provider),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.orange.shade300
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // 会话卡片内容
          Expanded(
            child: _buildSessionCardContent(
                session, isSelected, durationStr, duration),
          ),
        ],
      ),
    );
  }

  /// 会话卡片内容
  Widget _buildSessionCardContent(
    CodSession session,
    bool isSelected,
    String durationStr,
    Duration duration,
  ) {
    return InkWell(
      onTap: () => _selectSession(session),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6, right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2520) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                // 提供商图标
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getProviderColor(session.provider).withOpacity(0.3),
                        _getProviderColor(session.provider).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getProviderIcon(session.provider),
                    color: _getProviderColor(session.provider),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(
                      color: isSelected ? Colors.orange : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 状态指示器
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(session.status).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 元信息行
            Row(
              children: [
                _buildInfoChip(Icons.schedule, durationStr),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildInfoChip(
                      Icons.folder_outlined, _getShortPath(session.cwd)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        _getProviderColor(session.provider).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          _getProviderColor(session.provider).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    session.provider.toUpperCase(),
                    style: TextStyle(
                      color: _getProviderColor(session.provider),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // 操作按钮行
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.start,
              children: [
                _buildActionButton(
                  'Resume',
                  Icons.play_arrow,
                  Colors.green,
                  () => _resumeSession(session),
                ),
                _buildActionButton(
                  'Terminal',
                  Icons.terminal,
                  Colors.blue,
                  () => _openTerminal(session),
                ),
                _buildActionButton(
                  'Copy Cmd',
                  Icons.copy,
                  Colors.grey,
                  () => _copyResumeCommand(session),
                ),
                _buildActionButton(
                  'Delete',
                  Icons.delete_outline,
                  Colors.red,
                  () => _confirmDeleteSession(session),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 信息标签
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 11),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 操作按钮
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取短路径
  String _getShortPath(String path) {
    if (path.isEmpty) return 'N/A';
    final parts = path.split(Platform.isWindows ? '\\' : '/');
    if (parts.length <= 2) return path;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 右侧详情面板
  Widget _buildRightDetailPanel() {
    final session = _getSelectedSession();
    if (session == null) {
      return _buildEmptyDetailPanel();
    }

    final duration = session.updatedAt.difference(session.createdAt);
    final isHistory = _isHistorySession(session);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildDetailHeader(session, isHistory),
          // 会话信息网格
          _buildInfoGrid(session, duration),
          // 可折叠区域
          _buildCollapsibleSection(
              'Environment Context',
              _showEnvironmentContext,
              () => setState(
                  () => _showEnvironmentContext = !_showEnvironmentContext),
              _buildEnvironmentContextContent(session)),
          _buildCollapsibleSection(
              'Task Instructions',
              _showTaskInstructions,
              () => setState(
                  () => _showTaskInstructions = !_showTaskInstructions),
              _buildTaskInstructionsContent(session)),
          // 内置终端或对话区域
          Expanded(
            child: _showTerminal
                ? _buildTerminalView(session)
                : _buildConversationArea(session),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(CodSession session, bool isHistory) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Text(
            session.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 按钮行 - 使用 Wrap 防止溢出
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // Resume 按钮
              _buildHeaderButton(
                  isHistory ? 'Resume' : 'Run',
                  Icons.play_arrow,
                  () => isHistory
                      ? _resumeSession(session)
                      : _runSession(session),
                  primary: true),
              // 在终端中运行按钮
              PopupMenuButton<String>(
                tooltip: '在终端中运行',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Terminal',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                      const SizedBox(width: 3),
                      Icon(Icons.expand_more,
                          color: Colors.grey.shade500, size: 12),
                    ],
                  ),
                ),
                onSelected: (terminal) => _runInTerminal(session, terminal),
                itemBuilder: (context) => CodCliRunner.getAvailableTerminals()
                    .map((t) => PopupMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
              // 内置终端切换
              _buildHeaderButton(
                _showTerminal ? 'Conversation' : 'Terminal',
                _showTerminal ? Icons.chat : Icons.terminal,
                () => setState(() => _showTerminal = !_showTerminal),
              ),
              // 复制命令
              _buildHeaderButton(
                'Copy',
                Icons.copy_outlined,
                () => _copyResumeCommand(session),
              ),
              // 打开日志
              _buildHeaderButton(
                'Log',
                Icons.open_in_new,
                () => _openLogFile(session),
              ),
              // 删除会话
              _buildHeaderButton(
                'Delete',
                Icons.delete_outline,
                () => _confirmDeleteSession(session),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String label, IconData icon, VoidCallback onPressed,
      {bool primary = false, bool isDestructive = false}) {
    final color = isDestructive
        ? Colors.red
        : (primary ? Colors.blue : const Color(0xFF2D2D2D));
    final borderColor = isDestructive
        ? Colors.red
        : (primary ? Colors.blue : const Color(0xFF3A3A3A));

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isDestructive ? Colors.red : Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white,
                  fontSize: 10,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(CodSession session, Duration duration) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildInfoCell('STARTED', _formatDateTimeShort(session.createdAt)),
          _buildInfoCell('DURATION', _formatDuration(duration)),
          _buildInfoCell('MODEL', _capitalizeFirst(session.provider)),
          _buildInfoCell('CLI VERSION',
              _cliAvailability[session.provider]?.version ?? 'N/A'),
          _buildInfoCell(
              'ORIGINATOR', '${_capitalizeFirst(session.provider)} Code'),
          _buildInfoCell('WORKING DIRECTORY',
              session.cwd.isEmpty ? '(default)' : _getShortPath(session.cwd),
              width: 150),
          _buildInfoCell('FILE SIZE', _getLogFileSize(session)),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value, {double width = 90}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getInfoIcon(label), color: Colors.grey.shade600, size: 10),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 8,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  IconData _getInfoIcon(String label) {
    switch (label) {
      case 'STARTED':
        return Icons.schedule;
      case 'DURATION':
        return Icons.timer_outlined;
      case 'MODEL':
        return Icons.smart_toy_outlined;
      case 'CLI VERSION':
        return Icons.terminal;
      case 'ORIGINATOR':
        return Icons.code;
      case 'WORKING DIRECTORY':
        return Icons.folder_outlined;
      case 'FILE SIZE':
        return Icons.insert_drive_file_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildCollapsibleSection(
      String title, bool isExpanded, VoidCallback onToggle, Widget content) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1F1F1F),
              border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
            ),
            child: Row(
              children: [
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey,
                    size: 18),
                const SizedBox(width: 6),
                Icon(Icons.check_box_outline_blank,
                    color: Colors.grey.shade600, size: 14),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
            ),
            child: content,
          ),
      ],
    );
  }

  Widget _buildEnvironmentContextContent(CodSession session) {
    final resumeCmd = CodCliRunner.buildResumeCommand(session);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnvRow('Resume Command', resumeCmd),
        _buildEnvRow(
            'Full Command', '${session.command} ${session.args.join(" ")}'),
        _buildEnvRow('Working Directory',
            session.cwd.isEmpty ? '(default)' : session.cwd),
        _buildEnvRow('Log Path', session.logPath),
        _buildEnvRow('Status', _getStatusDisplayName(session.status)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _copyResumeCommand(session),
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy Command', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openWorkingDirectory(session),
              icon: const Icon(Icons.folder_open, size: 14),
              label: const Text('Open Folder', style: TextStyle(fontSize: 10)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade600),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10))),
          const SizedBox(width: 4),
          Expanded(
              child: SelectableText(value,
                  style: const TextStyle(color: Colors.white, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildTaskInstructionsContent(CodSession session) {
    return Text(
      '使用 ${_capitalizeFirst(session.provider)} CLI 进行对话和代码生成任务。\n\n'
      '恢复会话命令: ${CodCliRunner.buildResumeCommand(session)}',
      style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.5),
    );
  }

  /// 内置终端视图
  Widget _buildTerminalView(CodSession session) {
    return CodEmbeddedTerminal(
      session: session,
      workingDirectory: session.cwd.isNotEmpty ? session.cwd : null,
      onClose: () => setState(() => _showTerminal = false),
    );
  }

  Widget _buildConversationArea(CodSession session) {
    final stats = CodConversationParser.getStats(_conversation);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // 对话标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text('Conversation',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(stats.summary,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 9)),
                    const Spacer(),
                    Text('Newest First',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 9)),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500, size: 12),
                  ],
                ),
                const SizedBox(height: 6),
                // 筛选输入框
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _conversationSearchCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          decoration: InputDecoration(
                            hintText: 'Filter...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade600, fontSize: 10),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4)),
                        child: Text('Expand',
                            style: TextStyle(
                                color: Colors.blue.shade400, fontSize: 9)),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Colors.grey.shade500, size: 14),
                        onPressed: () => _reloadConversation(session),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 对话内容
          Expanded(
            child: _conversation.isEmpty
                ? _buildEmptyConversation()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversation.length,
                    itemBuilder: (context, index) =>
                        _buildConversationMessage(_conversation[index], index),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 40, color: Colors.grey.shade700),
          const SizedBox(height: 12),
          Text('暂无对话记录',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 4),
          Text('运行会话后，对话将显示在这里',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildConversationMessage(ConversationMessage msg, int index) {
    Color bgColor;
    Color borderColor;
    Color roleColor;

    if (msg.isUser) {
      bgColor = const Color(0xFF2A2A2A);
      borderColor = Colors.grey.shade700;
      roleColor = Colors.orange;
    } else if (msg.isAssistant) {
      bgColor = const Color(0xFF1F2D3D);
      borderColor = Colors.blue.shade800;
      roleColor = Colors.blue;
    } else if (msg.isTool) {
      bgColor = const Color(0xFF2D2D1F);
      borderColor = Colors.yellow.shade800;
      roleColor = Colors.yellow;
    } else {
      bgColor = const Color(0xFF252525);
      borderColor = Colors.grey.shade800;
      roleColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  msg.isUser
                      ? Icons.person
                      : msg.isAssistant
                          ? Icons.smart_toy
                          : msg.isTool
                              ? Icons.build
                              : Icons.code,
                  color: roleColor,
                  size: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                msg.displayRole,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(msg.timestamp),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.blue, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            msg.content,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.4,
                fontFamily: 'monospace'),
          ),
          if (msg.toolName != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Tool: ${msg.toolName}',
                style: TextStyle(color: Colors.yellow.shade300, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyDetailPanel() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 48, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text('选择一个会话查看详情',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFF252525), shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline,
                size: 48, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          const Text('没有找到会话',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('创建新会话或导入历史记录',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateSessionDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('创建会话', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _importHistorySessions,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('导入历史', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
          color: Color(0xFF252525),
          border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D)))),
      child: Row(
        children: [
          IconButton(
              onPressed: () => setState(() => _selectedId = null),
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_getSessionTitle(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ============ 辅助方法 ============

  int _getProjectSessionCount(List<CodSession> sessions, String project) {
    if (project == 'All') return sessions.length;
    return sessions
        .where((s) => s.provider.toLowerCase() == project.toLowerCase())
        .length;
  }

  List<CodSession> _getFilteredSessions() {
    var sessions = CodSessionStore.all();

    if (_selectedProject != 'All') {
      sessions = sessions
          .where(
              (s) => s.provider.toLowerCase() == _selectedProject.toLowerCase())
          .toList();
    }

    final query = _searchCtrl.text.toLowerCase();
    if (query.isNotEmpty) {
      sessions = sessions
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              s.provider.toLowerCase().contains(query) ||
              s.cwd.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedDay != null) {
      sessions = sessions.where((s) {
        final date = _calendarTab == 'Created' ? s.createdAt : s.updatedAt;
        return date.year == _selectedDay!.year &&
            date.month == _selectedDay!.month &&
            date.day == _selectedDay!.day;
      }).toList();
    }

    switch (_sortBy) {
      case 'Recent':
        sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'Duration':
        sessions.sort((a, b) => b.updatedAt
            .difference(b.createdAt)
            .compareTo(a.updatedAt.difference(a.createdAt)));
        break;
      case 'Activity':
        sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'A-Z':
        sessions.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Size':
        sessions.sort((a, b) => b.logPath.length.compareTo(a.logPath.length));
        break;
    }

    return sessions;
  }

  Map<String, List<CodSession>> _groupSessionsByDate(
      List<CodSession> sessions) {
    final groups = <String, List<CodSession>>{};
    final now = DateTime.now();

    for (final session in sessions) {
      final date = session.updatedAt;
      String label;
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        label = 'Today';
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        label = 'Yesterday';
      } else {
        label = '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      }
      groups.putIfAbsent(label, () => []).add(session);
    }
    return groups;
  }

  String _calculateGroupDuration(List<CodSession> sessions) {
    int totalMinutes = 0;
    for (final session in sessions) {
      totalMinutes += session.updatedAt.difference(session.createdAt).inMinutes;
    }
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _calculateTotalDuration(List<CodSession> sessions) {
    int totalMinutes = 0;
    for (final session in sessions) {
      totalMinutes += session.updatedAt.difference(session.createdAt).inMinutes;
    }
    return '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
  }

  CodSession? _getSelectedSession() {
    if (_selectedId == null) return null;
    try {
      return CodSessionStore.byId(_selectedId!);
    } catch (e) {
      setState(() => _selectedId = null);
      return null;
    }
  }

  String _getSessionTitle() => _getSelectedSession()?.title ?? '会话详情';
  bool _isHistorySession(CodSession session) =>
      session.id.startsWith('codex_') ||
      session.id.startsWith('claude_') ||
      session.id.startsWith('gemini_');
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month - 1];
  String _getMonthYearString(DateTime date) =>
      '${_getMonthName(date.month)} ${date.year}';
  String _formatDuration(Duration d) => d.inHours > 0
      ? '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s'
      : d.inMinutes > 0
          ? '${d.inMinutes}m ${d.inSeconds % 60}s'
          : '${d.inSeconds}s';
  String _formatDateTimeShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  String _getStatusDisplayName(CodSessionStatus status) {
    switch (status) {
      case CodSessionStatus.pending:
        return '待运行';
      case CodSessionStatus.running:
        return '运行中';
      case CodSessionStatus.completed:
        return '已完成';
      case CodSessionStatus.failed:
        return '失败';
    }
  }

  Color _getProviderColor(String p) {
    switch (p.toLowerCase()) {
      case 'claude':
        return Colors.orange;
      case 'codex':
        return Colors.blue;
      case 'gemini':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(String p) {
    switch (p.toLowerCase()) {
      case 'claude':
        return Icons.smart_toy;
      case 'codex':
        return Icons.code;
      case 'gemini':
        return Icons.auto_awesome;
      default:
        return Icons.chat;
    }
  }

  Color _getStatusColor(CodSessionStatus s) {
    switch (s) {
      case CodSessionStatus.running:
        return Colors.green;
      case CodSessionStatus.completed:
        return Colors.blue;
      case CodSessionStatus.failed:
        return Colors.red;
      case CodSessionStatus.pending:
        return Colors.orange;
    }
  }

  String _getLogFileSize(CodSession session) {
    try {
      final file = File(session.logPath);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        }
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return 'N/A';
  }

  // ============ 操作方法 ============

  void _showNewProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('新建项目', style: TextStyle(color: Colors.white)),
        content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: '项目名称',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('项目创建功能即将推出')));
              },
              child: const Text('创建'))
        ],
      ),
    );
  }

  void _showCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('新建会话', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择AI提供商',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: _provider,
                builder: (context, selectedProvider, child) =>
                    Wrap(spacing: 8, children: [
                  _buildProviderChip(
                      'codex', 'Codex', selectedProvider, Icons.code),
                  _buildProviderChip(
                      'claude', 'Claude', selectedProvider, Icons.smart_toy),
                  _buildProviderChip(
                      'gemini', 'Gemini', selectedProvider, Icons.auto_awesome),
                ]),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: '标题',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(
                  controller: _cwdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      labelText: '工作目录',
                      labelStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none))),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createAndRun();
              },
              child: const Text('创建并运行'))
        ],
      ),
    );
  }

  Widget _buildProviderChip(
      String value, String label, String selectedProvider, IconData icon) {
    final isSelected = selectedProvider == value;
    final isAvailable = _cliAvailability[value]?.available ?? true;
    return InkWell(
      onTap: () => _provider.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: isSelected ? Colors.blue : const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade700)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            Icon(icon,
                size: 16, color: isAvailable ? Colors.white : Colors.grey),
            if (!isAvailable)
              Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle)))
          ]),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: isAvailable ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Future<void> _createAndRun() async {
    try {
      final provider = _provider.value;
      final title = _titleCtrl.text.trim().isEmpty
          ? '新建 ${provider.toUpperCase()} 会话'
          : _titleCtrl.text.trim();
      final cwd = _cwdCtrl.text.trim();
      final additionalArgs = _argsCtrl.text.trim().isEmpty
          ? <String>[]
          : _argsCtrl.text.split(RegExp(r'\s+'));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('正在启动会话...'), duration: Duration(seconds: 1)));
      late LaunchResult result;
      switch (provider.toLowerCase()) {
        case 'codex':
          result = await CodLauncher.launchCodex(
              title: title,
              workingDirectory: cwd.isEmpty ? null : cwd,
              useFullAuto: additionalArgs.contains('--full-auto'),
              bypassSandbox: additionalArgs
                  .contains('--dangerously-bypass-approvals-and-sandbox'),
              model: _extractModel(additionalArgs));
          break;
        case 'claude':
          result = await CodLauncher.launchClaude(
              title: title,
              workingDirectory: cwd.isEmpty ? null : cwd,
              model: _extractModel(additionalArgs),
              enableMcp: !additionalArgs.contains('--no-mcp'));
          break;
        case 'gemini':
          result = await CodLauncher.launchGemini(
              title: title,
              workingDirectory: cwd.isEmpty ? null : cwd,
              model: _extractModel(additionalArgs));
          break;
        default:
          throw Exception('不支持的提供商: $provider');
      }
      if (result.success && result.session != null) {
        setState(() => _selectedId = result.session!.id);
        await _reloadConversation(result.session!);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.message)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result.error ?? '启动失败')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建会话失败: $e')));
      }
    }
  }

  String? _extractModel(List<String> args) {
    for (int i = 0; i < args.length - 1; i++) {
      if (args[i] == '--model' || args[i] == '-m') return args[i + 1];
    }
    return null;
  }

  Future<void> _runSession(CodSession session) async {
    try {
      await CodCliRunner.run(session,
          onStdout: (_) => _reloadConversation(session));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('会话已启动')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('启动会话失败: $e')));
      }
    }
  }

  Future<void> _resumeSession(CodSession session) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('正在恢复会话...'), duration: Duration(seconds: 1)));

      // 切换到选中的会话并打开内置终端
      setState(() {
        _selectedId = session.id;
        _showTerminal = true; // 自动切换到终端视图
      });

      // 等待 UI 更新
      await Future.delayed(const Duration(milliseconds: 300));

      // 内置终端会自动启动 Resume 命令
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('会话已在内置终端中恢复，可以开始对话'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('恢复会话失败: $e')));
      }
    }
  }

  Future<void> _openTerminal(CodSession session) async {
    setState(() => _showTerminal = true);
  }

  /// 显示配置对话框
  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF252525),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Color(0xFF333333))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'CLI 配置管理',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              // 配置面板
              const Expanded(
                child: CodConfigPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importHistorySessions() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('正在扫描并导入历史会话...'), duration: Duration(seconds: 2)));
      final result = await CodHistoryImporter.importAllSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.summary),
            duration: const Duration(seconds: 3),
            action: result.hasErrors || result.hasMessages
                ? SnackBarAction(
                    label: '详情',
                    onPressed: () => _showImportResultDialog(result))
                : null));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入历史会话失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('导入结果', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('导入了 ${result.imported} 个会话',
                    style: const TextStyle(color: Colors.white)),
                if (result.hasMessages) ...[
                  const SizedBox(height: 16),
                  const Text('消息:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  ...result.messages.map((msg) => Text('• $msg',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)))
                ],
                if (result.hasErrors) ...[
                  const SizedBox(height: 16),
                  const Text('错误:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  ...result.errors.map((err) => Text('• $err',
                      style: const TextStyle(fontSize: 12, color: Colors.red)))
                ],
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'))
        ],
      ),
    );
  }

  Future<void> _selectSession(CodSession session) async {
    try {
      setState(() {
        _selectedId = session.id;
        _showTerminal = false;
      });
      await _reloadConversation(session);
      _logWatch?.cancel();
      final file = File(session.logPath);
      if (await file.exists()) {
        _logWatch = file
            .watch(events: FileSystemEvent.modify)
            .listen((_) => _reloadConversation(session), onError: (_) {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择会话失败: $e')));
      }
    }
  }

  Future<void> _reloadConversation(CodSession session) async {
    try {
      final messages = await CodConversationParser.loadConversation(session);
      if (mounted) setState(() => _conversation = messages);
    } catch (e) {
      if (mounted) setState(() => _conversation = []);
    }
  }

  Future<void> _openLogFile(CodSession session) async {
    try {
      final file = File(session.logPath);
      if (await file.exists()) {
        if (Platform.isWindows) {
          await Process.start('notepad.exe', [file.path]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [file.path]);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('日志文件不存在')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('打开日志文件失败: $e')));
      }
    }
  }

  Future<void> _openWorkingDirectory(CodSession session) async {
    try {
      final dir = session.cwd.isNotEmpty ? session.cwd : Directory.current.path;
      if (Platform.isWindows) {
        await Process.run('explorer', [dir]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir]);
      } else {
        await Process.run('xdg-open', [dir]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('打开目录失败: $e')));
      }
    }
  }

  /// 在外部终端中运行会话
  Future<void> _runInTerminal(CodSession session, String terminal) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('正在$terminal中启动会话...'),
            duration: const Duration(seconds: 1)),
      );

      final success =
          await CodCliRunner.runInTerminal(session, terminalApp: terminal);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已在$terminal中启动会话')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('无法在$terminal中启动会话')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('启动终端失败: $e')));
      }
    }
  }

  /// 复制恢复命令
  void _copyResumeCommand(CodSession session) {
    final cmd = CodCliRunner.buildResumeCommand(session);
    Clipboard.setData(ClipboardData(text: cmd));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('命令已复制: $cmd')),
    );
  }

  /// 确认删除会话
  Future<void> _confirmDeleteSession(CodSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '确定要删除这个会话吗？',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              '会话: ${session.title}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            Text(
              '提供商: ${_capitalizeFirst(session.provider)}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作不可撤销！日志文件也将被删除。',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSession(session);
    }
  }

  /// 删除会话
  Future<void> _deleteSession(CodSession session) async {
    try {
      // 取消日志监听
      if (_selectedId == session.id) {
        _logWatch?.cancel();
        _logWatch = null;
      }

      // 删除日志文件（如果存在）
      try {
        final logFile = File(session.logPath);
        if (await logFile.exists()) {
          await logFile.delete();
        }
      } catch (e) {
        // 忽略日志文件删除错误
      }

      // 从数据库中删除
      await CodSessionStore.remove(session.id);

      // 如果当前选中的是这个会话，清除选择
      if (_selectedId == session.id) {
        setState(() {
          _selectedId = null;
          _conversation = [];
          _showTerminal = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('会话 "${session.title}" 已删除'),
            action: SnackBarAction(
              label: '知道了',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除会话失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
