import 'package:flutter/material.dart';
import 'package:salon_app/screens/auth/login_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final ScrollController controller = ScrollController();
  double controllerOffset = 0.0;

  void move() {
    controller.animateTo(
      controllerOffset + 392,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  bool isRev = false;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      move();
      setState(() => controllerOffset += 392);
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      move();
      setState(() => controllerOffset += 392);
    });

    super.initState();
  }

  final List<String> imgUrl = [
    "https://thumbs.dreamstime.com/b/hairdresser-protective-mask-cutting-hair-curly-african-american-client-beauty-salon-free-space-195792989.jpg",
    "https://as2.ftcdn.net/v2/jpg/02/65/48/75/1000_F_265487582_hg1t4uvUI33fhRDTdxVyHTNjv0F5WdX4.jpg",
    "https://www.nextinsurance.com/wp-content/uploads/2018/05/shutterstock_256912663-802x454.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SingleChildScrollView(
            reverse: isRev,
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: imgUrl
                  .map((e) =>
                  BannerImages(height: height, width: width, image: e))
                  .toList(),
            ),
          ),

          SingleChildScrollView(
            reverse: isRev,
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.fastOutSlowIn,
                    height: 5,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: controllerOffset < 300
                          ? const Color(0xff721c80).withOpacity(0.8)
                          : Colors.grey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.fastOutSlowIn,
                    height: 5,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: 300 < controllerOffset && controllerOffset < 600
                          ? const Color(0xff721c80).withOpacity(0.8)
                          : Colors.grey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.fastOutSlowIn,
                    height: 5,
                    width: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: 600 < controllerOffset && controllerOffset < 800
                          ? const Color(0xff721c80).withOpacity(0.8)
                          : Colors.grey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          const Text(
            "Chuyên gia tạo mẫu chuyên nghiệp",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            "Chọn kiểu tóc bạn thích, đặt lịch nhanh chóng\nvà trải nghiệm dịch vụ tốt nhất tại salon.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),

          GestureDetector(
            onTap: () {
              // ✅ Bước 1: chuyển sang trang đăng nhập
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              height: 50,
              width: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff721c80),
                    Color.fromARGB(255, 196, 103, 169),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "Bắt đầu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BannerImages extends StatelessWidget {
  final String image;
  final double height;
  final double width;

  const BannerImages({
    super.key,
    required this.image,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.8 * (height / 3),
      width: width,
      child: Image.network(image, fit: BoxFit.cover),
    );
  }
}
