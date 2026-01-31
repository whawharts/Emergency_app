import 'package:flutter/material.dart';

class HospitalPage extends StatefulWidget {
  final List<Map<String, String>> contacts;

  const HospitalPage({super.key, required this.contacts});

  @override
  State<HospitalPage> createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage> {
  late List<Map<String, String>> hospitalContacts;

  @override
  void initState() {
    super.initState();
    _loadHospitalContacts();
  }

  void _loadHospitalContacts() {
    hospitalContacts =
        widget.contacts.where((c) => c["type"] == "Hospital").toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hospital Contacts"),
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
      ),
      body: hospitalContacts.isEmpty
          ? const Center(
              child: Text("No hospital contacts added yet."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hospitalContacts.length,
              itemBuilder: (context, index) {
                final contact = hospitalContacts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_hospital,
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
