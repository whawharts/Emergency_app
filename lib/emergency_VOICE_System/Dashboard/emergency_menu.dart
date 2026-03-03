import 'package:flutter/material.dart';
import 'package:my_app/emergency_VOICE_System/UserDetails/userdetails_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Contacts/Custom_contacts.dart';
import '../feedback_page.dart';
import '../Settings/settings_page.dart';
import '../AboutUs/aboutus_page.dart';
import '../../auth/auth_service.dart';
import '../../constants/fallback_numbers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_app/services/location_service.dart';


// 🔹 EMERGENCY DASHBOARD PAGE
class EmergencyMenuPage extends StatefulWidget {
  
  final List<Map<String, String>> contacts;
  const EmergencyMenuPage({super.key, required this.contacts});

  @override
  State<EmergencyMenuPage> createState() => _EmergencyMenuPageState();
}




class _EmergencyMenuPageState extends State<EmergencyMenuPage> {
  
  // State variables for location and address
  String? _address;
  bool _isLoadingAddress = false;

  //supabase client
  void _showEmergencyContacts(String type) async {
  if (userId == null) return;

  final response = await supabase
      .from('custom_contacts')
      .select()
      .eq('user_id', userId!)
      .eq('type', type);

      // Check if response is a list of maps

  final contacts = List<Map<String, dynamic>>.from(response); // Cast response to list of maps

  showModalBottomSheet( // Show contacts in a bottom sheet
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: contacts.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min, 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$type Contacts",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text("Emergency Hotline"),
                    subtitle: Text(
                      "Fallback Number: ${FallbackNumbers.getByType(type)}", // Show fallback number if no custom contacts are found
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Calling ${FallbackNumbers.getByType(type)}...", // Show fallback number in snackbar when tapped
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            : Column( // Show custom contacts if they exist
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$type Contacts",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder( // List custom contacts
                    shrinkWrap: true,
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(contact['name']),
                        subtitle: Text(
                          "${contact['number']}\n${contact['location']}",
                        ),
                        isThreeLine: true,
                        onTap: () async {
                          final phoneNumber = (contact['number'] ?? '').toString().trim();
                          if (phoneNumber.isEmpty) return;

                          final ok = await launchUrl(
                            Uri(scheme: 'tel', path: phoneNumber),
                            mode: LaunchMode.externalApplication,
                          );

                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not open phone dialer")),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
      );
    },
  );
}





  //auth service

  final AuthService _authService = AuthService();
  

  //state variable 
  final supabase = Supabase.instance.client;

  String? userEmail;
  String? userId;
  bool isLoading = true;

  //fetch user data
  Future<void> _loadUser() async {
  final user = supabase.auth.currentUser;

    if (user == null) {
      // Safety fallback
      return;
    }

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
  _initLocationFlow();
}

Future<void> _initLocationFlow() async {
  if (!mounted) return;

  setState(() => _isLoadingAddress = true);

  try {
    final pos = await LocationService.refresh();

    if (pos == null) {
      setState(() {
        _address = LocationService.lastError ?? "Location not available";
      });
      return;
    }

    // 1) Convert to address (with timeout)
    String? addr;
    try {
      addr = await LocationService.getAddressFromPosition(pos)
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      addr = "Address lookup failed (check internet)";
    }

    // 2) SAVE TO DB (with timeout + catch)
    try {
      await LocationService.saveToDatabase(
        userId: supabase.auth.currentUser!.id, // ✅ don’t use userId! state
        pos: pos,
        address: addr,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      // If saving fails, still show address (don’t freeze)
      debugPrint("Save location failed: $e");
    }

    if (!mounted) return;
    setState(() {
      _address = addr ?? "Address not available";
    });
  } finally {
    if (!mounted) return;
    setState(() => _isLoadingAddress = false);
  }
}


  // 🔹 LOGOUT HANDLER
  Future<void> _handleLogout(BuildContext context) async {
    await _authService.signOut();
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(214, 184, 23, 23),
        title: const Text(
          "DASHBOARD",
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
            Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color.fromARGB(214, 184, 23, 23),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final pos = LocationService.lastKnownPosition;
                  final err = LocationService.lastError;

                  if (err != null) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_off, color: Color.fromARGB(214, 184, 23, 23)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            err,
                            style: const TextStyle(
                              color: Color.fromARGB(214, 184, 23, 23),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (pos == null) {
                    return const Row(
                      children: [
                        Icon(Icons.location_searching, color: Color.fromARGB(214, 184, 23, 23)),
                        SizedBox(width: 10),
                        Text("Getting location..."),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color.fromARGB(214, 184, 23, 23)),
                          SizedBox(width: 8),
                          Text(
                            "Current Location",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Address
                      Text(
                        _isLoadingAddress
                            ? "Converting coordinates to address..."
                            : (_address ?? "Address not available"),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Lat/Lng (small)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Lat: ${pos.latitude.toStringAsFixed(5)}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Lng: ${pos.longitude.toStringAsFixed(5)}",
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
                        label: "Police",
                        color: const Color.fromARGB(255, 0, 140, 255),
                        onPressed: () {
                          _showEmergencyContacts("Police");
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EmergencyBox(
                        icon: Icons.local_hospital,
                        label: "Hospital",
                        color: const Color.fromARGB(255, 68, 163, 71),
                        onPressed: () {
                          _showEmergencyContacts("Hospital");
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EmergencyBox(
                        icon: Icons.local_fire_department,
                        label: "Fire Station",
                        color: const Color.fromARGB(255, 241, 59, 46),
                        onPressed: () {
                          _showEmergencyContacts("Fire Station");
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
  final VoidCallback onPressed; // Callback for when the box is pressed

  const EmergencyBox({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: onPressed, // 👈 USE THIS
        child: Container(
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
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
