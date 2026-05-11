import 'package:flutter/material.dart';
import '../monitoring/monitoring_page.dart'; // Import halaman tujuan setelah login

// ============================================================================
// 1. HALAMAN UTAMA LOGIN
// ============================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // ----------------------------------------------------------------------
    // ⚠️ TEMPAT INTEGRASI API LOGIN NANTI
    // Di sini kamu bisa memanggil AuthRepository untuk validasi ke backend
    // ----------------------------------------------------------------------
    
    // Untuk sekarang, kita langsung navigasi ke halaman Monitoring
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MonitoringPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Menggunakan SafeArea agar konten tidak tertutup notch/status bar HP
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const LoginHeader(),
              const SizedBox(height: 40),
              LoginForm(
                emailController: _emailController,
                passwordController: _passwordController,
                onLogin: _handleLogin,
              ),
              const SizedBox(height: 64),
              const LoginFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. KOMPONEN: HEADER (Logo & Teks Selamat Datang)
// ============================================================================
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 60,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.health_and_safety, size: 60, color: Color(0xFF0052CC)),
        ),
        const SizedBox(height: 32),
        const Text(
          "Welcome back, Admin",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Sign in to continue monitoring patient health.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. KOMPONEN: FORM LOGIN & TOMBOL
// ============================================================================
class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Input Email ---
        const Text("EMAIL / MEDICAL ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: emailController,
          hintText: "admin@gmail.com",
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        
        // --- Input Password & Lupa Password ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PASSWORD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
            GestureDetector(
              onTap: () {
                // Aksi lupa password
              },
              child: const Text("Forgot Password?", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0052CC))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: passwordController,
          hintText: "••••••••",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        
        // --- Tombol Sign In ---
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC), // Biru gelap
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Tombol membulat
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget custom khusus untuk TextField di halaman login
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey[200], // Background abu-abu
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================================
// 4. KOMPONEN: FOOTER (Disclaimer)
// ============================================================================
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.circle, size: 8, color: Color(0xFF8B4513)), // Titik coklat
            SizedBox(width: 8),
            Text(
              "SECURE CLINICAL NETWORK",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Unauthorized access to health data is strictly\nprohibited under regional medical data protection\nregulations. Surabaya Health Dept. 2024.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
