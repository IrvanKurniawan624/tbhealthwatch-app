import 'package:flutter_test/flutter_test.dart';
import 'package:projekakhir/data/models/patient_model.dart';

void main() {
  test('Patient.fromJson parses list-endpoint fields', () {
    final json = {
      'id': 'abc-123',
      'nik': '3578010000000001',
      'name': 'Siti Aminah',
      'status': 'DALAM PERAWATAN',
      'location': 'Gubeng, Surabaya',
      'phase': 'PHASE 2 PERAWATAN',
      'currentMonth': 5,
      'totalMonths': 6,
    };
    final p = Patient.fromJson(json);
    expect(p.id, 'abc-123');
    expect(p.name, 'Siti Aminah');
    expect(p.currentMonth, 5);
    expect(p.phone, isNull);
  });

  test('Patient.fromJson parses detail-endpoint fields', () {
    final json = {
      'id': 'abc-123',
      'nik': '3578010000000001',
      'name': 'Siti Aminah',
      'status': 'DALAM PERAWATAN',
      'location': 'Gubeng, Surabaya',
      'phase': 'PHASE 2 PERAWATAN',
      'currentMonth': 5,
      'totalMonths': 6,
      'phone': '+62 811 3452 900',
      'address': 'Jl. Test No.1',
      'dob': '1989-08-17',
      'regionName': 'Gubeng',
      'photoUrl': null,
    };
    final p = Patient.fromJson(json);
    expect(p.phone, '+62 811 3452 900');
    expect(p.dob, '1989-08-17');
    expect(p.regionName, 'Gubeng');
  });
}
