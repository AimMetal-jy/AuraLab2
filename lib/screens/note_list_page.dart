import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/note_database_service.dart';
import '../services/ocr_service.dart';
import '../models/note_model.dart';
import 'note_edit_page.dart';
import '../widgets/drawer.dart';
import '../widgets/common_bottom_bar.dart';
import '../widgets/custom_toast.dart';

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

  @override
  void initState() {
    super.initState();
    _notesFuture = NoteDatabaseService.instance.readAllNotes();
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = NoteDatabaseService.instance.readAllNotes();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('笔记'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _showOCROptions,
                  tooltip: '拍照识别文字',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    // TODO: Implement sort functionality
                  },
                ),
              ],
            )
          : null,
      drawer: widget.showAppBar ? const TabsDrawer() : null,
      body: FutureBuilder<List<Note>>(
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

          final notes = snapshot.data!;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NoteEditPage(note: note),
                    ),
                  );
                  _refreshNotes();
                },
              );
            },
          );
        },
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
}
