import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/codecore/model/cod_skill.dart';
import 'package:server_box/codecore/store/cod_skill_store.dart';
import 'package:server_box/codecore/service/cod_skill_sync.dart';

/// Skill 管理页面
class CodSkillPage extends StatefulWidget {
  const CodSkillPage({super.key});

  @override
  State<CodSkillPage> createState() => _CodSkillPageState();
}

class _CodSkillPageState extends State<CodSkillPage> {
  final _searchCtrl = TextEditingController();
  CodSkillType? _selectedType;
  CodSkillProvider _selectedProvider = CodSkillProvider.all;
  String _sortBy = 'recent';
  bool _showFavoritesOnly = false;
  String? _selectedTag;
  bool _isSyncing = false;
  final Set<String> _selectedIds = {};
  bool _isMultiSelectMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                // 左侧标签面板
                _buildTagPanel(),
                // 右侧 Skill 列表
                Expanded(child: _buildSkillList()),
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
                colors: [Colors.purple.shade400, Colors.blue.shade400],
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
                'Skill 管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '管理 Claude, Codex, Gemini 的技能和提示词',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // 搜索框
          SizedBox(
            width: 250,
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
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          // 同步按钮
          _buildIconButton(
            icon: _isSyncing ? Icons.sync : Icons.cloud_sync,
            tooltip: '同步 Skills',
            onPressed: _isSyncing ? null : _syncSkills,
            isLoading: _isSyncing,
          ),
          const SizedBox(width: 8),
          // 导入按钮
          _buildIconButton(
            icon: Icons.upload_file,
            tooltip: '导入 Skills',
            onPressed: _importSkills,
          ),
          const SizedBox(width: 8),
          // 导出按钮
          _buildIconButton(
            icon: Icons.download,
            tooltip: '导出 Skills',
            onPressed: _exportSkills,
          ),
          const SizedBox(width: 8),
          // 新建按钮
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(null),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('新建 Skill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            )
          : Icon(icon, color: Colors.grey.shade400, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade700),
        ),
      ),
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        children: [
          // 类型筛选
          _buildFilterDropdown<CodSkillType?>(
            value: _selectedType,
            items: [
              const DropdownMenuItem(value: null, child: Text('全部类型')),
              ...CodSkillType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_getTypeName(t)),
                  )),
            ],
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(width: 12),
          // 提供商筛选
          _buildFilterDropdown<CodSkillProvider>(
            value: _selectedProvider,
            items: CodSkillProvider.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(_getProviderName(p)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedProvider = v!),
          ),
          const SizedBox(width: 12),
          // 排序
          _buildFilterDropdown<String>(
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'recent', child: Text('最近更新')),
              DropdownMenuItem(value: 'name', child: Text('名称')),
              DropdownMenuItem(value: 'useCount', child: Text('使用次数')),
              DropdownMenuItem(value: 'created', child: Text('创建时间')),
            ],
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
          const SizedBox(width: 12),
          // 收藏筛选
          FilterChip(
            label: const Text('仅收藏'),
            selected: _showFavoritesOnly,
            onSelected: (v) => setState(() => _showFavoritesOnly = v),
            backgroundColor: const Color(0xFF2A2A2A),
            selectedColor: Colors.orange.withOpacity(0.3),
            checkmarkColor: Colors.orange,
            labelStyle: TextStyle(
              color: _showFavoritesOnly ? Colors.orange : Colors.grey.shade400,
              fontSize: 12,
            ),
            side: BorderSide(
              color: _showFavoritesOnly ? Colors.orange : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          // 批量操作
          if (_isMultiSelectMode) ...[
            Text(
              '已选择 ${_selectedIds.length} 项',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('删除'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _isMultiSelectMode = false;
                _selectedIds.clear();
              }),
              child: const Text('取消'),
            ),
          ] else
            TextButton.icon(
              onPressed: () => setState(() => _isMultiSelectMode = true),
              icon: const Icon(Icons.checklist, size: 16),
              label: const Text('批量操作'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
          dropdownColor: const Color(0xFF2A2A2A),
          iconEnabledColor: Colors.grey.shade500,
        ),
      ),
    );
  }

  /// 标签面板
  Widget _buildTagPanel() {
    final tags = CodSkillStore.getAllTags();
    final stats = CodSkillStore.getStats();

    return Container(
      width: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(right: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计信息
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总计',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatItem('${stats['total']}', 'Skills'),
                    const SizedBox(width: 12),
                    _buildStatItem('${stats['favorites']}', '收藏'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF333333), height: 1),
          // 标签列表
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  '标签',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedTag != null)
                  InkWell(
                    onTap: () => setState(() => _selectedTag = null),
                    child: Text(
                      '清除',
                      style: TextStyle(color: Colors.blue.shade400, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...tags.map((tag) => _buildTagItem(tag)),
              ],
            ),
          ),
          // 底部操作
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _resetToPresets,
                    icon: const Icon(Icons.restore, size: 14),
                    label: const Text('重置预设', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTagItem(String tag) {
    final isSelected = _selectedTag == tag;
    final count = CodSkillStore.byTag(tag).length;

    return InkWell(
      onTap: () => setState(() => _selectedTag = isSelected ? null : tag),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.5)) : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.tag,
              size: 12,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tag,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Skill 列表
  Widget _buildSkillList() {
    return ValueListenableBuilder<Box<CodSkill>>(
      valueListenable: CodSkillStore.listenable() ?? ValueNotifier(Hive.box<CodSkill>('temp')),
      builder: (context, box, _) {
        final skills = _getFilteredSkills();

        if (skills.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: skills.length,
          itemBuilder: (context, index) => _buildSkillCard(skills[index]),
        );
      },
    );
  }

  List<CodSkill> _getFilteredSkills() {
    var skills = CodSkillStore.all();

    // 搜索
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      skills = CodSkillStore.search(query);
    }

    // 类型筛选
    if (_selectedType != null) {
      skills = skills.where((s) => s.type == _selectedType).toList();
    }

    // 提供商筛选
    if (_selectedProvider != CodSkillProvider.all) {
      skills = skills
          .where((s) => s.provider == _selectedProvider || s.provider == CodSkillProvider.all)
          .toList();
    }

    // 标签筛选
    if (_selectedTag != null) {
      skills = skills.where((s) => s.tags.contains(_selectedTag)).toList();
    }

    // 收藏筛选
    if (_showFavoritesOnly) {
      skills = skills.where((s) => s.isFavorite).toList();
    }

    // 排序
    switch (_sortBy) {
      case 'recent':
        skills.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'name':
        skills.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'useCount':
        skills.sort((a, b) => b.useCount.compareTo(a.useCount));
        break;
      case 'created':
        skills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return skills;
  }

  Widget _buildSkillCard(CodSkill skill) {
    final isSelected = _selectedIds.contains(skill.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.blue : const Color(0xFF333333),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isMultiSelectMode
            ? () => setState(() {
                  if (isSelected) {
                    _selectedIds.remove(skill.id);
                  } else {
                    _selectedIds.add(skill.id);
                  }
                })
            : () => _showEditDialog(skill),
        onLongPress: () {
          if (!_isMultiSelectMode) {
            setState(() {
              _isMultiSelectMode = true;
              _selectedIds.add(skill.id);
            });
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部行
              Row(
                children: [
                  if (_isMultiSelectMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selectedIds.add(skill.id);
                        } else {
                          _selectedIds.remove(skill.id);
                        }
                      }),
                      activeColor: Colors.blue,
                    ),
                  // 类型图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(skill.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(skill.type),
                      color: _getTypeColor(skill.type),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 标题和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                skill.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (skill.isFavorite) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star, color: Colors.orange, size: 14),
                            ],
                            if (!skill.isEnabled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '已禁用',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skill.description.isEmpty ? '暂无描述' : skill.description,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  if (!_isMultiSelectMode)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade500, size: 18),
                      onSelected: (action) => _handleSkillAction(skill, action),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              const Text('编辑'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              const Text('复制内容'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.content_copy, size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              const Text('复制 Skill'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                skill.isFavorite ? Icons.star : Icons.star_outline,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(skill.isFavorite ? '取消收藏' : '添加收藏'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                skill.isEnabled ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(skill.isEnabled ? '禁用' : '启用'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 内容预览
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  skill.content,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              // 底部信息
              Row(
                children: [
                  // 类型标签
                  _buildChip(_getTypeName(skill.type), _getTypeColor(skill.type)),
                  const SizedBox(width: 6),
                  // 提供商标签
                  _buildChip(_getProviderName(skill.provider), _getProviderColor(skill.provider)),
                  const SizedBox(width: 6),
                  // 标签
                  ...skill.tags.take(2).map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildChip(tag, Colors.grey),
                      )),
                  if (skill.tags.length > 2)
                    Text(
                      '+${skill.tags.length - 2}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                  const Spacer(),
                  // 使用次数
                  Icon(Icons.bolt, color: Colors.grey.shade600, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '${skill.useCount}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  // 更新时间
                  Icon(Icons.schedule, color: Colors.grey.shade600, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    _formatDate(skill.updatedAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '没有找到 Skills',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建你的第一个 Skill 或导入预设',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showEditDialog(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新建 Skill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetToPresets,
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('加载预设'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade300,
                  side: BorderSide(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ 操作方法 ============

  void _handleSkillAction(CodSkill skill, String action) async {
    switch (action) {
      case 'edit':
        _showEditDialog(skill);
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: skill.content));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('内容已复制到剪贴板')),
          );
        }
        await CodSkillStore.markUsed(skill.id);
        break;
      case 'duplicate':
        final newSkill = skill.copyWith(
          id: CodSkill.generateId(),
          name: '${skill.name} (副本)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncId: null,
          syncStatus: 0,
        );
        await CodSkillStore.add(newSkill);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skill 已复制')),
          );
        }
        break;
      case 'favorite':
        await CodSkillStore.toggleFavorite(skill.id);
        break;
      case 'toggle':
        await CodSkillStore.toggleEnabled(skill.id);
        break;
      case 'delete':
        _confirmDelete(skill);
        break;
    }
  }

  Future<void> _confirmDelete(CodSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除 "${skill.name}" 吗？此操作不可撤销。',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CodSkillStore.remove(skill.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 "${skill.name}"')),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除选中的 ${_selectedIds.length} 个 Skills 吗？此操作不可撤销。',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CodSkillStore.removeAll(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isMultiSelectMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除选中的 Skills')),
        );
      }
    }
  }

  void _showEditDialog(CodSkill? skill) {
    showDialog(
      context: context,
      builder: (context) => CodSkillEditDialog(skill: skill),
    );
  }

  Future<void> _syncSkills() async {
    setState(() => _isSyncing = true);
    try {
      final result = await CodSkillSyncService.sync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _importSkills() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final imported = await CodSkillStore.importFromJson(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $imported 个 Skills')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _exportSkills() async {
    try {
      final data = CodSkillStore.exportToJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出 Skills',
        fileName: 'cod_skills_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonStr);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skills 已导出')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _resetToPresets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('重置为预设', style: TextStyle(color: Colors.white)),
        content: Text(
          '这将清除所有现有 Skills 并加载预设。确定继续吗？',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CodSkillStore.resetToPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已重置为预设 Skills')),
        );
      }
    }
  }

  // ============ 辅助方法 ============

  String _getTypeName(CodSkillType type) {
    switch (type) {
      case CodSkillType.systemPrompt:
        return '系统提示词';
      case CodSkillType.codeTemplate:
        return '代码模板';
      case CodSkillType.workflow:
        return '工作流';
      case CodSkillType.customCommand:
        return '自定义命令';
      case CodSkillType.promptSnippet:
        return '提示词片段';
    }
  }

  IconData _getTypeIcon(CodSkillType type) {
    switch (type) {
      case CodSkillType.systemPrompt:
        return Icons.psychology;
      case CodSkillType.codeTemplate:
        return Icons.code;
      case CodSkillType.workflow:
        return Icons.account_tree;
      case CodSkillType.customCommand:
        return Icons.terminal;
      case CodSkillType.promptSnippet:
        return Icons.short_text;
    }
  }

  Color _getTypeColor(CodSkillType type) {
    switch (type) {
      case CodSkillType.systemPrompt:
        return Colors.purple;
      case CodSkillType.codeTemplate:
        return Colors.blue;
      case CodSkillType.workflow:
        return Colors.green;
      case CodSkillType.customCommand:
        return Colors.orange;
      case CodSkillType.promptSnippet:
        return Colors.cyan;
    }
  }

  String _getProviderName(CodSkillProvider provider) {
    switch (provider) {
      case CodSkillProvider.all:
        return '全部';
      case CodSkillProvider.claude:
        return 'Claude';
      case CodSkillProvider.codex:
        return 'Codex';
      case CodSkillProvider.gemini:
        return 'Gemini';
    }
  }

  Color _getProviderColor(CodSkillProvider provider) {
    switch (provider) {
      case CodSkillProvider.all:
        return Colors.grey;
      case CodSkillProvider.claude:
        return Colors.orange;
      case CodSkillProvider.codex:
        return Colors.blue;
      case CodSkillProvider.gemini:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

/// Skill 编辑对话框
class CodSkillEditDialog extends StatefulWidget {
  final CodSkill? skill;

  const CodSkillEditDialog({super.key, this.skill});

  @override
  State<CodSkillEditDialog> createState() => _CodSkillEditDialogState();
}

class _CodSkillEditDialogState extends State<CodSkillEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _shortcutCtrl;

  late CodSkillType _type;
  late CodSkillProvider _provider;
  late bool _isFavorite;
  late bool _isEnabled;

  bool get _isNew => widget.skill == null;

  @override
  void initState() {
    super.initState();
    final skill = widget.skill;
    _nameCtrl = TextEditingController(text: skill?.name ?? '');
    _descCtrl = TextEditingController(text: skill?.description ?? '');
    _contentCtrl = TextEditingController(text: skill?.content ?? '');
    _tagsCtrl = TextEditingController(text: skill?.tags.join(', ') ?? '');
    _shortcutCtrl = TextEditingController(text: skill?.shortcut ?? '');
    _type = skill?.type ?? CodSkillType.systemPrompt;
    _provider = skill?.provider ?? CodSkillProvider.all;
    _isFavorite = skill?.isFavorite ?? false;
    _isEnabled = skill?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    _shortcutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(
                    _isNew ? Icons.add_circle : Icons.edit,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isNew ? '新建 Skill' : '编辑 Skill',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称
                    _buildField('名称 *', _nameCtrl, hintText: '输入 Skill 名称'),
                    const SizedBox(height: 16),
                    // 描述
                    _buildField('描述', _descCtrl, hintText: '简短描述这个 Skill 的用途'),
                    const SizedBox(height: 16),
                    // 内容
                    _buildField(
                      '内容 *',
                      _contentCtrl,
                      hintText: '输入提示词或代码模板...',
                      maxLines: 10,
                      isCode: true,
                    ),
                    const SizedBox(height: 16),
                    // 类型和提供商
                    Row(
                      children: [
                        Expanded(child: _buildTypeDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildProviderDropdown()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 标签
                    _buildField('标签', _tagsCtrl, hintText: '用逗号分隔，如：代码审查, 重构, 优化'),
                    const SizedBox(height: 16),
                    // 快捷键
                    _buildField('快捷键', _shortcutCtrl, hintText: '可选，如：Ctrl+Shift+R'),
                    const SizedBox(height: 16),
                    // 开关选项
                    Row(
                      children: [
                        _buildSwitch('收藏', _isFavorite, (v) => setState(() => _isFavorite = v)),
                        const SizedBox(width: 24),
                        _buildSwitch('启用', _isEnabled, (v) => setState(() => _isEnabled = v)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF333333))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isNew ? '创建' : '保存'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hintText,
    int maxLines = 1,
    bool isCode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: isCode ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF252525),
            contentPadding: const EdgeInsets.all(12),
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
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类型',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CodSkillType>(
              value: _type,
              isExpanded: true,
              items: CodSkillType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_getTypeName(t)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              dropdownColor: const Color(0xFF252525),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '适用提供商',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CodSkillProvider>(
              value: _provider,
              isExpanded: true,
              items: CodSkillProvider.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_getProviderName(p)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _provider = v!),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              dropdownColor: const Color(0xFF252525),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    );
  }

  String _getTypeName(CodSkillType type) {
    switch (type) {
      case CodSkillType.systemPrompt:
        return '系统提示词';
      case CodSkillType.codeTemplate:
        return '代码模板';
      case CodSkillType.workflow:
        return '工作流';
      case CodSkillType.customCommand:
        return '自定义命令';
      case CodSkillType.promptSnippet:
        return '提示词片段';
    }
  }

  String _getProviderName(CodSkillProvider provider) {
    switch (provider) {
      case CodSkillProvider.all:
        return '全部';
      case CodSkillProvider.claude:
        return 'Claude';
      case CodSkillProvider.codex:
        return 'Codex';
      case CodSkillProvider.gemini:
        return 'Gemini';
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入名称')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final skill = (widget.skill ?? CodSkill(id: CodSkill.generateId(), name: '', content: ''))
        .copyWith(
      name: name,
      description: _descCtrl.text.trim(),
      content: content,
      type: _type,
      provider: _provider,
      tags: tags,
      isFavorite: _isFavorite,
      isEnabled: _isEnabled,
      shortcut: _shortcutCtrl.text.trim().isEmpty ? null : _shortcutCtrl.text.trim(),
    );

    if (_isNew) {
      await CodSkillStore.add(skill);
    } else {
      await CodSkillStore.update(skill);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isNew ? 'Skill 已创建' : 'Skill 已更新')),
      );
    }
  }
}
