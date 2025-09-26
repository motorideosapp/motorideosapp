import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _apiKey = 'SENIN_OPENWEATHER_API_ANAHTARIN_BURAYA'; 
  final String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getWeatherData() async {
    if (_apiKey == 'SENIN_OPENWEATHER_API_ANAHTARIN_BURAYA' || _apiKey.isEmpty) {
      return _errorData('API Key not configured');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final url = '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'temperature': data['main']['temp'].round().toString(),
          'condition': data['weather'][0]['main'],
          'weatherIcon': _getWeatherIcon(data['weather'][0]['id']),
        };
      } else {
        return _errorData('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return _errorData(e.toString());
    }
  }

  Map<String, dynamic> _errorData(String error) {
    return {
      'temperature': '--',
      'condition': 'Error',
      'weatherIcon': Icons.error_outline,
    };
  }

  IconData _getWeatherIcon(int conditionCode) {
    if (conditionCode < 300) return Icons.thunderstorm;
    if (conditionCode < 400) return Icons.umbrella;
    if (conditionCode < 600) return Icons.beach_access;
    if (conditionCode < 700) return Icons.ac_unit;
    if (conditionCode < 800) return Icons.foggy;
    if (conditionCode == 800) return Icons.wb_sunny;
    if (conditionCode <= 804) return Icons.cloud;
    return Icons.help_outline;
  }
}
