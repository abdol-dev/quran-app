import 'package:flutter/material.dart';

class NewLessonPage extends StatelessWidget {
  const NewLessonPage({Key? key}) : super(key: key);

  static const Color cream = Color(0xFFFFF8E1);
  static const Color gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text("درس جدید", style: TextStyle(color: Colors.white)),
        backgroundColor: gold,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _buildDropdown("انتخاب سوره"),
            _buildDropdown("انتخاب آیه"),

            const SizedBox(height: 20),

            _buildDropdown("انتخاب قاری"),
            _buildDropdown("تعداد تکرار"),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text("شروع تلاوت"),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(18),
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gold)),
              child: const Column(
                children: [

                  Text(
                    "بِسْمِ ٱللَّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
                    style: TextStyle(fontSize: 18, height: 1.7),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  Text(
                    "پس از اتمام تلاوت، شما بخوانید",
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 10),

                  Icon(Icons.mic, size: 40, color: gold),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField(
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        hint: Text(hint),
        items: const [],
        onChanged: (value) {},
      ),
    );
  }
}
