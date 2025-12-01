import 'package:doorcab/feautures/shared/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import '../../rides/driver/screens/reuseable_widgets/driver_bottom_nav.dart';
import '../controllers/review_controller.dart';
import '../models/review_model.dart';

class ReviewScreen extends StatelessWidget {
  ReviewScreen({super.key});

  final ReviewController controller = Get.put(ReviewController());
  final role = StorageService.getRole();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    /// Base reference (iPhone 16 Pro Max)
    final baseWidth = 440.0;
    final baseHeight = 956.0;

    double sw(double w) => w * screenWidth / baseWidth;
    double sh(double h) => h * screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        final loading = controller.isLoading.value;

        return Stack(
          children: [
            /// Main Content
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: sw(16),
                vertical: sh(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// App Bar Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Back Arrow
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          "assets/icons/Arrow.svg",
                          width: sw(28),
                          height: sh(28),
                        ),
                      ),

                      /// Title
                      Text(
                        "My Reviews",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: sw(18),
                          color: Colors.black,
                        ),
                      ),

                      /// Empty space for balance
                      SizedBox(width: sw(28)),
                    ],
                  ),

                  SizedBox(height: sh(20)),

                  /// Rating Header
                  _buildRatingHeader(sw, sh, screenWidth, baseWidth),

                  SizedBox(height: sh(20)),

                  /// Reviews List
                  ...controller.reviews
                      .map((review) => _buildReviewCard(review, sw, sh, screenWidth))
                      .toList(),

                  SizedBox(height: sh(80)), // Bottom padding
                ],
              ),
            ),

            /// Custom Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: (role == "Driver" || role == "driver") ? DriverBottomNav(
                currentIndex: 2, // Performance is active (same as performance screen)
                isRequestsListActive: false,
              ) : SizedBox(),
            ),

            /// Loader Overlay
            if (loading)
              Container(
                height: screenHeight,
                width: screenWidth,
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildRatingHeader(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Obx(() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Left: Rating number + stars + total reviews
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              controller.averageRating.value.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontWeight: FontWeight.w900,
                fontSize: sw(40),
                height: 1.2,
                color: Colors.black,
              ),
            ),
            SizedBox(height: sh(4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (i) => Icon(
                  i < controller.averageRating.value.floor()
                      ? Icons.star
                      : (i < controller.averageRating.value
                      ? Icons.star_half
                      : Icons.star_border),
                  size: sw(20),
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: sh(4)),
            Text(
              '${controller.totalReviews.value} Reviews',
              style: TextStyle(
                color: Colors.black54,
                fontSize: sw(15),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),

        SizedBox(width: sw(30)),

        /// Right: Rating Distribution
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: _buildRatingDistribution(sw, sh, screenWidth, baseWidth),
          ),
        ),
      ],
    ));
  }

  Widget _buildRatingDistribution(
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      double baseWidth,
      ) {
    return Obx(() => Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: controller.ratingDistribution.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: sh(3)),
          child: Row(
            children: [
              SizedBox(
                width: sw(22),
                child: Text(
                  entry.key.toString(),
                  style: TextStyle(
                    fontSize: sw(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: sw(5)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(sw(4)),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.black,
                    minHeight: sh(9),
                  ),
                ),
              ),
              SizedBox(width: sw(10)),
              Text(
                '${entry.value}%',
                style: TextStyle(
                  fontSize: sw(13),
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ));
  }

  Widget _buildReviewCard(
      Review review,
      double Function(double) sw,
      double Function(double) sh,
      double screenWidth,
      ) {
    return GestureDetector(
      onTap: () {
        // Handle review tap if needed
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: sh(8)),
        padding: EdgeInsets.all(sw(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(sw(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: screenWidth < 400 ? sw(20) : sw(24),
              backgroundImage: NetworkImage(review.imageUrl),
            ),
            SizedBox(width: sw(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: sw(15),
                    ),
                  ),
                  SizedBox(height: sh(2)),
                  Text(
                    review.date,
                    style: TextStyle(
                      fontSize: sw(12),
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: sh(6)),
                  Row(
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < review.rating
                            ? Icons.star
                            : Icons.star_border_outlined,
                        size: sw(18),
                      ),
                    ),
                  ),
                  SizedBox(height: sh(6)),
                  if (review.comment.isNotEmpty) ...[
                    Text(
                      review.comment,
                      style: TextStyle(
                        fontSize: sw(14),
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: sh(6)),
                  ],
                  if (review.ratingTags.isNotEmpty) ...[
                    Wrap(
                      spacing: sw(6),
                      runSpacing: sh(4),
                      children: review.ratingTags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: sw(8),
                            vertical: sh(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(sw(12)),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: sw(10),
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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