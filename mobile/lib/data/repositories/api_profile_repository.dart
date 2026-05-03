/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements IProfileRepository {
  final String baseUrl; // Misal: URL API kelompok kalian

  ApiProfileRepository({required this.baseUrl});

  @override
  Future<Profile> getProfileData() async {
    try {
      // TODO: UBAH URL INI SESUAI DENGAN ENDPOINT BACKEND TEMANMU
      final response = await http.get(Uri.parse('$baseUrl/api/profile/me'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Profile(
          name: data['name'],
          role: data['role'],
          facilityName: data['facilityName'],
          facilityRole: data['facilityRole'],
          assignmentLocation: data['assignmentLocation'],
          email: data['email'],
          phone: data['phone'],
          address: data['address'],
        );
      } else {
        throw Exception('Gagal memuat profil');
      }
    } catch (e) {
      throw Exception('Error koneksi ke backend: $e');
    }
  }
}
*/
