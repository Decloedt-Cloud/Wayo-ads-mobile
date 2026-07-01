import '../data/user_profile_remote_datasource.dart';

/// Maps Wayo-ads / Auth_Wayo profile name errors to stable codes.
String? profileNameErrorCode(UserProfileUpdateException error) {
  final code = error.code?.trim().toLowerCase();
  if (code == 'name_taken' || code == 'name_invalid') return code;

  final msg = error.message.trim().toLowerCase();
  if (msg == 'name_taken' || msg.contains('already taken')) {
    return 'name_taken';
  }
  if (msg == 'name_invalid' ||
      msg.contains('different alphabets') ||
      msg.contains('alphabets')) {
    return 'name_invalid';
  }
  return code;
}

bool isProfileNameFieldError(String? code) =>
    code == 'name_taken' || code == 'name_invalid';
