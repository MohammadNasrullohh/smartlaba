import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LegalDocumentSection {
  final String title;
  final List<String> paragraphs;

  const LegalDocumentSection({required this.title, required this.paragraphs});
}

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<LegalDocumentSection> sections;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.unbounded(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF162B5A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < sections.length; i++) ...[
                    Text(
                      sections[i].title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final paragraph in sections[i].paragraphs) ...[
                      Text(
                        paragraph,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.7,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (i != sections.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
