import 'package:flutter/material.dart';
import '../../../user/profile/views/profile_view.dart' as userview;

class PoliceProfileView extends StatelessWidget {
  final String userId;
  final String userName;
  final String userRole;

  const PoliceProfileView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Reutilizamos toda la vista madura y funcional del Ciudadano
    return userview.ProfileView(
      userId: userId,
      userName: userName,
      userRole: userRole,
    );
  }
}
