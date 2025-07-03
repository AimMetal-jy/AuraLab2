import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../models/note_model.dart';
import '../services/note_database_service.dart';
import '../widgets/custom_toast.dart';

class NoteEditPage extends StatefulWidget {
  final Note? note;

  const NoteEditPage({super.key, this.note});

  @override
  NoteEditPageState createState() => NoteEditPageState();
}

class NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isMarkdown;
  late List<String> _images;

  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _isMarkdown = widget.note?.isMarkdown ?? false;
    _images = widget.note?.images ?? [];
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

      if (!mounted) return;
      CustomToast.show(
        context,
        message: '笔记保存成功',
        type: ToastType.success,
      );
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
        CustomToast.show(
          context,
          message: '图片插入成功',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(
        context,
        message: '图片插入失败：$e',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
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
                validator: (value) =>
                    value!.isEmpty ? '标题不能为空' : null,
              ),
              Expanded(
                child: _showPreview
                    ? Markdown(
                        data: _contentController.text,
                        imageBuilder: (uri, title, alt) {
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
                            // Handle other cases or return a placeholder
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
                        },
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
}