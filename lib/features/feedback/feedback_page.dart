import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

import '../fandom/shared/state_views.dart';
import 'feedback_service.dart';

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
  bool _loadingReviews = true;
  String? _ratingErr, _impressionErr, _suggestionErr, _reviewsError;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() { super.initState(); _loadReviews(); }

  @override
  void dispose() { _impression.dispose(); _suggestion.dispose(); super.dispose(); }

  Future<void> _loadReviews() async {
    setState(() { _loadingReviews = true; _reviewsError = null; });
    try {
      final reviews = await FeedbackService.fetchReviews();
      if (!mounted) return;
      setState(() { _reviews = reviews; _loadingReviews = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _reviewsError = friendlyError(e); _loadingReviews = false; });
    }
  }

  bool _validate() {
    final imp = _impression.text.trim();
    final sug = _suggestion.text.trim();
    setState(() {
      _ratingErr = _rating < 1 ? 'Pilih rating 1-5' : null;
      _impressionErr = imp.isEmpty ? 'Kesan wajib diisi' : (imp.length > 500 ? 'Maksimal 500 karakter' : null);
      _suggestionErr = sug.isEmpty ? 'Saran wajib diisi' : (sug.length > 500 ? 'Maksimal 500 karakter' : null);
    });
    return _ratingErr == null && _impressionErr == null && _suggestionErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _sending = true);
    try {
      await FeedbackService.submit(rating: _rating, impression: _impression.text.trim(), suggestion: _suggestion.text.trim());
      if (!mounted) return;
      _impression.clear(); _suggestion.clear(); setState(() => _rating = 0);
      showSnack(context, 'Terima kasih! Feedback berhasil dikirim.');
      await _loadReviews();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Widget _buildReviews() {
    if (_loadingReviews) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    if (_reviewsError != null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_reviewsError!, style: const TextStyle(color: AppTheme.error)),
      TextButton.icon(onPressed: _loadReviews, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
    ]);
    if (_reviews.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Belum ada review. Jadilah yang pertama memberikan saran dan kesan!'));
    return Column(children: _reviews.map((review) {
      final name = (review['user_name'] ?? 'Pengguna').toString();
      final rating = int.tryParse(review['rating'].toString()) ?? 0;
      final impression = (review['impression'] ?? '').toString();
      final suggestion = (review['suggestion'] ?? '').toString();
      final createdAt = (review['created_at'] ?? '').toString();
      return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)), Text('⭐ ' + rating.toString() + '/5')]),
        if (createdAt.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(createdAt, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 10), Text('Kesan', style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(impression),
        const SizedBox(height: 10), Text('Saran', style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(suggestion),
      ])));
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Saran & Kesan')), body: ListView(padding: const EdgeInsets.all(AppTheme.spacingLarge), children: [
      Text('Mata kuliah Pemrograman Aplikasi Mobile', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppTheme.spacingMedium), Text('Rating', style: Theme.of(context).textTheme.titleMedium),
      Row(children: [for (var i = 1; i <= 5; i++) IconButton(onPressed: _sending ? null : () => setState(() => _rating = i), icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: AppTheme.accentYellow, size: 36))]),
      if (_ratingErr != null) Text(_ratingErr!, style: const TextStyle(color: AppTheme.error)),
      const SizedBox(height: AppTheme.spacingMedium),
      TextField(controller: _impression, maxLines: 4, maxLength: 500, decoration: InputDecoration(labelText: 'Kesan', errorText: _impressionErr)),
      const SizedBox(height: AppTheme.spacingSmall),
      TextField(controller: _suggestion, maxLines: 4, maxLength: 500, decoration: InputDecoration(labelText: 'Saran', errorText: _suggestionErr)),
      const SizedBox(height: AppTheme.spacingMedium),
      ElevatedButton(onPressed: _sending ? null : _submit, child: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kirim')),
      const SizedBox(height: 28), const Divider(),
      Row(children: [Expanded(child: Text('Review yang sudah masuk', style: Theme.of(context).textTheme.titleLarge)), IconButton(tooltip: 'Muat ulang review', onPressed: _loadReviews, icon: const Icon(Icons.refresh))]),
      const SizedBox(height: 12), _buildReviews(),
    ]));
  }
}
