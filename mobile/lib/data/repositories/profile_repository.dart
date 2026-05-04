import '../models/profile_model.dart';

abstract class IProfileRepository {
  Future<Profile> getProfileData();
  Future<void> updateProfileData(Profile profile);
}