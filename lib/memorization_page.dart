import 'package:flutter/material.dart';
import 'new_lesson_page.dart';
import 'free_review_page.dart';

class MemorizationPage extends StatelessWidget {
  const MemorizationPage({Key? key}) : super(key: key);

  static const Color cream = Color(0xFFFFF8E1);
  static const Color gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: gold,
        centerTitle: true,
        title: const Text("حفظ قرآن", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _buildItem(
              context,
              icon: Icons.menu_book,
              title: "درس جدید",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NewLessonPage()));
              },
            ),

            _buildItem(
              context,
              icon: Icons.replay,
              title: "تکرار محفوظات",
              onTap: () {},
            ),

            _buildItem(
              context,
              icon: Icons.gps_fixed,
              title: "مراجعه آزاد",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FreeReviewPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: gold, size: 30),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 18)
            ],
          ),
        ),
      ),
    );
  }
}
