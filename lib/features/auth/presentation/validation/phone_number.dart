import 'package:formz/formz.dart';

enum PhoneNumberValidationError { empty, invalid }

class PhoneNumber extends FormzInput<String, PhoneNumberValidationError> {
  const PhoneNumber.pure() : super.pure('');
  const PhoneNumber.dirty([super.value = '']) : super.dirty();

  @override
  PhoneNumberValidationError? validator(String value) {
    if (value.isEmpty) return PhoneNumberValidationError.empty;
    if (value.length < 10) return PhoneNumberValidationError.invalid;
    return null;
  }
}
