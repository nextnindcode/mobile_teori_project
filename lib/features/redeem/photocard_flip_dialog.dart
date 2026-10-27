import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'eclipse_card_model.dart';

class PhotocardFlipDialog extends StatefulWidget {
  final EclipseCard card;
  final bool isOwned;

  const PhotocardFlipDialog({
    super.key,
    required this.card,
    required this.isOwned,
  });

  @override
  State<PhotocardFlipDialog> createState() => _PhotocardFlipDialogState();
}

class _PhotocardFlipDialogState extends State<PhotocardFlipDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    )..addListener(() {
        if (_animation.value >= 0.5 && !_showBack) {
          setState(() => _showBack = true);
        } else if (_animation.value < 0.5 && _showBack) {
          setState(() => _showBack = false);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.eclipseViolet.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.eclipseViolet),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, size: 14, color: AppTheme.coolCyan),
                    const SizedBox(width: 4),
                    Text(
                      _showBack ? 'Sisi Belakang (Holo)' : 'Ketuk kartu untuk Flip',
                      style: const TextStyle(
                        color: AppTheme.coolCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final angle = _animation.value * math.pi;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015) // perspective
                    ..rotateY(angle),
                  alignment: FractionalOffset.center,
                  child: _showBack
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: FractionalOffset.center,
                          child: _buildCardBack(),
                        )
                      : _buildCardFront(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.card.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.isOwned
                ? 'Koleksi Digital Resmi Terverifikasi'
                : 'Photocard Eksklusif EclipseVerse',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSubtle, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.eclipseViolet.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.card.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppTheme.surfaceElevated,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.coronaGold, width: 1),
                ),
                child: const Text(
                  'ECLIPSE OFFICIAL',
                  style: TextStyle(
                    color: AppTheme.coronaGold,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Limited First Edition Photocard',
                    style: TextStyle(
                      color: AppTheme.coolCyan,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 260,
      height: 380,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF2E1A47),
            Color(0xFF15102A),
            Color(0xFF090714),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.coronaGold.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.coronaGold.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.coronaGold, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.coronaGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOLO VERIFIED',
                  style: TextStyle(
                    color: AppTheme.coronaGold,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, color: AppTheme.coronaGold, size: 20),
            ],
          ),
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.coolCyan, width: 2),
                  gradient: const LinearGradient(
                    colors: [AppTheme.eclipseViolet, AppTheme.coolCyan],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.brightness_2, size: 38, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ECLIPSEVERSE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DIGITAL COLLECTIBLE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Card ID', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('#EV-${widget.card.id.toString().padLeft(4, '0')}',
                        style: const TextStyle(color: AppTheme.coolCyan, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nilai Koleksi', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text('${widget.card.cost} Points',
                        style: const TextStyle(color: AppTheme.coronaGold, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Kepemilikan', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(
                      widget.isOwned ? 'Tersimpan di Koleksi' : 'Tersedia di Store',
                      style: TextStyle(
                        color: widget.isOwned ? AppTheme.success : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

