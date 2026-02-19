import 'package:eyesos/core/bloc/connectivity_bloc.dart';
import 'package:eyesos/core/bloc/connectivity_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityStatus>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state != ConnectivityStatus.checking)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 90,
                left: 16,
                child: _buildPill(state) ?? const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }

  Widget? _buildPill(ConnectivityStatus state) {
    if (state == ConnectivityStatus.connected) {
      return _Pill(
        icon: Icons.check_circle,
        label: 'Back online',
        color: Colors.green[600]!,
        autoDismiss: true,
      );
    }

    if (state == ConnectivityStatus.disconnected) {
      return _Pill(
        icon: Icons.wifi_off,
        label: 'No internet',
        color: Colors.red[700]!,
        autoDismiss: false,
      );
    }

    return null;
  }
}

class _Pill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool autoDismiss;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.autoDismiss,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoDismiss) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none, // add this
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.5, duration: 200.ms, curve: Curves.easeOut);
  }
}
