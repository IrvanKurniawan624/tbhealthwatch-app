import '../models/profile_model.dart';
import 'profile_repository.dart';
import '../../core/api_client.dart';

class ApiProfileRepository implements IProfileRepository {
  final ApiClient _client;

  ApiProfileRepository(this._client);

  @override
  Future<Profile> getProfileData() async {
    final data =
        await _client.get('/profile/me') as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  @override
  Future<void> updateProfileData(Profile profile) async {
    await _client.put('/profile/me', profile.toJson());
  }
}
