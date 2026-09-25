import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Interactive 5-star row used inside entry dialogs.
/// 5 = went very well, 1 = refused / very poor.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 32,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= value;
        return IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(starValue),
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: color,
            size: size,
          ),
        );
      }),
    );
  }
}

/// Read-only 5-star row for tiles / journal rows. `rating == null` means
/// "not logged today" and renders an all-outline row; callers pair this
/// with the muted "Günlük veri girişi yapılmadı" caption themselves.
class StarRatingDisplay extends StatelessWidget {
  final int? rating;
  final double size;
  final Color color;

  const StarRatingDisplay({
    super.key,
    this.rating,
    this.size = 18,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final filledCount = rating ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < filledCount;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: color,
          size: size,
        );
      }),
    );
  }
}
