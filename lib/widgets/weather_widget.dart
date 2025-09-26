import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  final String temperature;
  final String condition;
  final IconData weatherIcon;
  final bool isLoading;

  const WeatherWidget({
    super.key,
    this.temperature = '--',
    this.condition = 'Loading...',
    this.weatherIcon = Icons.cloud_off,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    // Yükleniyor durumunda daha küçük bir widget göster
    if (isLoading) {
      return const SizedBox(
        width: 150,
        height: 60,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    // DEĞİŞİKLİK: Widget'ın genel dolgusunu (padding) azalttık.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DEĞİŞİKLİK: İkon boyutunu küçülttük.
          Icon(
            weatherIcon,
            size: 38, // 48'den küçültüldü
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.cyan.withOpacity(0.4),
                blurRadius: 15.0,
              ),
            ],
          ),
          // DEĞİŞİKLİK: İkon ve metin arasındaki boşluğu azalttık.
          const SizedBox(width: 12), // 16'dan küçültüldü
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DEĞİŞİKLİK: Sıcaklık metninin boyutunu küçülttük.
              Text(
                '$temperature°C',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontSize: 30, // 36'dan küçültüldü
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              // DEĞİŞİKLİK: Hava durumu metninin boyutunu küçülttük.
              Text(
                condition,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14, // 16'dan küçültüldü
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
