import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/note_database_service.dart';
import '../services/ocr_service.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingOCR = false;

  // 搜索和排序相关变量
  String _searchQuery = '';
  NoteSortOption _currentSort = NoteSortOption.modifiedTime;
  bool _isAscending = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
  }

  // 过滤和排序笔记
  List<Note> _filterAndSortNotes(List<Note> notes) {
    // 搜索过滤
    var filtered = notes;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
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

  /// 拍照识别文字功能
  Future<void> _takePhotoAndRecognizeText() async {
    try {
      // 拍照
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isProcessingOCR = true;
      });

      // 显示处理中的提示
      if (!mounted) return;
      CustomToast.show(context, message: '正在识别图片中的文字...');

      // 读取图片字节
      final imageBytes = await image.readAsBytes();

      // 调用OCR服务
      final recognizedText = await OCRService.recognizeText(imageBytes);

      setState(() {
        _isProcessingOCR = false;
      });

      if (recognizedText.isNotEmpty) {
        // 识别成功，跳转到笔记编辑页面
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditPage(initialContent: recognizedText),
          ),
        );
        _refreshNotes();
        if (!mounted) return;
        CustomToast.show(context, message: '文字识别成功！', type: ToastType.success);
      } else {
        if (!mounted) return;
        CustomToast.show(
          context,
          message: '未识别到文字，请重试',
          type: ToastType.warning,
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingOCR = false;
      });
      if (!mounted) return;
      CustomToast.show(
        context,
        message: '识别失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  /// 从相册选择图片识别文字
  Future<void> _pickImageAndRecognizeText() async {
    try {
      // 从相册选择图片
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isProcessingOCR = true;
      });

      if (!mounted) return;
      CustomToast.show(context, message: '正在识别图片中的文字...');

      // 读取图片字节
      final imageBytes = await image.readAsBytes();

      // 调用OCR服务
      final recognizedText = await OCRService.recognizeText(imageBytes);

      setState(() {
        _isProcessingOCR = false;
      });

      if (recognizedText.isNotEmpty) {
        // 识别成功，跳转到笔记编辑页面
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditPage(initialContent: recognizedText),
          ),
        );
        _refreshNotes();
        if (!mounted) return;
        CustomToast.show(context, message: '文字识别成功！', type: ToastType.success);
      } else {
        if (!mounted) return;
        CustomToast.show(
          context,
          message: '未识别到文字，请重试',
          type: ToastType.warning,
        );
      }
    } catch (e) {
      setState(() {
        _isProcessingOCR = false;
      });
      if (!mounted) return;
      CustomToast.show(
        context,
        message: '识别失败: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  /// 显示OCR选项底部弹窗
  void _showOCROptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择图片识别文字',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照识别'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoAndRecognizeText();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndRecognizeText();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
                if (_isSearching)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _showOCROptions,
                    tooltip: '拍照识别文字',
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: _showSortOptions,
                  ),
                ],
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
          // 笔记列表
          Expanded(
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
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NoteEditPage(note: note),
                          ),
                        );
                        _refreshNotes();
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
