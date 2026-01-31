
import 'package:flutter/material.dart';


class PolicePage extends StatefulWidget {
  final List<Map<String, String>> contacts; 

  const PolicePage({super.key, required this.contacts});

  @override
  State<PolicePage> createState() => _PolicePageState();
}

class _PolicePageState extends State<PolicePage> {
  late List<Map<String, String>> policeContacts;

  @override
  void initState() {
    super.initState();
    _loadPoliceContacts();
  }

  void _loadPoliceContacts() {
    policeContacts = widget.contacts
        .where((c) => c["type"] == "Police")
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Police Contacts"),
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
      ),
      body: policeContacts.isEmpty
          ? const Center(
              child: Text("No police contacts added yet."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: policeContacts.length,
              itemBuilder: (context, index) {
                final contact = policeContacts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_police,
                      color: Color.fromARGB(214, 184, 23, 23),
                    ),
                    title: Text(
                      contact["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${contact["phone"]!}\n${contact["location"]!}"),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
