import 'package:flutter/material.dart';
import 'memorization_page.dart';
import 'prayer_times_page.dart';
import 'quran_reader_page.dart';



class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  static const Color cream = Color(0xFFFFF8E1);
  static const Color gold = Color(0xFFC9A227);
  static const Color darkGold = Color(0xFF8B6B22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: gold,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "القرآن الکریم",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ==== آیه روز ====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: gold, width: 1),
              ),
              child: const Column(
                children: [
                  Text(
                    "آیه روز",
                    style: TextStyle(
                        color: darkGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "أَلا بِذِكْرِاللّهِ تَطْمَئِنُّ الْقُلُوبُ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "UthmanTaha",
                      fontSize: 32,
                      height: 1.8,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "(سوره رعد - آیه ۲۸)",
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),

            // ==== آیکون‌های اصلی ====
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [

                _buildMenuItem(
                  icon: Icons.psychology,
                  text: "حفظ قرآن",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) =>  MemorizationPage()),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.headphones,
                  text: "تلاوت قرآن",
                  onTap: () async {



                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuranReaderPage(),
                        ),
                      );

                  },
                ),

                _buildMenuItem(
                  icon: Icons.auto_awesome,
                  text: "اوقات شرعی",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrayerTimesPage(),
                      ),
                    );
                  },
                ),
              ]
            ),

            const SizedBox(height: 25),

            // ==== پیشرفت کاربر ====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6)
                ],
              ),
              child: Column(
                children: const [

                  Text(
                    "پیشرفت شما",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGold),
                  ),

                  SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [

                      Column(
                        children: [
                          Text(
                            "120",
                            style: TextStyle(
                                fontSize: 26,
                                color: gold,
                                fontWeight: FontWeight.bold),
                          ),
                          Text("آیات حفظ شده")
                        ],
                      ),

                      Column(
                        children: [
                          Text(
                            "8 🔥",
                            style: TextStyle(
                                fontSize: 26,
                                color: gold,
                                fontWeight: FontWeight.bold),
                          ),
                          Text("روزهای متوالی")
                        ],
                      ),

                      Column(
                        children: [
                          Text(
                            "مبتدی",
                            style: TextStyle(
                                fontSize: 22,
                                color: gold,
                                fontWeight: FontWeight.bold),
                          ),
                          Text("سطح")
                        ],
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

  Widget _buildMenuItem(
      {required IconData icon,
        required String text,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: darkGold),
            ),

            const SizedBox(height: 12),

            Text(
              text,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
