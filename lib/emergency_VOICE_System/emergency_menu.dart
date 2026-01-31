import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_user.dart';
import 'custom_contacts.dart';
import 'feedback_page.dart';
import 'settings_page.dart';
import 'aboutus_page.dart';
import '../auth/auth_service.dart';
import 'userdetails_page.dart';
import 'police_page.dart';
import 'hospital_page.dart';
import 'fire_page.dart';

// 🔹 EMERGENCY DASHBOARD PAGE
class EmergencyMenuPage extends StatefulWidget {
  final List<Map<String, String>> contacts;
  const EmergencyMenuPage({super.key, required this.contacts});

  @override
  State<EmergencyMenuPage> createState() => _EmergencyMenuPageState();
}

class _EmergencyMenuPageState extends State<EmergencyMenuPage> {
  final AuthService _authService = AuthService(); //state variable
  final supabase = Supabase.instance.client;

  String? userEmail;
  String? userId;
  bool isLoading = true;

  //fetch user data
  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() {
      userId = user.id;
      userEmail = user.email;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // 🔹 LOGOUT HANDLER
  Future<void> _handleLogout(BuildContext context) async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 225, 225),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
        title: const Text(
          "EMERGENCY DASHBOARD",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),

      // DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(226, 175, 23, 23),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail ?? "USER",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserDetailsPage(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "View Details",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.contacts, "Custom Contacts"),
            _drawerItem(Icons.history, "Call Log History"),
            _drawerItem(Icons.feedback, "Feedback"),
            _drawerItem(Icons.info, "About Us"),
            _drawerItem(Icons.settings, "Settings"),
            const Divider(),
            _drawerItem(Icons.logout, "Log Out"),
          ],
        ),
      ),

      // BODY
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Column(
              children: [
                const Icon(Icons.person, size: 120),
                const SizedBox(height: 12),
                Text(
                  userEmail ?? "USER",
                  style: const TextStyle(
                      fontSize: 35, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: EmergencyBox(
                        icon: Icons.local_police,
                        label: "POLICE",
                        color: const Color.fromARGB(255, 21, 135, 228),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PolicePage(contacts: widget.contacts),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
  child: EmergencyBox(
    icon: Icons.local_hospital,
    label: "HOSPITAL",
    color: const Color.fromARGB(255, 68, 163, 71),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalPage(contacts: widget.contacts),
        ),
      );
    },
  ),
),

                    const SizedBox(width: 16),

                    Expanded(
  child: EmergencyBox(
    icon: Icons.local_fire_department,
    label: "FIRE",
    color: const Color.fromARGB(255, 241, 59, 46),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FirePage(contacts: widget.contacts),
        ),
      );
    },
  ),
),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 DRAWER ITEM LOGIC
  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context);
        switch (title) {
          case "Log Out":
            await _handleLogout(context);
            break;
          case "Custom Contacts":
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CustomContactsPage()),
            );
            break;
          case "Feedback":
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FeedbackPage()));
            break;
          case "Settings":
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage()));
            break;
          case "About Us":
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutUsPage()));
            break;
          case "view details":
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserDetailsPage()));
            break;
        }
      },
    );
  }
}

// 🔹 EMERGENCY BOX
class EmergencyBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap; // ✅ add callback

  const EmergencyBox({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$label selected")),
              );
            },
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
