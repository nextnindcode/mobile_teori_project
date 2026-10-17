import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import '../fandom/shared/state_views.dart';
import 'feedback_service.dart';

/// Tab 2 di /shell (Saran & Kesan).
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _impression = TextEditingController();
  final _suggestion = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  String? _ratingErr, _impressionErr, _suggestionErr;

  @override
  void dispose() {
    _impression.dispose();
    _suggestion.dispose();
    super.dispose();
  }

  bool _validate() {
    final imp = _impression.text.trim();
    final sug = _suggestion.text.trim();
    setState(() {
      _ratingErr = _rating < 1 ? 'Pilih rating 1-5' : null;
      _impressionErr = imp.isEmpty
          ? 'Kesan wajib diisi'
          : (imp.length > 500 ? 'Maksimal 500 karakter' : null);
      _suggestionErr = sug.isEmpty
          ? 'Saran wajib diisi'
          : (sug.length > 500 ? 'Maksimal 500 karakter' : null);
    });
    return _ratingErr == null &&
        _impressionErr == null &&
        _suggestionErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _sending = true);
    try {
      await FeedbackService.submit(
        rating: _rating,
        impression: _impression.text.trim(),
        suggestion: _suggestion.text.trim(),
      );
      if (!mounted) return;
      _impression.clear();
      _suggestion.clear();
      setState(() => _rating = 0);
      showSnack(context, 'Terima kasih');
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saran & Kesan')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        children: [
          Text(
            'Mata kuliah Pemrograman Aplikasi Mobile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text('Rating', style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: _sending
                      ? null
                      : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.accentYellow,
                    size: 36,
                  ),
                ),
            ],
          ),
          if (_ratingErr != null)
            Text(_ratingErr!, style: const TextStyle(color: AppTheme.error)),
          const SizedBox(height: AppTheme.spacingMedium),
          TextField(
            controller: _impression,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Kesan',
              errorText: _impressionErr,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          TextField(
            controller: _suggestion,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Saran',
              errorText: _suggestionErr,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}
