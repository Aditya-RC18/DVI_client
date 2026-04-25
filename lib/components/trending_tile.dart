import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dreamventz/config/supabase_config.dart';

class TrendingTile extends StatelessWidget {
  final String title;
  final String price;
  final String imageFileName;

  const TrendingTile({
    super.key,
    required this.title,
    required this.price,
    required this.imageFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      // ✅ NO vertical margin — parent SizedBox(height: 210) is the constraint.
      // Horizontal spacing is handled by separatorBuilder in the parent ListView.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                SupabaseConfig.getImageUrl(imageFileName),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                /// Price
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 14,
                      color: Colors.black87,
                    ),
                    Text(
                      price,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Button
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/bookpackage');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0c1c2c),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "View Details",
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
