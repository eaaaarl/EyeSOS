import 'package:eyesos/features/auth/presentation/bloc/session_bloc.dart';
import 'package:eyesos/features/auth/presentation/bloc/session_event.dart';
import 'package:eyesos/features/auth/presentation/bloc/signin_bloc.dart';
import 'package:eyesos/features/auth/presentation/bloc/signin_event.dart';
import 'package:eyesos/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: GoogleFonts.inter(fontSize: 15, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<SigninBloc>().add(const SigninResetState());
            context.read<SessionBloc>().add(AuthLoggedOut());
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Logout',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
