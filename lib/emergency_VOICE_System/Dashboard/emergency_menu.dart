import 'package:flutter/material.dart';
import 'package:my_app/emergency_VOICE_System/Contacts/Custom_contacts.dart';
import 'package:my_app/emergency_VOICE_System/UserDetails/userdetails_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../feedback_page.dart';
import '../Settings/settings_page.dart';
import '../AboutUs/aboutus_page.dart';
import '../../auth/auth_service.dart';
import 'package:my_app/services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// 🔹 EMERGENCY DASHBOARD PAGE
class EmergencyMenuPage extends StatefulWidget {
  final List<Map<String, String>> contacts;

  const EmergencyMenuPage({
    super.key,
    required this.contacts,
  });

  @override
  State<EmergencyMenuPage> createState() => _EmergencyMenuPageState();
}

class _EmergencyMenuPageState extends State<EmergencyMenuPage> {
  // -----------------------------
  // EASY CONFIG SECTION
  // -----------------------------
  static const double mapHeight = 260;
  static const double defaultZoom = 15;
  static const String fireContactType =
      "fire"; // change to "fire_station" if your DB uses that

  // -----------------------------
  // STATE
  // -----------------------------
  String? _address;
  bool _isLoadingAddress = false;

  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;

  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  String? _selectedType;
  List<Map<String, dynamic>> _emergencyContacts = [];
  Map<String, dynamic>? _selectedContact;
  String _fallbackNumber = "911";

  String? userEmail;
  String? userId;
  bool isLoading = true;

