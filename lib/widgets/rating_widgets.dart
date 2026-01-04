import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/chef_review_service.dart';

const Color _primary = AppColors.primary;

/// Compact star rating display
class StarRating extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final Color color;
  final bool showValue;

  const StarRating({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 16,
    this.color = Colors.amber,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxStars, (index) {
          final starValue = index + 1;
          IconData icon;
          
          if (rating >= starValue) {
            icon = Icons.star;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          
          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}


/// Chef rating summary card with stats
class ChefRatingCard extends StatelessWidget {
  final String chefId;
  final bool compact;

  const ChefRatingCard({
    super.key,
    required this.chefId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChefRatingStats?>(
      future: ChefReviewService.getChefRatingStats(chefId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final stats = snapshot.data;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        if (compact) {
          return _buildCompact(stats);
        }

        return _buildFull(stats);
      },
    );
  }

  Widget _buildCompact(ChefRatingStats stats) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 4),
        Text(
          stats.averageRating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          ' (${stats.totalReviews})',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFull(ChefRatingStats stats) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Average rating
            Column(
              children: [
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                StarRating(rating: stats.averageRating, size: 20),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalReviews} تقييم',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Rating distribution
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final percentage = stats.getPercentage(star);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 35,
                          child: Text(
                            '${percentage.toInt()}%',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Inline rating badge for dish/chef cards
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool small;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(small ? 4 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: small ? 12 : 14,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          if (reviewCount != null) ...[
            Text(
              ' (${_formatCount(reviewCount!)})',
              style: TextStyle(
                fontSize: small ? 9 : 10,
                color: Colors.amber[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}


/// Large rating display for chef profile header
class ChefProfileRating extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final VoidCallback? onTap;

  const ChefProfileRating({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRating(rating: rating, size: 16),
                const SizedBox(height: 2),
                Text(
                  '$totalReviews تقييم',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_left, color: Colors.grey[400]),
            ],
          ],
        ),
      ),
    );
  }
}
