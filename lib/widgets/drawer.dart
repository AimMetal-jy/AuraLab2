import 'package:flutter/material.dart';

class TabsDrawer extends StatelessWidget {
  const TabsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                image: AssetImage('assets/images/AuraLab_icon.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: null,
          ),
          ListTile(
            title: const Text("示例一"),
            leading: const CircleAvatar(child: Icon(Icons.text_format)),
            //onTap: () => context.push('/tts'),
          ),
          ListTile(
            title: const Text("示例二"),
            leading: const CircleAvatar(child: Icon(Icons.audio_file)),
            //onTap: () => context.push('/asr'),
          ),
        ],
      ),
    );
  }
}