  // -----------------------------
  // USER LOADING
  // -----------------------------
  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      userId = user.id;
      userEmail = user.email;
      isLoading = false;
    });
  }

  // -----------------------------
  // INIT
  // -----------------------------
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

      String? addr;
      try {
        addr = await LocationService.getAddressFromPosition(pos)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        addr = "Address lookup failed (check internet)";
      }

      try {
        await LocationService.saveToDatabase(
          userId: supabase.auth.currentUser!.id,
          pos: pos,
          address: addr,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint("Save location failed: $e");
      }

      if (!mounted) return;
      setState(() {
        _address = addr ?? "Address not available";
      });

      _setUserMarker();
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingAddress = false);
    }
  }

  // -----------------------------
  // MAP HELPERS
  // -----------------------------
  void _setUserMarker() {
    final pos = LocationService.lastKnownPosition;
    if (pos == null) return;

    setState(() {
      _markers = [
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.blue,
          ),
        ),
      ];
    });

    _mapController.move(
      LatLng(pos.latitude, pos.longitude),
      defaultZoom,
    );
  }

  void _resetMapToUser() {
    final pos = LocationService.lastKnownPosition;
    if (pos == null) return;

    _mapController.move(
      LatLng(pos.latitude, pos.longitude),
      defaultZoom,
    );
  }

  Color _typeColor(String contactType) {
    switch (contactType) {
      case 'police':
        return const Color.fromARGB(255, 9, 63, 107);
      case 'hospital':
        return const Color.fromARGB(255, 3, 117, 6);
      default:
        return const Color.fromARGB(255, 124, 22, 15);
    }
  }

  IconData _typeIcon(String contactType) {
    switch (contactType) {
      case 'police':
        return Icons.local_police;
      case 'hospital':
        return Icons.local_hospital;
      default:
        return Icons.local_fire_department;
    }
  }

  Future<void> _showEmergencyType(String contactType) async {
    final uid = supabase.auth.currentUser?.id;
    final userPos = LocationService.lastKnownPosition;

    if (uid == null || userPos == null) return;

    try {
      // Load emergency contacts
      final response = await supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', uid)
          .eq('contact_type', contactType)
          .order('rank', ascending: true);

      final contacts = List<Map<String, dynamic>>.from(response);

      // Load fallback from user_settings
      final settings = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      String fallback = "911";
      if (settings != null) {
        switch (contactType) {
          case 'police':
            fallback = (settings['police_fallback'] ?? "911").toString();
            break;
          case 'hospital':
            fallback = (settings['hospital_fallback'] ?? "911").toString();
            break;
          default:
            fallback = (settings['fire_fallback'] ?? "911").toString();
        }
      }

      // Build markers (user + 3 emergency contacts)
      final List<Marker> newMarkers = [
        Marker(
          point: LatLng(userPos.latitude, userPos.longitude),
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.blue,
          ),
        ),
      ];

      for (final contact in contacts) {
        final lat = (contact['latitude'] as num?)?.toDouble();
        final lng = (contact['longitude'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          newMarkers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 50,
              height: 50,
              child: Icon(
                _typeIcon(contactType),
                size: 30,
                color: _typeColor(contactType),
              ),
            ),
          );
        }
      }

      setState(() {
        _selectedType = contactType;
        _selectedContact = null;
        _emergencyContacts = contacts;
        _fallbackNumber = fallback;
        _markers = newMarkers;
      });

      _mapController.move(
        LatLng(userPos.latitude, userPos.longitude),
        14,
      );
    } catch (e) {
      debugPrint("Failed to load emergency contacts: $e");
    }
  }

  void _selectEmergencyContact(Map<String, dynamic> contact) {
    final userPos = LocationService.lastKnownPosition;
    if (userPos == null || _selectedType == null) return;

    final lat = (contact['latitude'] as num?)?.toDouble();
    final lng = (contact['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) return;

    final userLat = userPos.latitude;
    final userLng = userPos.longitude;

    final centerLat = (userLat + lat) / 2;
    final centerLng = (userLng + lng) / 2;

    setState(() {
      _selectedContact = contact;
      _markers = [
        Marker(
          point: LatLng(userLat, userLng),
          width: 60,
          height: 60,
          child: const Icon(
            Icons.location_pin,
            size: 40,
            color: Colors.blue,
          ),
        ),
        Marker(
          point: LatLng(lat, lng),
          width: 60,
          height: 60,
          child: Icon(
            _typeIcon(_selectedType!),
            size: 38,
            color: _typeColor(_selectedType!),
          ),
        ),
      ];
    });

    _mapController.move(
      LatLng(centerLat, centerLng),
      13,
    );
  }

  Future<void> _callNumber(String number) async {
    final cleanNumber = number.trim();
    if (cleanNumber.isEmpty) return;

    final ok = await launchUrl(
      Uri(scheme: 'tel', path: cleanNumber),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open phone dialer")),
      );
    }
  }

  String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return "Nearest";
      case 2:
        return "2nd Nearest";
      case 3:
        return "3rd Nearest";
      default:
        return "Contact";
    }
  }

  // -----------------------------
  // LOGOUT
  // -----------------------------
  Future<void> _handleLogout(BuildContext context) async {
    await _authService.signOut();
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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

      // -----------------------------
      // DRAWER
      // -----------------------------
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

      // -----------------------------
      // BODY
      // -----------------------------
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // -----------------------------
              // LOCATION CARD ABOVE MAP
              // -----------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
                            const Icon(
                              Icons.location_off,
                              color: Color.fromARGB(214, 184, 23, 23),
                            ),
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
                            Icon(
                              Icons.location_searching,
                              color: Color.fromARGB(214, 184, 23, 23),
                            ),
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
                              Icon(
                                Icons.location_on,
                                color: Color.fromARGB(214, 184, 23, 23),
                              ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Lat: ${pos.latitude.toStringAsFixed(5)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "Lng: ${pos.longitude.toStringAsFixed(5)}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedType != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              "Showing: $_selectedType",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              // -----------------------------
              // MAP + RESET BUTTON // EMERGENCY CONTACTS MARKERS // MAP CENTERED ON USER LOCATION //temporary map: OpenStreetMap
              // -----------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: mapHeight,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              LocationService.lastKnownPosition?.latitude ??
                                  10.0,
                              LocationService.lastKnownPosition?.longitude ??
                                  122.0,
                            ),
                            initialZoom: defaultZoom,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.my_app',
                            ),
                            MarkerLayer(
                              markers: _markers,
                            ),
                          ],
                        ),
                      ),

                      // Reset-to-user button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: "reset_map_btn",
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromARGB(214, 184, 23, 23),
                          onPressed: _resetMapToUser,
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------
              // EMERGENCY BUTTONS
              // -----------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: EmergencyIconButton(
                        icon: Icons.local_police,
                        color: const Color.fromARGB(255, 9, 63, 107),
                        onPressed: () => _showEmergencyType("police"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EmergencyIconButton(
                        icon: Icons.local_hospital,
                        color: const Color.fromARGB(255, 3, 117, 6),
                        onPressed: () => _showEmergencyType("hospital"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: EmergencyIconButton(
                        icon: Icons.local_fire_department,
                        color: const Color.fromARGB(255, 124, 22, 15),
                        onPressed: () => _showEmergencyType(fireContactType),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -----------------------------
              // EMERGENCY CONTACTS LIST IN DASHBOARD
              // -----------------------------
              if (_selectedType != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Emergency Contacts",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_emergencyContacts.isEmpty)
                        const Card(
                          child: ListTile(
                            title: Text("No emergency contacts found."),
                          ),
                        )
                      else
                        ..._emergencyContacts.map((contact) {
                          final rank = (contact['rank'] ?? 0) as int;
                          final name = (contact['name'] ?? '').toString();
                          final number =
                              (contact['phone_number'] ?? '').toString();
                          final address = (contact['address'] ?? '').toString();

                          final isSelected =
                              _selectedContact != null &&
                                  _selectedContact!['id'] == contact['id'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              color: isSelected
                                  ? _typeColor(_selectedType!).withOpacity(0.10)
                                  : null,
                              child: ListTile(
                                leading: Icon(
                                  _typeIcon(_selectedType!),
                                  color: _typeColor(_selectedType!),
                                ),
                                title: Text("${_rankLabel(rank)} • $name"),
                                subtitle: Text("$number\n$address"),
                                isThreeLine: true,
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green)
                                    : null,
                                onTap: () => _selectEmergencyContact(contact),
                              ),
                            ),
                          );
                        }).toList(),

                      // Fallback
                      Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                          title: const Text("Fallback Hotline"),
                          subtitle: Text(_fallbackNumber),
                          onTap: () => _callNumber(_fallbackNumber),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Call selected contact button
                      if (_selectedContact != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final number = (_selectedContact!['phone_number'] ?? '')
                                  .toString();
                              _callNumber(number);
                            },
                            icon: const Icon(Icons.call),
                            label: const Text("Call"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(214, 184, 23, 23),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // DRAWER ITEM
  // -----------------------------
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
                builder: (_) => const CustomContactsPage(),
              ),
            );
            break;

          case "Feedback":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackPage()),
            );
            break;

          case "Settings":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
            break;

          case "About Us":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutUsPage()),
            );
            break;

          case "view details":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserDetailsPage()),
            );
            break;
        }
      },
    );
  }
}

// 🔹 SIMPLE ICON BUTTON
class EmergencyIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const EmergencyIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Icon(
          icon,
          size: 30,
        ),
      ),
    );
  }
}