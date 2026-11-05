import 'package:campus_fix/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ALU email', () {
    test('accepts student and staff domains', () {
      expect(Validators.aluEmail('a.uwase@alustudent.com'), isNull);
      expect(Validators.aluEmail('J.Mugisha@ALUeducation.com'), isNull);
    });

    test('rejects malformed input', () {
      expect(Validators.aluEmail('alustudent.com'), isNotNull);
      expect(Validators.aluEmail(''), isNotNull);
    });

    test('rejects other domains and look-alikes', () {
      expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
      expect(Validators.aluEmail('x@alustudent.com.evil.io'), isNotNull);
      expect(Validators.aluEmail('x@fakealustudent.com'), isNotNull);
    });
  });

  group('passwords', () {
    test('new password needs 8+ chars with letters and numbers', () {
      expect(Validators.newPassword('short1'), isNotNull);
      expect(Validators.newPassword('onlyletters'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('campus2026'), isNull);
    });
  });

  group('report form', () {
    test('title required, 5–80 chars', () {
      expect(Validators.reportTitle(''), 'A title is required');
      expect(Validators.reportTitle('tap'), isNotNull);
      expect(Validators.reportTitle('Leaking tap in washroom'), isNull);
      expect(Validators.reportTitle('x' * 81), isNotNull);
    });

    test('description needs at least 15 characters', () {
      expect(Validators.reportDescription('Broken'), 'Add a bit more detail (at least 15 characters)');
      expect(Validators.reportDescription('Water is pooling by the door.'), isNull);
    });

    test('location must be chosen', () {
      expect(Validators.location(null), isNotNull);
      expect(Validators.location('Leadership Commons'), isNull);
    });

    test('exact location is required, 3–100 chars', () {
      expect(Validators.locationDetail(''), isNotNull);
      expect(Validators.locationDetail('ab'), isNotNull);
      expect(Validators.locationDetail('Angola class, food court'), isNull);
      expect(Validators.locationDetail('x' * 101), isNotNull);
    });
  });
}
