import 'package:flutter/material.dart';
import 'emergency_menu.dart';

class CustomContactsPage extends StatefulWidget {
  const CustomContactsPage({super.key});

  @override
  State<CustomContactsPage> createState() => _CustomContactsPageState();
}

class _CustomContactsPageState extends State<CustomContactsPage> {
  final List<Map<String, String>> contacts = [];

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  String emergencyType = "Police"; // Default value

  void addContact() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty || phone.isEmpty || location.isEmpty || emergencyType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() {
      contacts.add({
        "name": name,
        "phone": phone,
        "location": location,
        "type": emergencyType,
      });
    });

    // Clear fields
    nameController.clear();
    phoneController.clear();
    locationController.clear();
    emergencyType = "Police";

    Navigator.pop(context);
  }

  void showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Emergency Contact"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Contact Number",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),

                // Type of Emergency Dropdown
                DropdownButtonFormField<String>(
                  initialValue: emergencyType,
                  items: const [
                    DropdownMenuItem(value: "Police", child: Text("Police")),
                    DropdownMenuItem(value: "Hospital", child: Text("Hospital")),
                    DropdownMenuItem(value: "Fire Station", child: Text("Fire Station")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      emergencyType = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Type of Emergency",
                    prefixIcon: Icon(Icons.warning),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: addContact,
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 199, 199),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
        title: const Text(
          "Custom Contacts",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
        onPressed: showAddContactDialog,
        child: const Icon(Icons.add),
      ),
      body: contacts.isEmpty
          ? const Center(
              child: Text(
                "No emergency contacts added",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: Color.fromARGB(214, 184, 23, 23),
                    ),
                    title: Text(
                      contact["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        "${contact["phone"]!}\n${contact["location"]!} - ${contact["type"]!}"),
                    isThreeLine: true,

                    // Tap contact → Emergency Menu
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EmergencyMenuPage(contacts: contacts),
    ),
  );
},

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          contacts.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}