import 'package:get/get.dart';
import '../../../common/widgets/snakbar/snackbar.dart';
import '../../../utils/http/http_client.dart';
import '../models/review_model.dart';
import '../services/storage_service.dart';

class ReviewController extends GetxController {
  var isLoading = true.obs;
  var averageRating = 0.0.obs;
  var totalReviews = 0.obs;
  var currentIndex = 2.obs;
  var ratingDistribution = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  }.obs;

  var reviews = <Review>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Get arguments passed from performance screen
    if (Get.arguments != null) {
      averageRating.value = Get.arguments['rating'] ?? averageRating.value;
      totalReviews.value = Get.arguments['reviewCount'] ?? totalReviews.value;
    }

    fetchReviewsData();
  }

  Future<void> fetchReviewsData() async {
    try {
      isLoading.value = true;

      final token = StorageService.getAuthToken();
      if (token == null) {
        print("❌ User token not found for active rides API");
        return;
      }

      FHttpHelper.setAuthToken(token, useBearer: true);
      final response = await FHttpHelper.get('rating/userRating');

      if (response['userId'] != null) {
        final data = response;

        // Update average rating and total reviews from API
        averageRating.value = (data['avg_rating'] ?? 0.0).toDouble();
        totalReviews.value = data['total_ratings'] ?? 0;

        // Parse reviews
        final ratingsData = List<Map<String, dynamic>>.from(data['ratings'] ?? []);
        reviews.assignAll(ratingsData.map((reviewData) => Review.fromJson(reviewData)).toList());

        // Calculate rating distribution
        _calculateRatingDistribution();
      }
    } catch (e) {
      print('Error fetching reviews data: $e');
      FSnackbar.show(title: "Error", message: "Failed to load reviews", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateRatingDistribution() {
    // Reset distribution
    ratingDistribution.value = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (reviews.isEmpty) return;

    // Count each rating
    final ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final review in reviews) {
      final rating = review.rating.round();
      if (rating >= 1 && rating <= 5) {
        ratingCounts[rating] = ratingCounts[rating]! + 1;
      }
    }

    // Calculate percentages
    final total = reviews.length;
    if (total > 0) {
      ratingDistribution.value = {
        5: ((ratingCounts[5]! / total) * 100).round(),
        4: ((ratingCounts[4]! / total) * 100).round(),
        3: ((ratingCounts[3]! / total) * 100).round(),
        2: ((ratingCounts[2]! / total) * 100).round(),
        1: ((ratingCounts[1]! / total) * 100).round(),
      };
    }
  }
}