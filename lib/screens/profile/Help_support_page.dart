import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _supportEmail = 'support@dreamventz.com';

  static const _faqs = [
    (
      q: 'How do I book a service?',
      a:
          'Go to the Home page, browse categories, select a vendor and tap "Book Now". Follow the steps to confirm your booking.',
    ),
    (
      q: 'Can I cancel or reschedule a booking?',
      a:
          'Yes. Go to My Orders, select the booking and tap "Cancel" or "Reschedule". Cancellations must be made 24 hours before the event.',
    ),
    (
      q: 'How do I track my order?',
      a:
          'Open My Orders from your profile. Each booking shows its current status in real time.',
    ),
    (
      q: 'How do I add a vendor to my wishlist?',
      a:
          'Tap the heart icon on any vendor card. Access your saved vendors from Profile → Wishlist.',
    ),
    (
      q: 'How do I update my profile?',
      a:
          'Go to Profile and tap "Edit profile". You can update your name, address, phone and profile photo.',
    ),
    (
      q: 'I forgot my password. What should I do?',
      a:
          'On the login screen tap "Forgot password". Enter your email and we\'ll send a reset link.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F3F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.urbanist(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildContactCard(context),
            const SizedBox(height: 12),
            _buildFaqCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Contact actions ────────────────────────────────────────────────────────

  Widget _buildContactCard(BuildContext context) {
    return _SectionCard(
      title: 'Get in Touch',
      children: [
        _ActionTile(
          icon: Icons.email_outlined,
          label: 'Email Support',
          subtitle: _supportEmail,
          iconBgColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF1565C0),
          onTap: () => _launchEmail(),
        ),
        Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
        _ActionTile(
          icon: Icons.bug_report_outlined,
          label: 'Report a Problem',
          subtitle: 'Tell us what went wrong',
          iconBgColor: const Color(0xFFFCE4EC),
          iconColor: const Color(0xFFE53935),
          onTap: () => _showReportSheet(context),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=DreamVentz Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportProblemSheet(),
    );
  }

  // ── FAQ ────────────────────────────────────────────────────────────────────

  Widget _buildFaqCard() {
    return _SectionCard(
      title: 'Frequently Asked Questions',
      children: _faqs
          .map((faq) => _FaqTile(question: faq.q, answer: faq.a))
          .toList(),
    );
  }
}

// ── Report Problem Bottom Sheet ──────────────────────────────────────────────

class _ReportProblemSheet extends StatefulWidget {
  const _ReportProblemSheet();

  @override
  State<_ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<_ReportProblemSheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: _sent ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Report a Problem',
          style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Describe the issue and we\'ll get back to you.',
          style:
              GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _controller,
          maxLines: 5,
          style: GoogleFonts.urbanist(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Describe your problem here...',
            hintStyle:
                GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[400]),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF4A7DC8), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0c1c2c),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Submit Report',
                    style: GoogleFonts.urbanist(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_outline,
              size: 36, color: Colors.green[600]),
        ),
        const SizedBox(height: 16),
        Text(
          'Report Submitted',
          style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you! Our team will review your report and get back to you.',
          textAlign: TextAlign.center,
          style:
              GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0c1c2c),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Done',
                style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem')),
      );
      return;
    }
    setState(() => _sending = true);

    // Send via email
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@dreamventz.com',
      query:
          'subject=Problem Report - DreamVentz&body=${Uri.encodeComponent(_controller.text.trim())}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);

    setState(() {
      _sending = false;
      _sent = true;
    });
  }
}

// ── FAQ Tile ─────────────────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.help_outline,
                      size: 20, color: Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.answer,
              style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5),
            ),
          ),
        Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]),
      ],
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBgColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor ?? Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(icon, size: 20, color: iconColor ?? Colors.grey[700]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                  Text(subtitle,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}