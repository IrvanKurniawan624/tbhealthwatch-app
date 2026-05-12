import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projekakhir/core/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasToken returns false when no token stored', () async {
    expect(await ApiClient.hasToken(), false);
  });

  test('hasToken returns true after saveTokens', () async {
    await ApiClient.saveTokens('access123', 'refresh456');
    expect(await ApiClient.hasToken(), true);
  });

  test('clearTokens removes stored tokens', () async {
    await ApiClient.saveTokens('access123', 'refresh456');
    await ApiClient.clearTokens();
    expect(await ApiClient.hasToken(), false);
  });
}
