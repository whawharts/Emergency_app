import 'package:flutter/material.dart';

class FirePage extends StatefulWidget {
  final List<Map<String, String>> contacts;

  const FirePage({super.key, required this.contacts});

  @override
  State<FirePage> createState() => _FirePageState();
}

class _FirePageState extends State<FirePage> {
  late List<Map<String, String>> fireContacts;

  @override
  void initState() {
    super.initState();
    _loadFireContacts();
  }

  void _loadFireContacts() {
    fireContacts =
        widget.contacts.where((c) => c["type"] == "Fire Station").toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fire Station Contacts"),
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
      ),
      body: fireContacts.isEmpty
          ? const Center(
              child: Text("No fire station contacts added yet."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fireContacts.length,
              itemBuilder: (context, index) {
                final contact = fireContacts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_fire_department,
                      color: Color.fromARGB(214, 184, 23, 23),
                    ),
                    title: Text(
                      contact["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        Text("${contact["phone"]!}\n${contact["location"]!}"),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
