import 'package:flutter/material.dart';
import 'emergency_menu.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;

  final fullNameController = TextEditingController();
  final contactController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void handleSubmit() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (isLogin) {
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email and password are required")),
        );
        return;
      }
    } else {
      if (fullNameController.text.isEmpty ||
          contactController.text.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")),
        );
        return;
      }

      if (password != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyMenuPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 193, 193),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔝 HEADER WITH MIC BACKGROUND
                SizedBox(
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 420,
                        color: Colors.red.withOpacity(0.08),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          // ❌ Emergency icon without circle
                          Icon(
                            Icons.emergency,
                            size: 130,
                            color: Color.fromARGB(255, 187, 28, 28),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Emergency Voice",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 51, 51, 51),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ❌ USER ICON WITHOUT CIRCLE
                const Center(
                  child: Icon(
                    Icons.person,
                    size: 120,
                    color: Color.fromARGB(255, 54, 54, 54),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔐 LOGIN / SIGN UP TEXT
                Text(
                  isLogin ? "GUEST" : "Sign Up",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // 👤 FULL NAME (SIGN UP ONLY)
                if (!isLogin)
                  Column(
                    children: [
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // 📞 CONTACT NUMBER (SIGN UP ONLY)
                if (!isLogin)
                  Column(
                    children: [
                      TextField(
                        controller: contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Contact Number",
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // 📧 EMAIL
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔑 PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔁 CONFIRM PASSWORD (SIGN UP ONLY)
                if (!isLogin)
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),

                const SizedBox(height: 20),

                // 🔘 BUTTON
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    child: Text(isLogin ? "LOGIN" : "SIGN UP"),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    setState(() => isLogin = !isLogin);
                  },
                  child: Text(
                    isLogin
                        ? "Create new account"
                        : "Already have an account? Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
