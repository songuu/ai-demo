import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/codecore/model/claude_skill.dart';
import 'package:server_box/codecore/service/claude_skill_service.dart';

/// Claude Code Skills 管理页面
/// 管理本地 ~/.claude/skills/ 目录下的 skills
class ClaudeSkillPage extends StatefulWidget {
  const ClaudeSkillPage({super.key});

  @override
  State<ClaudeSkillPage> createState() => _ClaudeSkillPageState();
}

class _ClaudeSkillPageState extends State<ClaudeSkillPage> {
  final _searchCtrl = TextEditingController();
  List<ClaudeSkill> _skills = [];
  bool _isLoading = true;
  String? _error;
  ClaudeSkill? _selectedSkill;
  String _filterType = 'all'; // all, user, system

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final skills = await ClaudeSkillService.getAllSkills();
      if (mounted) {
        setState(() {
          _skills = skills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ClaudeSkill> get _filteredSkills {
    var skills = _skills;

    // 按类型筛选
    if (_filterType == 'user') {
      skills = skills.where((s) => !s.isSystem).toList();
    } else if (_filterType == 'system') {
      skills = skills.where((s) => s.isSystem).toList();
    }

    // 搜索
    final query = _searchCtrl.text.toLowerCase();
    if (query.isNotEmpty) {
      skills = skills.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.content.toLowerCase().contains(query);
      }).toList();
    }

    // 排序：用户自定义在前，系统在后
    skills.sort((a, b) {
      if (a.isSystem != b.isSystem) {
        return a.isSystem ? 1 : -1;
      }
      return a.name.compareTo(b.name);
    });

    return skills;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: Row(
              children: [
                // 左侧 Skills 列表
                SizedBox(
                  width: 350,
                  child: _buildSkillList(),
                ),
                // 右侧详情面板
                Expanded(
                  child: _selectedSkill != null
                      ? _buildDetailPanel()
                      : _buildEmptyDetail(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 头部
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Claude Code Skills',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ClaudeSkillService.userSkillsPath,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          // 搜索框
          SizedBox(
            width: 220,
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索 Skills...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          // 刷新按钮
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.shade400, size: 20),
            tooltip: '刷新',
            onPressed: _loadSkills,
          ),
          // 打开目录按钮
          IconButton(
            icon: Icon(Icons.folder_open, color: Colors.grey.shade400, size: 20),
            tooltip: '打开 Skills 目录',
            onPressed: () => ClaudeSkillService.openUserSkillsDirectory(),
          ),
          const SizedBox(width: 8),
          // 新建按钮
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('新建 Skill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    final userCount = _skills.where((s) => !s.isSystem).length;
    final systemCount = _skills.where((s) => s.isSystem).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          _buildFilterChip('全部', 'all', _skills.length),
          const SizedBox(width: 8),
          _buildFilterChip('自定义', 'user', userCount),
          const SizedBox(width: 8),
          _buildFilterChip('系统', 'system', systemCount),
          const Spacer(),
          Text(
            '共 ${_filteredSkills.length} 个 Skills',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skills 列表
  Widget _buildSkillList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSkills,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final skills = _filteredSkills;

    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              '没有找到 Skills',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty ? '尝试其他搜索词' : '点击右上角新建',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: skills.length,
        itemBuilder: (context, index) => _buildSkillItem(skills[index]),
      ),
    );
  }

  Widget _buildSkillItem(ClaudeSkill skill) {
    final isSelected = _selectedSkill?.name == skill.name && 
                       _selectedSkill?.path == skill.path;

    return InkWell(
      onTap: () => setState(() => _selectedSkill = skill),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.15) : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: skill.isSystem
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                skill.isSystem ? Icons.lock_outline : Icons.edit_note,
                color: skill.isSystem ? Colors.blue : Colors.orange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '/${skill.name}',
                          style: TextStyle(
                            color: isSelected ? Colors.orange : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (skill.isSystem) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '系统',
                            style: TextStyle(color: Colors.blue, fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (skill.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 详情面板
  Widget _buildDetailPanel() {
    final skill = _selectedSkill!;

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // 标题栏
          _buildDetailHeader(skill),
          // 内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息
                  _buildInfoSection(skill),
                  const SizedBox(height: 20),
                  // Frontmatter 配置
                  _buildFrontmatterSection(skill),
                  const SizedBox(height: 20),
                  // Skill 内容
                  _buildContentSection(skill),
                  if (skill.supportingFiles.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSupportingFilesSection(skill),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(ClaudeSkill skill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: skill.isSystem
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              skill.isSystem ? Icons.lock_outline : Icons.edit_note,
              color: skill.isSystem ? Colors.blue : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.slashCommand,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.isSystem ? '系统 Skill（只读）' : '自定义 Skill',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          // 操作按钮
          if (!skill.isSystem) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: '编辑',
              onPressed: () => _showEditDialog(skill),
            ),
            IconButton(
              icon: const Icon(Icons.content_copy, color: Colors.grey),
              tooltip: '复制',
              onPressed: () => _duplicateSkill(skill),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除',
              onPressed: () => _confirmDelete(skill),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.folder_open_outlined, color: Colors.grey),
            tooltip: '打开目录',
            onPressed: () => ClaudeSkillService.openSkillDirectory(skill),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, color: Colors.grey),
            tooltip: '复制命令',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: skill.slashCommand));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已复制: ${skill.slashCommand}')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ClaudeSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('基本信息'),
        const SizedBox(height: 12),
        _buildInfoRow('名称', skill.name),
        _buildInfoRow('路径', skill.path),
        if (skill.description.isNotEmpty)
          _buildInfoRow('描述', skill.description),
        if (skill.modifiedAt != null)
          _buildInfoRow('修改时间', _formatDate(skill.modifiedAt!)),
      ],
    );
  }

  Widget _buildFrontmatterSection(ClaudeSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Frontmatter 配置'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildConfigChip(
              'context',
              skill.context ?? 'inline',
              Colors.purple,
            ),
            _buildConfigChip(
              'disable-model-invocation',
              skill.disableModelInvocation ? 'true' : 'false',
              skill.disableModelInvocation ? Colors.red : Colors.green,
            ),
            if (skill.allowedTools != null && skill.allowedTools!.isNotEmpty)
              _buildConfigChip(
                'allowed-tools',
                skill.allowedTools!.join(', '),
                Colors.blue,
              ),
            if (skill.disallowedTools != null && skill.disallowedTools!.isNotEmpty)
              _buildConfigChip(
                'disallowed-tools',
                skill.disallowedTools!.join(', '),
                Colors.orange,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentSection(ClaudeSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('SKILL.md 内容'),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: skill.rawContent));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制完整内容')),
                );
              },
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('复制'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: SelectableText(
            skill.rawContent,
            style: const TextStyle(
              color: Color(0xFFE6EDF3),
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportingFilesSection(ClaudeSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('支持文件'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skill.supportingFiles.map((file) {
            return InkWell(
              onTap: () => _showFileContent(skill, file),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(file),
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      file,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyDetail() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, color: Colors.grey.shade600, size: 48),
          const SizedBox(height: 16),
          Text(
            '选择一个 Skill 查看详情',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'md':
        return Icons.description;
      case 'sh':
      case 'bash':
        return Icons.terminal;
      case 'py':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ============ 操作方法 ============

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contentCtrl = TextEditingController(text: '''当用户请求时，执行以下操作：

1. 第一步
2. 第二步
3. 第三步

请确保遵循这些指南。''');
    String skillContext = 'inline';
    bool disableModelInvocation = false;

    final result = await showDialog<bool>(
      context: this.context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: const Text('新建 Skill', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogField('名称 *', nameCtrl, 
                    hintText: 'my-skill（只能包含字母、数字、连字符）'),
                  const SizedBox(height: 16),
                  _buildDialogField('描述', descCtrl, 
                    hintText: '简短描述这个 Skill 的用途'),
                  const SizedBox(height: 16),
                  _buildDialogField('内容 *', contentCtrl, 
                    hintText: 'Skill 指令内容...', maxLines: 8),
                  const SizedBox(height: 16),
                  Text('上下文设置', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['inline', 'fork', 'none'].map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: skillContext == c,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => skillContext = c);
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: skillContext == c ? Colors.white : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: disableModelInvocation,
                        onChanged: (v) => setDialogState(() => disableModelInvocation = v ?? false),
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '禁用模型自动调用（仅手动 /command 触发）',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final desc = descCtrl.text.trim();
      final skillContent = contentCtrl.text.trim();

      if (name.isEmpty || skillContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('名称和内容不能为空')),
        );
        return;
      }

      if (!ClaudeSkillService.isValidSkillName(name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('名称只能包含字母、数字、连字符和下划线，且以字母开头')),
        );
        return;
      }

      try {
        final skill = await ClaudeSkillService.createSkill(
          name: name,
          description: desc,
          content: skillContent,
          context: skillContext,
          disableModelInvocation: disableModelInvocation,
        );
        await _loadSkills();
        setState(() => _selectedSkill = skill);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已创建 Skill: /$name')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('创建失败: $e')),
          );
        }
      }
    }

    nameCtrl.dispose();
    descCtrl.dispose();
    contentCtrl.dispose();
  }

  Future<void> _showEditDialog(ClaudeSkill skill) async {
    final nameCtrl = TextEditingController(text: skill.name);
    final descCtrl = TextEditingController(text: skill.description);
    final contentCtrl = TextEditingController(text: skill.content);
    String skillContext = skill.context ?? 'inline';
    bool disableModelInvocation = skill.disableModelInvocation;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: const Text('编辑 Skill', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogField('名称', nameCtrl, enabled: false),
                  const SizedBox(height: 16),
                  _buildDialogField('描述', descCtrl, hintText: '简短描述'),
                  const SizedBox(height: 16),
                  _buildDialogField('内容 *', contentCtrl, maxLines: 10),
                  const SizedBox(height: 16),
                  Text('上下文设置', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['inline', 'fork', 'none'].map((c) {
                      return ChoiceChip(
                        label: Text(c),
                        selected: skillContext == c,
                        onSelected: (selected) {
                          if (selected) setDialogState(() => skillContext = c);
                        },
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: skillContext == c ? Colors.white : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: disableModelInvocation,
                        onChanged: (v) => setDialogState(() => disableModelInvocation = v ?? false),
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '禁用模型自动调用',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updatedSkill = skill.copyWith(
          description: descCtrl.text.trim(),
          content: contentCtrl.text.trim(),
          context: skillContext,
          disableModelInvocation: disableModelInvocation,
        );
        final saved = await ClaudeSkillService.updateSkill(updatedSkill);
        await _loadSkills();
        setState(() => _selectedSkill = saved);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skill 已更新')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    }

    nameCtrl.dispose();
    descCtrl.dispose();
    contentCtrl.dispose();
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller, {
    String? hintText,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey,
            fontSize: 13,
            fontFamily: maxLines > 1 ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _duplicateSkill(ClaudeSkill skill) async {
    final nameCtrl = TextEditingController(text: '${skill.name}-copy');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('复制 Skill', style: TextStyle(color: Colors.white)),
        content: _buildDialogField('新名称', nameCtrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('复制'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!ClaudeSkillService.isValidSkillName(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('名称格式不正确')),
        );
        return;
      }

      try {
        final newSkill = await ClaudeSkillService.duplicateSkill(skill, result);
        await _loadSkills();
        setState(() => _selectedSkill = newSkill);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已复制为: /$result')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('复制失败: $e')),
          );
        }
      }
    }

    nameCtrl.dispose();
  }

  Future<void> _confirmDelete(ClaudeSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除 "${skill.name}" 吗？\n\n这将删除整个 Skill 目录，包括所有支持文件。此操作不可撤销。',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ClaudeSkillService.deleteSkill(skill);
        await _loadSkills();
        setState(() => _selectedSkill = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除: ${skill.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _showFileContent(ClaudeSkill skill, String fileName) async {
    try {
      final content = await ClaudeSkillService.readSupportingFile(skill, fileName);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF252525),
            title: Text(fileName, style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 600,
              height: 400,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制文件内容')),
                  );
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取文件失败: $e')),
        );
      }
    }
  }
}
