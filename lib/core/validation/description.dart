import 'package:formz/formz.dart';

enum DescriptionValidationError { tooShort }

class Description extends FormzInput<String, DescriptionValidationError> {
  const Description.pure() : super.pure('');
  const Description.dirty([super.value = '']) : super.dirty();

  static const int minLength = 5;

  @override
  DescriptionValidationError? validator(String value) {
    if (value.trim().isEmpty) {
      return null;
    } else if (value.trim().length < minLength) {
      return DescriptionValidationError.tooShort;
    }
    return null;
  }

  String? get errorMessage {
    if (error == DescriptionValidationError.tooShort) {
      return 'Description must be at least $minLength characters';
    }
    return null;
  }
}
