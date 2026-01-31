import 'package:flutter/material.dart';


class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
        title: const Text("User Details"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),
            const Text(
              "User Information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Example: Name
            Row(
              children: const [
                Icon(Icons.person, color: Colors.black54),
                SizedBox(width: 10),
                Text(
                  "Full Name: John Cedrick lajato",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Example: Email
            Row(
              children: const [
                Icon(Icons.email, color: Colors.black54),
                SizedBox(width: 10),
                Text(
                  "Email: cedricklaajto04@gmail.com",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Example: Contact
            Row(
              children: const [
                Icon(Icons.phone, color: Colors.black54),
                SizedBox(width: 10),
                Text(
                  "Contact: +63 912 345 6789",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Example: User ID
            Row(
              children: const [
                Icon(Icons.perm_identity, color: Colors.black54),
                SizedBox(width: 10),
                Text(
                  "User ID: ABC123456",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
