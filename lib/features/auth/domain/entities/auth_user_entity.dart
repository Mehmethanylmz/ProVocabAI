import 'package:equatable/equatable.dart';

class AuthUserEntity extends Equatable {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;

  const AuthUserEntity({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
  });

  @override
  List<Object?> get props => [uid, displayName, email, photoUrl, isAnonymous];
}
