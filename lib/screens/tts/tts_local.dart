import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:xml/xml.dart';
import 'dart:convert';
import '../../services/tts_selection_service.dart';
import 'package:archive/archive_io.dart';

class TtsSenderLocal extends StatefulWidget {
  const TtsSenderLocal({super.key});

  @override
  TtsSenderLocalState createState() => TtsSenderLocalState();
}

class TtsSenderLocalState extends State<TtsSenderLocal> {
  final TtsSelectionService _ttsSelectionService = TtsSelectionService();
  bool _isLoading = false;

  Future<void> _pickAndProcessFiles() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'json', 'docx'],
      );
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }
      List<String> allTexts = [];
      for (final file in result.files) {
        final path = file.path;
        if (path == null) continue;
        final ext = path.split('.').last.toLowerCase();
        String text = '';
        if (ext == 'txt') {
          text = await File(path).readAsString();
        } else if (ext == 'json') {
          final content = await File(path).readAsString();
          final jsonData = jsonDecode(content);
          if (jsonData is Map<String, dynamic>) {
            if (jsonData.containsKey('text')) {
              text = jsonData['text'].toString();
            } else if (jsonData.containsKey('content')) {
              text = jsonData['content'].toString();
            } else {
              text = content;
            }
          } else if (jsonData is List) {
            text = jsonData.map((e) => e.toString()).join('\n');
          } else {
            text = content;
          }
        } else if (ext == 'docx') {
          final bytes = await File(path).readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          final docEntry = archive.files.firstWhere(
            (e) => e.name == 'word/document.xml',
            orElse: () => throw Exception('docx文件无正文'),
          );
          final xmlDoc = XmlDocument.parse(utf8.decode(docEntry.content));
          text = xmlDoc
              .findAllElements('w:t')
              .map((node) => node.innerText)
              .join(' ');
        }
        if (text.trim().isNotEmpty) {
          allTexts.add(text.trim());
          await _ttsSelectionService.addText(text.trim());
        }
      }
      setState(() => _isLoading = false);
      if (allTexts.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('提取并添加成功'),
            content: SingleChildScrollView(
              child: Text(allTexts.join('\n\n---\n\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('未提取到有效文本'),
            content: Text('请检查文件内容是否为纯文本或支持的结构'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('文件处理失败'),
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("自行上传文件"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('选择并上传docx/txt/json文件'),
                onPressed: _pickAndProcessFiles,
              ),
      ),
    );
  }
}
