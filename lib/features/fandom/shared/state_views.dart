import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyView({
    super.key,
    required this.text,
    this.icon = Icons.search_off,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.grey),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppTheme.grey),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pesan error ramah untuk pengguna.
String friendlyError(Object e) {
  final s = e.toString();
  if (s.contains('SocketException') ||
      s.contains('ClientException') ||
      s.contains('TimeoutException') ||
      s.contains('Failed host lookup')) {
    return 'Tidak ada koneksi';
  }
  return s.replaceFirst('Exception: ', '');
}

/// Dropdown dengan label.
class DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
