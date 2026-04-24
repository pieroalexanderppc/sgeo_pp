import 'package:flutter/material.dart';
import '../../../user/profile/views/profile_view.dart' as userview;

class AdminProfileView extends StatelessWidget {
  final String userId;
  final String userName;
  final String userRole;

  const AdminProfileView({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return userview.ProfileView(
      userId: userId,
      userName: userName,
      userRole: userRole,
    );
  }
}
