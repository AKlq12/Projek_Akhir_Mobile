import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/feedback_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/sqlite_service.dart';

/// Screen for users to provide suggestions and impressions (Saran & Kesan) for the TPM course.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _suggestionController = TextEditingController();
  final _impressionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<FeedbackModel> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    // Schedule fetch after first frame to ensure context is available for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFeedback();
    });
  }

  Future<void> _fetchFeedback() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        final feedback = await SQLiteService.instance.getFeedback(userId);
        if (mounted) {
          setState(() {
            _feedbackList = feedback;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching feedback: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    _impressionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final suggestion = _suggestionController.text.trim();
    final impression = _impressionController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mengirim feedback.')),
      );
      return;
    }

    if (suggestion.isEmpty || impression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi saran dan kesan Anda.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newFeedback = FeedbackModel(
        id: const Uuid().v4(),
        userId: userId,
        suggestion: suggestion,
        impression: impression,
        createdAt: DateTime.now(),
      );

      await SQLiteService.instance.insertFeedback(newFeedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saran dan kesan Anda telah disimpan secara lokal.'),
            backgroundColor: Colors.green,
          ),
        );
        _suggestionController.clear();
        _impressionController.clear();
        _fetchFeedback(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Saran & Kesan TPM',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFeedback,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Section
              _buildForm(colorScheme),

              const SizedBox(height: 40),

              // Feedback List Section
              Text(
                'RIWAYAT FEEDBACK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_feedbackList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada feedback yang dikirim.',
                          style: GoogleFonts.plusJakartaSans(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _feedbackList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final feedback = _feedbackList[index];
                    return _buildFeedbackCard(feedback, colorScheme);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 24),

        Text(
          'Apa pendapat Anda tentang mata kuliah TPM?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukan Anda sangat berharga bagi kami untuk meningkatkan kualitas pembelajaran ke depannya.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 32),

        // Kesan Input
        _buildInputField(
          label: 'Kesan',
          hint: 'Tuliskan kesan Anda selama mengikuti mata kuliah ini...',
          controller: _impressionController,
          maxLines: 4,
        ),

        const SizedBox(height: 20),

        // Saran Input
        _buildInputField(
          label: 'Saran',
          hint: 'Tuliskan saran perbaikan untuk mata kuliah ini...',
          controller: _suggestionController,
          maxLines: 4,
        ),

        const SizedBox(height: 40),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.onSurface,
              foregroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'KIRIM FEEDBACK',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFeedbackCard(FeedbackModel feedback, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(feedback.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.green.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeedbackItem('KESAN', feedback.impression, colorScheme),
          const SizedBox(height: 12),
          _buildFeedbackItem('SARAN', feedback.suggestion, colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildFeedbackItem(String label, String content, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
