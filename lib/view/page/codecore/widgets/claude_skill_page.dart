import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/codecore/model/claude_skill.dart';
import 'package:server_box/codecore/service/claude_skill_service.dart';
import 'package:server_box/view/page/codecore/widgets/remote_market_dialog.dart';

/// Claude Code Skills 管理页面
/// 管理本地 ~/.claude/skills/ 目录下的 skills
/// 参考: https://code.claude.com/docs/en/skills
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
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
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
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade600, size: 18),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            icon:
                Icon(Icons.folder_open, color: Colors.grey.shade400, size: 20),
            tooltip: '打开 Skills 目录',
            onPressed: () => ClaudeSkillService.openUserSkillsDirectory(),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _openRemoteMarketplace,
            icon: const Icon(Icons.cloud_download_outlined, size: 16),
            label: const Text('远端市场'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          // 新建按钮
          ElevatedButton.icon(
            onPressed: () => _showSkillEditor(null),
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
          color:
              isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
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
            Icon(Icons.auto_awesome_outlined,
                color: Colors.grey.shade600, size: 48),
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
          color: isSelected
              ? Colors.orange.withOpacity(0.15)
              : const Color(0xFF252525),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
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
                      if (skill.supportingFiles.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.attach_file,
                            size: 12, color: Colors.grey.shade500),
                        Text(
                          '${skill.supportingFiles.length}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  if (skill.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
              onPressed: () => _showSkillEditor(skill),
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
            if (skill.agent != null && skill.agent!.isNotEmpty)
              _buildConfigChip('agent', skill.agent!, Colors.cyan),
            if (skill.allowMultipleTurns != null)
              _buildConfigChip(
                'allow-multiple-turns',
                skill.allowMultipleTurns! ? 'true' : 'false',
                Colors.teal,
              ),
            if (skill.allowedTools != null && skill.allowedTools!.isNotEmpty)
              _buildConfigChip(
                'allowed-tools',
                skill.allowedTools!.join(', '),
                Colors.blue,
              ),
            if (skill.disallowedTools != null &&
                skill.disallowedTools!.isNotEmpty)
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
    final scripts = skill.scripts;
    final examples = skill.examples;
    final templates = skill.templates;
    final others = skill.supportingFiles
        .where((f) => f.type == SkillFileType.other)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('支持文件 (${skill.supportingFiles.length})'),
        const SizedBox(height: 12),

        // Scripts
        if (scripts.isNotEmpty) ...[
          _buildFileCategory('📜 脚本 (scripts/)', scripts, skill),
          const SizedBox(height: 12),
        ],

        // Examples
        if (examples.isNotEmpty) ...[
          _buildFileCategory('📝 示例 (examples/)', examples, skill),
          const SizedBox(height: 12),
        ],

        // Templates
        if (templates.isNotEmpty) ...[
          _buildFileCategory('📄 模板', templates, skill),
          const SizedBox(height: 12),
        ],

        // Others
        if (others.isNotEmpty) ...[
          _buildFileCategory('📎 其他文件', others, skill),
        ],
      ],
    );
  }

  Widget _buildFileCategory(
      String title, List<SkillFile> files, ClaudeSkill skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: files.map((file) {
            return InkWell(
              onTap: () => _showFileContent(skill, file),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(file.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(
                      file.relativePath,
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
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ============ 操作方法 ============

  /// 显示 Skill 编辑器（新建/编辑）
  Future<void> _showSkillEditor(ClaudeSkill? existingSkill) async {
    final result = await Navigator.of(context).push<ClaudeSkill>(
      MaterialPageRoute(
        builder: (context) => _SkillEditorPage(skill: existingSkill),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      await _loadSkills();
      setState(() => _selectedSkill = result);
    }
  }

  Future<void> _duplicateSkill(ClaudeSkill skill) async {
    final nameCtrl = TextEditingController(text: '${skill.name}-copy');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('复制 Skill', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '新名称',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
              ),
            ),
          ],
        ),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('名称格式不正确')),
          );
        }
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

  Future<void> _showFileContent(ClaudeSkill skill, SkillFile file) async {
    try {
      final content = await file.readContent();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF252525),
            title: Row(
              children: [
                Text(file.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.relativePath,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 700,
              height: 500,
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
                      height: 1.5,
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
                child: const Text('复制内容'),
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

  Future<void> _openRemoteMarketplace() async {
    final installedNames = _skills
        .where((skill) => !skill.isSystem)
        .map((skill) => skill.name)
        .toSet();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RemoteMarketDialog(
        installedSkillNames: installedNames,
        onSkillInstalled: (skillName) async {
          await _loadSkills();
          if (!mounted) return;
          ClaudeSkill? installed;
          for (final skill in _skills) {
            if (!skill.isSystem && skill.name == skillName) {
              installed = skill;
              break;
            }
          }
          if (installed != null) {
            setState(() => _selectedSkill = installed);
          }
        },
      ),
    );
  }
}

// ============ Skill 编辑器页面 ============

class _SkillEditorPage extends StatefulWidget {
  final ClaudeSkill? skill;

  const _SkillEditorPage({this.skill});

  @override
  State<_SkillEditorPage> createState() => _SkillEditorPageState();
}

class _SkillEditorPageState extends State<_SkillEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = false;

  // 基本信息
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  // Frontmatter 配置
  String _context = 'inline';
  bool _disableModelInvocation = false;
  final _allowedToolsCtrl = TextEditingController();
  final _disallowedToolsCtrl = TextEditingController();
  final _agentCtrl = TextEditingController();
  bool? _allowMultipleTurns;

  // 支持文件
  List<NewSkillFile> _newFiles = [];
  List<String> _deleteFiles = [];
  List<SkillFile> _existingFiles = [];

  bool get isEditing => widget.skill != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    if (widget.skill != null) {
      final skill = widget.skill!;
      _nameCtrl.text = skill.name;
      _descCtrl.text = skill.description;
      _contentCtrl.text = skill.content;
      _context = skill.context ?? 'inline';
      _disableModelInvocation = skill.disableModelInvocation;
      _allowedToolsCtrl.text = skill.allowedTools?.join(', ') ?? '';
      _disallowedToolsCtrl.text = skill.disallowedTools?.join(', ') ?? '';
      _agentCtrl.text = skill.agent ?? '';
      _allowMultipleTurns = skill.allowMultipleTurns;
      _existingFiles = List.from(skill.supportingFiles);
    } else {
      _contentCtrl.text = '''# Skill 指令

当用户请求时，执行以下操作：

1. **第一步**: 描述具体操作
2. **第二步**: 描述具体操作
3. **第三步**: 描述具体操作

## 注意事项

- 重要提示 1
- 重要提示 2

请确保遵循这些指南。''';
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _allowedToolsCtrl.dispose();
    _disallowedToolsCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252525),
        title: Text(
          isEditing ? '编辑 Skill: ${widget.skill!.name}' : '新建 Skill',
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEditing ? '保存' : '创建'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '基本信息'),
            Tab(text: 'Frontmatter 配置'),
            Tab(text: '支持文件'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildBasicInfoTab(),
          _buildFrontmatterTab(),
          _buildFilesTab(),
        ],
      ),
    );
  }

  /// 基本信息标签页
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 名称
          _buildField(
            '名称 *',
            _nameCtrl,
            hintText: 'my-skill（只能包含字母、数字、连字符和下划线）',
            enabled: !isEditing,
            helperText: '名称将成为 /slash-command，例如 /my-skill',
          ),
          const SizedBox(height: 24),

          // 描述
          _buildField(
            '描述',
            _descCtrl,
            hintText: '简短描述这个 Skill 的用途（帮助 Claude 决定何时自动调用）',
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // 内容
          _buildSectionHeader(
            'SKILL.md 内容 *',
            subtitle: 'Skill 的主要指令内容，使用 Markdown 格式',
          ),
          const SizedBox(height: 12),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: TextField(
              controller: _contentCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: '输入 Skill 指令内容...',
                hintStyle: TextStyle(color: Color(0xFF6E7681)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Frontmatter 配置标签页
  Widget _buildFrontmatterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context 设置
          _buildSectionHeader(
            'Context (上下文设置)',
            subtitle: '控制 Skill 如何在对话中运行',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildContextOption(
                'inline',
                'Inline (默认)',
                '内容直接添加到当前会话上下文',
                Icons.layers,
              ),
              _buildContextOption(
                'fork',
                'Fork',
                '在子代理中运行，隔离上下文',
                Icons.call_split,
              ),
              _buildContextOption(
                'none',
                'None',
                '不添加任何上下文',
                Icons.block,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 调用控制
          _buildSectionHeader(
            '调用控制',
            subtitle: '控制 Skill 如何被触发',
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'disable-model-invocation',
            '禁用模型自动调用',
            '启用后，Skill 只能通过 /command 手动触发',
            _disableModelInvocation,
            (v) => setState(() => _disableModelInvocation = v),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'allow-multiple-turns',
            '允许多轮对话',
            '启用后，Skill 可以在子代理中进行多轮对话',
            _allowMultipleTurns ?? false,
            (v) => setState(() => _allowMultipleTurns = v),
            triState: true,
            currentValue: _allowMultipleTurns,
          ),
          const SizedBox(height: 32),

          // Agent 设置
          _buildField(
            'Agent (代理类型)',
            _agentCtrl,
            hintText: '可选，如 explore、code 等',
            helperText: '用于 fork 上下文时指定代理类型',
          ),
          const SizedBox(height: 32),

          // 工具控制
          _buildSectionHeader(
            '工具访问控制',
            subtitle: '限制 Skill 可以使用的工具',
          ),
          const SizedBox(height: 12),
          _buildField(
            'allowed-tools (允许的工具)',
            _allowedToolsCtrl,
            hintText: '逗号分隔，如: read, write, execute',
            helperText: '留空表示允许所有工具',
          ),
          const SizedBox(height: 16),
          _buildField(
            'disallowed-tools (禁止的工具)',
            _disallowedToolsCtrl,
            hintText: '逗号分隔，如: delete, network',
            helperText: '列出禁止使用的工具',
          ),
        ],
      ),
    );
  }

  Widget _buildContextOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _context == value;
    return InkWell(
      onTap: () => setState(() => _context = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.1)
              : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : const Color(0xFF333333),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.orange : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.orange : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String key,
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged, {
    bool triState = false,
    bool? currentValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          if (triState)
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _allowMultipleTurns = null),
                  child: Text(
                    '未设置',
                    style: TextStyle(
                      color: currentValue == null ? Colors.orange : Colors.grey,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.orange,
                ),
              ],
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.orange,
            ),
        ],
      ),
    );
  }

  /// 支持文件标签页
  Widget _buildFilesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '支持文件说明',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '支持文件是 Skill 目录中除 SKILL.md 外的其他文件：\n'
                        '• scripts/ - Claude 可执行的脚本\n'
                        '• examples/ - 示例输出文件\n'
                        '• template.md - 模板文件\n\n'
                        '在 SKILL.md 中引用这些文件以告诉 Claude 如何使用它们。',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 添加文件按钮
          Row(
            children: [
              _buildAddFileButton(
                '添加脚本',
                Icons.terminal,
                Colors.green,
                () => _showAddFileDialog(SkillFileType.script),
              ),
              const SizedBox(width: 12),
              _buildAddFileButton(
                '添加示例',
                Icons.description,
                Colors.blue,
                () => _showAddFileDialog(SkillFileType.example),
              ),
              const SizedBox(width: 12),
              _buildAddFileButton(
                '添加模板',
                Icons.insert_drive_file,
                Colors.purple,
                () => _showAddFileDialog(SkillFileType.template),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 现有文件列表
          if (_existingFiles.isNotEmpty) ...[
            _buildSectionHeader('现有文件'),
            const SizedBox(height: 12),
            ..._existingFiles.map((file) => _buildExistingFileItem(file)),
            const SizedBox(height: 24),
          ],

          // 新文件列表
          if (_newFiles.isNotEmpty) ...[
            _buildSectionHeader('待添加文件'),
            const SizedBox(height: 12),
            ..._newFiles.asMap().entries.map(
                  (entry) => _buildNewFileItem(entry.key, entry.value),
                ),
          ],

          // 待删除文件
          if (_deleteFiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
              '待删除文件',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _deleteFiles
                  .map((path) => Chip(
                        label: Text(
                          path,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.undo, size: 16),
                        onDeleted: () {
                          setState(() {
                            _deleteFiles.remove(path);
                            // 恢复到现有文件列表
                            final existing = widget.skill?.supportingFiles
                                .where((f) => f.relativePath == path)
                                .firstOrNull;
                            if (existing != null) {
                              _existingFiles.add(existing);
                            }
                          });
                        },
                        backgroundColor: Colors.red.withOpacity(0.1),
                        side: const BorderSide(color: Colors.red),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddFileButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildExistingFileItem(SkillFile file) {
    final isDeleted = _deleteFiles.contains(file.relativePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDeleted ? Colors.red.withOpacity(0.1) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDeleted ? Colors.red : const Color(0xFF333333),
        ),
      ),
      child: Row(
        children: [
          Text(file.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.relativePath,
                  style: TextStyle(
                    color: isDeleted ? Colors.red : Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    decoration: isDeleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  file.typeDescription,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!isDeleted) ...[
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              color: Colors.grey,
              tooltip: '预览',
              onPressed: () => _previewFile(file),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red,
              tooltip: '删除',
              onPressed: () {
                setState(() {
                  _deleteFiles.add(file.relativePath);
                  _existingFiles.remove(file);
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewFileItem(int index, NewSkillFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add, size: 14, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.relativePath,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${file.content.length} 字符',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: Colors.blue,
            tooltip: '编辑',
            onPressed: () => _editNewFile(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            tooltip: '移除',
            onPressed: () {
              setState(() => _newFiles.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hintText,
    String? helperText,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF252525),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF252525)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ],
    );
  }

  // ============ 文件操作 ============

  Future<void> _showAddFileDialog(SkillFileType type) async {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    String prefix = '';
    String defaultExt = '.md';
    String placeholder = '';

    switch (type) {
      case SkillFileType.script:
        prefix = 'scripts/';
        defaultExt = '.sh';
        placeholder = 'validate.sh';
        contentCtrl.text =
            ClaudeSkillService.getDefaultScriptTemplate('script.sh');
        break;
      case SkillFileType.example:
        prefix = 'examples/';
        placeholder = 'sample.md';
        contentCtrl.text =
            ClaudeSkillService.getDefaultExampleTemplate('sample.md');
        break;
      case SkillFileType.template:
        placeholder = 'template.md';
        contentCtrl.text =
            ClaudeSkillService.getDefaultTemplateContent('template.md');
        break;
      case SkillFileType.other:
        placeholder = 'file.txt';
        break;
    }

    final result = await showDialog<NewSkillFile>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF252525),
          title: Text(
            '添加${type == SkillFileType.script ? '脚本' : type == SkillFileType.example ? '示例' : '模板'}文件',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件名
                  Row(
                    children: [
                      if (prefix.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Text(
                            prefix,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: placeholder,
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: prefix.isEmpty
                                    ? const Radius.circular(8)
                                    : Radius.zero,
                                right: const Radius.circular(8),
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            // 更新模板内容中的文件名
                            if (type == SkillFileType.script) {
                              setDialogState(() {
                                contentCtrl.text =
                                    ClaudeSkillService.getDefaultScriptTemplate(
                                        value.isEmpty
                                            ? 'script$defaultExt'
                                            : value);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 脚本类型选择（仅脚本）
                  if (type == SkillFileType.script) ...[
                    Text(
                      '脚本类型',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildScriptTypeChip('.sh', 'Bash', nameCtrl,
                            contentCtrl, setDialogState),
                        _buildScriptTypeChip('.py', 'Python', nameCtrl,
                            contentCtrl, setDialogState),
                        _buildScriptTypeChip('.js', 'JavaScript', nameCtrl,
                            contentCtrl, setDialogState),
                        _buildScriptTypeChip('.ps1', 'PowerShell', nameCtrl,
                            contentCtrl, setDialogState),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 内容
                  Text(
                    '文件内容',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: TextField(
                      controller: contentCtrl,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: Color(0xFFE6EDF3),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入文件名')),
                  );
                  return;
                }

                Navigator.pop(
                  ctx,
                  NewSkillFile(
                    relativePath: '$prefix$name',
                    content: contentCtrl.text,
                    type: type,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _newFiles.add(result));
    }

    nameCtrl.dispose();
    contentCtrl.dispose();
  }

  Widget _buildScriptTypeChip(
    String ext,
    String label,
    TextEditingController nameCtrl,
    TextEditingController contentCtrl,
    StateSetter setDialogState,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final baseName = nameCtrl.text.split('.').first;
        final newName = baseName.isEmpty ? 'script$ext' : '$baseName$ext';
        setDialogState(() {
          nameCtrl.text = newName;
          contentCtrl.text =
              ClaudeSkillService.getDefaultScriptTemplate(newName);
        });
      },
    );
  }

  Future<void> _editNewFile(int index) async {
    final file = _newFiles[index];
    final contentCtrl = TextEditingController(text: file.content);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: Text(
          '编辑 ${file.relativePath}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: TextField(
              controller: contentCtrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Color(0xFFE6EDF3),
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, contentCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _newFiles[index] = NewSkillFile(
          relativePath: file.relativePath,
          content: result,
          type: file.type,
        );
      });
    }

    contentCtrl.dispose();
  }

  Future<void> _previewFile(SkillFile file) async {
    try {
      final content = await file.readContent();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF252525),
            title: Row(
              children: [
                Text(file.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.relativePath,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 400,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      color: Color(0xFFE6EDF3),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
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

  // ============ 保存 ============

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    // 验证
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 Skill 名称')),
      );
      _tabCtrl.animateTo(0);
      return;
    }

    if (!ClaudeSkillService.isValidSkillName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名称只能包含字母、数字、连字符和下划线，且以字母开头')),
      );
      _tabCtrl.animateTo(0);
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 Skill 内容')),
      );
      _tabCtrl.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      ClaudeSkill result;

      // 解析工具列表
      List<String>? allowedTools;
      List<String>? disallowedTools;

      final allowedText = _allowedToolsCtrl.text.trim();
      if (allowedText.isNotEmpty) {
        allowedTools = allowedText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final disallowedText = _disallowedToolsCtrl.text.trim();
      if (disallowedText.isNotEmpty) {
        disallowedTools = disallowedText
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      if (isEditing) {
        // 更新现有 skill
        final updatedSkill = widget.skill!.copyWith(
          description: _descCtrl.text.trim(),
          content: content,
          context: _context,
          disableModelInvocation: _disableModelInvocation,
          allowedTools: allowedTools,
          disallowedTools: disallowedTools,
          agent: _agentCtrl.text.trim().isEmpty ? null : _agentCtrl.text.trim(),
          allowMultipleTurns: _allowMultipleTurns,
        );

        result = await ClaudeSkillService.updateSkill(
          updatedSkill,
          newFiles: _newFiles.isEmpty ? null : _newFiles,
          deleteFiles: _deleteFiles.isEmpty ? null : _deleteFiles,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skill 已更新')),
          );
        }
      } else {
        // 创建新 skill
        result = await ClaudeSkillService.createSkill(
          name: name,
          description: _descCtrl.text.trim(),
          content: content,
          context: _context,
          disableModelInvocation: _disableModelInvocation,
          allowedTools: allowedTools,
          disallowedTools: disallowedTools,
          agent: _agentCtrl.text.trim().isEmpty ? null : _agentCtrl.text.trim(),
          allowMultipleTurns: _allowMultipleTurns,
          supportingFiles: _newFiles.isEmpty ? null : _newFiles,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已创建 Skill: /$name')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
