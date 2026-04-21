import 'package:equatable/equatable.dart';

final class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.name,
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String? firstName;
  final String? name;
  final String? avatarUrl;

  String get displayFirstName {
    final f = firstName?.trim();
    if (f != null && f.isNotEmpty) {
      return f;
    }
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      return n.split(' ').first;
    }
    return '';
  }

  @override
  List<Object?> get props => [id, email, firstName, name, avatarUrl];
}
