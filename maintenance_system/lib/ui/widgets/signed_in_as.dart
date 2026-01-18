import 'package:flutter/material.dart';

class SignedInAs extends StatelessWidget {
  final String userLabel;

  const SignedInAs({
    super.key,
    required this.userLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.person,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          'Signed in as ',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          userLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
