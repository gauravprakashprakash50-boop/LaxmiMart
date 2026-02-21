import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader {
  static Widget productCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x261C1C1C),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFF0F0F0),
        highlightColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area skeleton — matches fixed 130px height
            Container(
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight tag
                  Container(
                    height: 10,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Product name line 1
                  Container(
                    height: 13,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Product name line 2
                  Container(
                    height: 13,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Container(
                        height: 14,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // ADD button placeholder
                      Container(
                        height: 36,
                        width: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget categoryCard() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container — 52x52
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 6),
            // Category name line 1
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            // Category name line 2
            Container(
              width: 36,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget categoryItem() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget listTile() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Container(
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  static Widget detailImage({double height = 300}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: Colors.white,
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFFF0F0F0),
      ),
    );
  }
}
