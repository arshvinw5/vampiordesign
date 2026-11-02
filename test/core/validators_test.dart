import 'package:flutter_test/flutter_test.dart';
import 'package:vampiordesigns/core/utils/password_strength.dart';
import 'package:vampiordesigns/core/utils/phone_formatter.dart';
import 'package:vampiordesigns/core/validation/validators.dart';

void main() {
  group('Validators.identifier', () {
    test(
      'required',
      () => expect(Validators.identifier('  '), 'Email or mobile number is required'),
    );
    test('accepts email', () => expect(Validators.identifier('a@b.co'), isNull));
    test('accepts phone with spaces/plus', () {
      expect(Validators.identifier('+94 77 123 4567'), isNull);
      expect(Validators.identifier('0771234567'), isNull);
    });
    test('rejects junk', () {
      expect(Validators.identifier('abc'), 'Enter a valid email or mobile number');
      expect(Validators.identifier('12345'), 'Enter a valid email or mobile number');
      expect(Validators.identifier('a@b.c'), 'Enter a valid email or mobile number');
    });
  });

  group('Validators.loginPassword', () {
    test('required', () => expect(Validators.loginPassword(''), 'Password is required'));
    test(
      'min 6',
      () => expect(Validators.loginPassword('12345'), 'Password must be at least 6 characters'),
    );
    test('ok', () => expect(Validators.loginPassword('123456'), isNull));
  });

  group('Validators.fullName', () {
    test('required', () => expect(Validators.fullName(''), 'Full name is required'));
    test('letters only', () => expect(Validators.fullName('J4ne Doe'), 'Use letters only'));
    test('first + last', () => expect(Validators.fullName('Jane'), 'Enter first and last name'));
    test('ok', () {
      expect(Validators.fullName('Jane Doe'), isNull);
      expect(Validators.fullName("Mary-Jane O'Neil"), isNull);
    });
  });

  group('Validators.email', () {
    test('required', () => expect(Validators.email(''), 'Email address is required'));
    test('invalid', () => expect(Validators.email('jane@'), 'Enter a valid email address'));
    test('ok', () => expect(Validators.email(' jane@doe.com '), isNull));
  });

  group('Validators.mobile', () {
    test('required', () => expect(Validators.mobile(''), 'Mobile number is required'));
    test('must start with 7 and be 9 digits', () {
      expect(Validators.mobile('612345678'), 'Enter a 9-digit number starting with 7');
      expect(Validators.mobile('7712345'), 'Enter a 9-digit number starting with 7');
    });
    test('ok', () => expect(Validators.mobile('771234567'), isNull));
  });

  group('Validators.newPassword', () {
    test('required', () => expect(Validators.newPassword(''), 'Password is required'));
    test('min 8', () => expect(Validators.newPassword('abc123'), 'At least 8 characters'));
    test('letters + number', () {
      expect(Validators.newPassword('abcdefgh'), 'Use letters and at least one number');
      expect(Validators.newPassword('12345678'), 'Use letters and at least one number');
    });
    test('ok', () => expect(Validators.newPassword('abcdefg1'), isNull));
  });

  group('Validators.confirmPassword', () {
    test(
      'required',
      () => expect(Validators.confirmPassword('', 'x'), 'Please confirm your password'),
    );
    test(
      'mismatch',
      () => expect(Validators.confirmPassword('abc', 'abd'), 'Passwords do not match'),
    );
    test('ok', () => expect(Validators.confirmPassword('abc', 'abc'), isNull));
  });

  group('LkMobile', () {
    test('parse strips 0, +94 and non-digits, caps at 9', () {
      expect(LkMobile.parse('077 123 4567'), '771234567');
      expect(LkMobile.parse('+94 77 123 4567'), '771234567');
      expect(LkMobile.parse('94771234567'), '771234567');
      expect(LkMobile.parse('7712345678999'), '771234567');
    });
    test('format groups 2-3-4', () {
      expect(LkMobile.format('7'), '7');
      expect(LkMobile.format('771'), '77 1');
      expect(LkMobile.format('771234'), '77 123 4');
      expect(LkMobile.format('771234567'), '77 123 4567');
    });
    test('input formatter reformats pasted text', () {
      final out = LkMobileInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '+94771234567'),
      );
      expect(out.text, '77 123 4567');
    });
  });

  test('PasswordStrength scoring', () {
    expect(PasswordStrength.of(''), PasswordStrength.none);
    expect(PasswordStrength.of('abc'), PasswordStrength.none);
    expect(PasswordStrength.of('abcdefgh'), PasswordStrength.weak);
    expect(PasswordStrength.of('abcdefg1'), PasswordStrength.fair);
    expect(PasswordStrength.of('Abcdefg1'), PasswordStrength.good);
    expect(PasswordStrength.of('Abcdefg1!'), PasswordStrength.strong);
  });
}
