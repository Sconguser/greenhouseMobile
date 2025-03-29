import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

part 'user_model.g.dart';

enum Role { USER, ADMIN }

@freezed
abstract class User with _$User {
  const User._();
  factory User({
    required String username,
    required Role role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
