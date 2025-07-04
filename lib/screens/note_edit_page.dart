import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../models/note_model.dart';
import '../services/note_database_service.dart';
import '../widgets/custom_toast.dart';

// 自定义图片构建器
class CustomImageBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String? src = element.attributes['src'];
    if (src == null) return null;

    final uri = Uri.tryParse(src);
    if (uri == null) return null;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return Image.network(
        uri.toString(),
        width: 300,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 300,
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } else if (uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 300,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('图片加载失败', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        );
      } else {
        return Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('图片文件不存在', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }
    } else {
      return Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('不支持的图片格式', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }
}

class NoteEditPage extends StatefulWidget {
  final Note? note;
  final String? initialContent;

  const NoteEditPage({super.key, this.note, this.initialContent});

  @override
  NoteEditPageState createState() => NoteEditPageState();
}

class NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isMarkdown = true;
  late List<String> _images;

  bool _showPreview = false;
  
  // 自动保存相关
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  String _lastSavedTitle = '';
  String _lastSavedContent = '';
  DateTime? _lastAutoSaveTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? widget.initialContent ?? '',
    );
    _isMarkdown = widget.note?.isMarkdown ?? false;
    _images = widget.note?.images ?? [];
    
    // 初始化保存状态
    _lastSavedTitle = _titleController.text;
    _lastSavedContent = _contentController.text;
    
    // 添加文本变化监听器
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    
    // 启动自动保存定时器（每30秒检查一次）
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performAutoSave();
    });
  }

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final now = DateTime.now();
      final note = Note(
        id: widget.note?.id,
        title: _titleController.text,
        content: _contentController.text,
        isMarkdown: _isMarkdown,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        categoryId: 1, // Default category for now
        images: _images,
      );

      if (widget.note == null) {
        await NoteDatabaseService.instance.createNote(note);
      } else {
        await NoteDatabaseService.instance.updateNote(note);
      }
      
      // 更新保存状态，避免重复保存
      _lastSavedTitle = _titleController.text;
      _lastSavedContent = _contentController.text;
      _lastAutoSaveTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }

      if (!mounted) return;
      CustomToast.show(context, message: '笔记保存成功', type: ToastType.success);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final imageUri = Uri.file(pickedFile.path).toString();
        setState(() {
          _images.add(pickedFile.path);
          _contentController.text += '\n![image]($imageUri)\n';
        });

        if (!mounted) return;
        CustomToast.show(context, message: '图片插入成功', type: ToastType.success);
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(context, message: '图片插入失败：$e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.note == null ? '新建笔记' : '编辑笔记'),
            if (_hasUnsavedChanges) ...[
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.orange,
                   borderRadius: BorderRadius.circular(10),
                 ),
                 child: const Text(
                   '未保存',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 10,
                   ),
                 ),
               ),
             ] else if (_lastAutoSaveTime != null) ...[
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.green,
                   borderRadius: BorderRadius.circular(10),
                 ),
                 child: const Text(
                   '已保存',
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 10,
                   ),
                 ),
               ),
             ]
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
          IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '标题'),
                validator: (value) => value!.isEmpty ? '标题不能为空' : null,
              ),
              Expanded(
                child: _showPreview
                    ? Markdown(
                        data: _contentController.text,
                        // 使用新的builders属性替代已弃用的imageBuilder
                        builders: {'img': CustomImageBuilder()},
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        extensionSet: md.ExtensionSet(
                          md.ExtensionSet.gitHubWeb.blockSyntaxes,
                          [
                            md.EmojiSyntax(),
                            ...md.ExtensionSet.gitHubWeb.inlineSyntaxes,
                          ],
                        ),
                      )
                    : TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(labelText: '内容'),
                        maxLines: null,
                        expands: true,
                      ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isMarkdown,
                    onChanged: (value) {
                      setState(() {
                        _isMarkdown = value!;
                      });
                    },
                  ),
                  const Text('使用Markdown格式'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 取消自动保存定时器
    _autoSaveTimer?.cancel();
    
    // 移除监听器
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    
    // 最后一次自动保存
    _autoSaveNote();
    
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 文本变化监听器
  void _onTextChanged() {
    final currentTitle = _titleController.text;
    final currentContent = _contentController.text;
    
    if (currentTitle != _lastSavedTitle || currentContent != _lastSavedContent) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }
  
  // 执行自动保存
  Future<void> _performAutoSave() async {
    if (_hasUnsavedChanges) {
      await _autoSaveNote();
    }
  }
  
  // 自动保存方法（静默保存）
  Future<void> _autoSaveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      return;
    }

    try {
      // 检查内容是否真的有变化，避免重复保存
      final currentTitle = _titleController.text;
      final currentContent = _contentController.text;
      
      if (currentTitle == _lastSavedTitle && currentContent == _lastSavedContent) {
        return; // 内容没有变化，不需要保存
      }
      
      final now = DateTime.now();
      final note = Note(
        id: widget.note?.id,
        title: _titleController.text.trim().isEmpty
            ? '无标题'
            : _titleController.text,
        content: _contentController.text,
        isMarkdown: _isMarkdown,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
        categoryId: 1,
        images: _images,
      );
      
      if (widget.note == null) {
        await NoteDatabaseService.instance.createNote(note);
      } else {
        await NoteDatabaseService.instance.updateNote(note);
      }
      
      // 更新保存状态
      _lastSavedTitle = currentTitle;
      _lastSavedContent = currentContent;
      _lastAutoSaveTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      // 静默处理错误，避免在dispose时显示错误
    }
  }
}
