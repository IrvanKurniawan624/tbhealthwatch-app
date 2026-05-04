import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profile_model.dart';
import 'profile_repository.dart';

class ApiProfileRepository implements IProfileRepository {
  final String baseUrl; // e.g. http://10.0.2.2:5000/api

  ApiProfileRepository({required this.baseUrl});

  @override
  Future<Profile> getProfileData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/me'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Profile.fromJson(data);
      } else {
        throw Exception('Gagal memuat profil');
      }
    } catch (e) {
      throw Exception('Error koneksi ke backend: $e');
    }
  }

  @override
  Future<void> updateProfileData(Profile profile) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/me'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui profil');
      }
    } catch (e) {
      throw Exception('Error koneksi ke backend: $e');
    }
  }
}
