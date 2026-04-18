import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final bool showOnline;
  final bool isOnline;
  final VoidCallback? onTap;
  final int? colorIndex;

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 46,
    this.showOnline = false,
    this.isOnline = false,
    this.onTap,
    this.colorIndex,
  });

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  Color get _bgColor {
    final idx = (colorIndex ?? name.hashCode.abs()) % AppConstants.avatarColors.length;
    return Color(AppConstants.avatarColors[idx]);
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: photoUrl!,
        imageBuilder: (ctx, provider) => Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: provider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (_, __) => _buildInitialsAvatar(),
        errorWidget: (_, __, ___) => _buildInitialsAvatar(),
      );
    } else {
      avatar = _buildInitialsAvatar();
    }

    Widget result = avatar;

    if (showOnline) {
      result = Stack(children: [
        avatar,
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: size * 0.26, height: size * 0.26,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.online : AppColors.offline,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
            ),
          ),
        ),
      ]);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _bgColor),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
