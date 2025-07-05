import 'package:flutter/material.dart';
import '../services/note_database_service.dart';
import '../models/note_model.dart';
import 'note_edit_page.dart';
import '../widgets/drawer.dart';
import '../widgets/common_bottom_bar.dart';
import '../widgets/custom_toast.dart';

enum NoteSortOption { createdTime, modifiedTime, title }

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  NoteListPageState createState() => NoteListPageState();
}

class NoteListPageState extends State<NoteListPage> {
  late Future<List<Note>> _notesFuture;
  final bool _isProcessingOCR = false;

  // 搜索和排序相关变量
  String _searchQuery = '';
  NoteSortOption _currentSort = NoteSortOption.modifiedTime;
  bool _isAscending = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // 标签筛选相关变量
  String _selectedTag = '';
  List<String> _allTags = [];

  @override
  void initState() {
    super.initState();
    _notesFuture = NoteDatabaseService.instance.readAllNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = NoteDatabaseService.instance.readAllNotes();
    });
    _updateTagsList();
  }
  
  // 更新标签列表
  void _updateTagsList() async {
    final notes = await NoteDatabaseService.instance.readAllNotes();
    final tags = <String>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        if (tag.isNotEmpty) {
          tags.add(tag);
        }
      }
    }
    setState(() {
      _allTags = tags.toList()..sort();
    });
  }

  // 过滤和排序笔记
  List<Note> _filterAndSortNotes(List<Note> notes) {
    // 搜索过滤
    var filtered = notes;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
    
    // 标签筛选
    if (_selectedTag.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.tags.contains(_selectedTag);
      }).toList();
    }

    // 排序
    filtered.sort((a, b) {
      int comparison;
      switch (_currentSort) {
        case NoteSortOption.createdTime:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case NoteSortOption.modifiedTime:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case NoteSortOption.title:
          comparison = a.title.compareTo(b.title);
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // 显示排序选项
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '排序方式',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<NoteSortOption>(
                    title: const Text('修改时间'),
                    value: NoteSortOption.modifiedTime,
                    groupValue: _currentSort,
                    onChanged: (value) {
                      setState(() => _currentSort = value!);
                      this.setState(() => _currentSort = value!);
                    },
                  ),
                  RadioListTile<NoteSortOption>(
                    title: const Text('创建时间'),
                    value: NoteSortOption.createdTime,
                    groupValue: _currentSort,
                    onChanged: (value) {
                      setState(() => _currentSort = value!);
                      this.setState(() => _currentSort = value!);
                    },
                  ),
                  RadioListTile<NoteSortOption>(
                    title: const Text('标题'),
                    value: NoteSortOption.title,
                    groupValue: _currentSort,
                    onChanged: (value) {
                      setState(() => _currentSort = value!);
                      this.setState(() => _currentSort = value!);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('升序排列'),
                    subtitle: Text(_isAscending ? '从旧到新 / A-Z' : '从新到旧 / Z-A'),
                    value: _isAscending,
                    onChanged: (value) {
                      setState(() => _isAscending = value);
                      this.setState(() => _isAscending = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }




  // 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(Note note) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除笔记'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('确定要删除笔记 "${note.title}" 吗？'),
                const SizedBox(height: 8),
                const Text(
                  '此操作无法撤销。',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteNote(note);
              },
            ),
          ],
        );
      },
    );
  }

  // 删除笔记
  Future<void> _deleteNote(Note note) async {
    try {
      await NoteDatabaseService.instance.deleteNote(note.id!);
      _refreshNotes();
      if (!mounted) return;
      CustomToast.show(context, message: '笔记已删除', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        message: '删除失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  // 标签筛选弹窗
  void _showTagFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('按标签筛选'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('显示全部'),
                leading: Radio<String>(
                  value: '',
                  groupValue: _selectedTag,
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const Divider(),
              if (_allTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('暂无标签'),
                )
              else
                ...(_allTags.map((tag) => ListTile(
                  title: Text(tag),
                  leading: Radio<String>(
                    value: tag,
                    groupValue: _selectedTag,
                    onChanged: (value) {
                      setState(() {
                        _selectedTag = value!;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
  
  // 分类/标签弹窗
  void _showTagDialog() async {
    final notes = await _notesFuture;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final tagController = TextEditingController();
        return AlertDialog(
          title: const Text('为笔记打标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('输入新标签或选择已有标签：'),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(hintText: '输入标签'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final note in notes)
                    for (final tag in note.tags)
                      if (tag.isNotEmpty)
                        ActionChip(
                          label: Text(tag),
                          onPressed: () {
                            tagController.text = tag;
                          },
                        ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final tag = tagController.text.trim();
                if (tag.isEmpty) return;
                final navigator = Navigator.of(context);
                // 给所有选中的笔记打标签（这里只做演示，实际可扩展为多选/单选）
                for (final note in notes) {
                  if (!note.tags.contains(tag)) {
                    final updated = note.copyWith(tags: [...note.tags, tag]);
                    await NoteDatabaseService.instance.updateNote(updated);
                  }
                }
                if (!mounted) return;
                navigator.pop();
                _refreshNotes();
                if (mounted) {
                  CustomToast.show(
                    this.context,
                    message: '标签已添加',
                    type: ToastType.success,
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 单条笔记标签编辑弹窗
  void _showNoteTagDialog(Note note) async {
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('为该笔记打标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('输入新标签：'),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(hintText: '输入标签'),
              ),
              const SizedBox(height: 12),
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in note.tags)
                      Chip(
                        label: Text(tag),
                        onDeleted: () async {
                          final navigator = Navigator.of(context);
                          final updated = note.copyWith(
                            tags: List.of(note.tags)..remove(tag),
                          );
                          await NoteDatabaseService.instance.updateNote(
                            updated,
                          );
                          if (!mounted) return;
                          navigator.pop();
                          _refreshNotes();
                          if (mounted) {
                            CustomToast.show(
                              this.context,
                              message: '标签已移除',
                              type: ToastType.success,
                            );
                          }
                        },
                      ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final tag = tagController.text.trim();
                if (tag.isEmpty) return;
                final navigator = Navigator.of(context);
                if (!note.tags.contains(tag)) {
                  final updated = note.copyWith(tags: [...note.tags, tag]);
                  await NoteDatabaseService.instance.updateNote(updated);
                }
                if (!mounted) return;
                navigator.pop();
                _refreshNotes();
                if (mounted) {
                  CustomToast.show(
                    this.context,
                    message: '标签已添加',
                    type: ToastType.success,
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '搜索笔记...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    )
                  : const Text('AuraLab笔记页'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                  onPressed: _refreshNotes,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '搜索',
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: '标签筛选',
                  onPressed: _showTagFilterDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.label),
                  tooltip: '添加标签',
                  onPressed: _showTagDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                ),
              ],
            )
          : null,
      drawer: widget.showAppBar ? const TabsDrawer() : null,
      body: Column(
        children: [
          // 搜索结果提示
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '搜索 "$_searchQuery" 的结果',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
          // 标签筛选状态提示
          if (_selectedTag.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '筛选标签: $_selectedTag',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTag = '';
                      });
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
          // 笔记列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshNotes();
                // 等待一小段时间确保刷新完成
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: FutureBuilder<List<Note>>(
                future: _notesFuture,
                builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('没有笔记'));
                }

                final filteredNotes = _filterAndSortNotes(snapshot.data!);

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '没有找到匹配的笔记',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => NoteEditPage(note: note),
                              ),
                            )
                            .then((_) => _refreshNotes());
                      },
                      onLongPress: () {
                        _showDeleteConfirmDialog(note);
                      },
                      child: Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题区域
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      note.title.isNotEmpty
                                          ? note.title[0].toUpperCase()
                                          : 'N',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 单条笔记标签按钮
                                  IconButton(
                                    icon: const Icon(
                                      Icons.label_outline,
                                      size: 20,
                                    ),
                                    tooltip: '打标签',
                                    onPressed: () => _showNoteTagDialog(note),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 内容区域
                              Expanded(
                                child: Text(
                                  note.content,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 标签展示
                              if (note.tags.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      for (final tag in note.tags)
                                        if (tag.trim().isNotEmpty)
                                          Chip(
                                            label: Text(
                                              tag,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            backgroundColor: Colors.blue[50],
                                          ),
                                    ],
                                  ),
                                ),
                              // 时间和操作提示
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(note.updatedAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.more_vert,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: _isProcessingOCR
          ? FloatingActionButton(
              onPressed: null,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NoteEditPage()),
                );
                _refreshNotes();
              },
            ),
      bottomNavigationBar: widget.showAppBar
          ? const CommonBottomBar(currentIndex: 2)
          : null, // 只在独立页面显示
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
