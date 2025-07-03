import 'package:flutter/material.dart';
import '../services/note_database_service.dart';
import '../models/note_model.dart';
import 'note_edit_page.dart';

class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key});

  @override
  NoteListPageState createState() => NoteListPageState();
}

class NoteListPageState extends State<NoteListPage> {
  late Future<List<Note>> _notesFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记'),
        actions: [
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
      ),
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
                subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NoteEditPage()),
          );
          _refreshNotes();
        },
      ),
    );
  }
}