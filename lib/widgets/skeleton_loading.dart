import 'package:flutter/material.dart';

class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const SizedBox(),
    );
  }
}

class AnimeCardSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const AnimeCardSkeleton({
    super.key,
    this.width = 140,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image skeleton
            Expanded(
              child: SkeletonLoading(
                height: height * 0.7,
                borderRadius: 0,
              ),
            ),

            // Title and rating skeleton
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoading(
                    width: width * 0.8,
                    height: 14,
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoading(
                    width: width * 0.5,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimeListItemSkeleton extends StatelessWidget {
  const AnimeListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SkeletonLoading(
        width: 40,
        height: 60,
        borderRadius: 8,
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SkeletonLoading(
          height: 16,
        ),
      ),
      subtitle: SkeletonLoading(
        width: 100,
        height: 14,
      ),
    );
  }
}

class AnimeDetailSkeleton extends StatelessWidget {
  const AnimeDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image skeleton
        SkeletonLoading(
          height: 250,
          borderRadius: 0,
        ),

        // Info bar skeleton
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (index) => Column(
                children: [
                  SkeletonLoading(
                    width: 24,
                    height: 24,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoading(
                    width: 60,
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tabs skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SkeletonLoading(
            height: 40,
          ),
        ),

        const SizedBox(height: 16),

        // Content skeleton
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Genres skeleton
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  5,
                  (index) => SkeletonLoading(
                    width: 80,
                    height: 32,
                    borderRadius: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title skeleton
              SkeletonLoading(
                width: 150,
                height: 24,
              ),

              const SizedBox(height: 16),

              // Description skeleton
              Column(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SkeletonLoading(
                      height: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
