import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class Carousel extends StatelessWidget {
  final VoidCallback? onGoBooking;
  const Carousel({super.key, this.onGoBooking});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: [
        _Slide(
          title: "Khung giờ hoạt động",
          subtitle: "8AM - 10PM",
          buttonText: "Giảm đến 20%",
          imageUrl:
          "https://images.squarespace-cdn.com/content/v1/5e867df9747b0e555c337eef/1589945925617-4NY8TG8F76FH1O0P46FW/Kampaamo-helsinki-hair-design-balayage-hiustenpidennys-varjays.png",
          onTap: null,
        ),

        // Slide 2: bấm để chuyển sang đặt lịch
        _Slide(
          title: "Đặt lịch hẹn\nnhanh chóng",
          subtitle: "Ngay bây giờ",
          buttonText: "Đặt lịch tại đây",
          imageUrl:
          "https://img.grouponcdn.com/bynder/2sLSquS1xGWk4QjzYuL7h461CDsJ/2s-2048x1229/v1/sc600x600.jpg",
          onTap: onGoBooking,
        ),
      ],
      options: CarouselOptions(
        disableCenter: true,
        enableInfiniteScroll: false,
        height: 180.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 10 / 8,
        autoPlayCurve: Curves.easeInOut,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.78,
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String imageUrl;
  final VoidCallback? onTap;

  const _Slide({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 8.0;

    Widget content = Container(
      width: 400,
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff721c80),
            Color.fromARGB(255, 196, 103, 169),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          // Text + button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Btn(text: buttonText),
                ],
              ),
            ),
          ),

          // Image (luôn có chỗ hiển thị)
          SizedBox(
            width: 120,
            height: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(radius),
                bottomRight: Radius.circular(radius),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Nếu có onTap thì bọc InkWell cho click + vẫn giữ bo góc
    if (onTap != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

class Btn extends StatelessWidget {
  final String text;
  const Btn({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(12),
      height: 40,
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: const LinearGradient(
          colors: [
            Color(0xff721c80),
            Color.fromARGB(255, 196, 103, 169),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
