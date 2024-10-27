// weather_event.dart

import 'package:equatable/equatable.dart';

abstract class WeatherEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchWeather extends WeatherEvent {
  final String city;

  FetchWeather({required this.city});

  @override
  List<Object> get props => [city];
}

class FetchWeatherByCoordinates extends WeatherEvent {
  final double lat;
  final double lon;

  FetchWeatherByCoordinates({required this.lat, required this.lon});

  @override
  List<Object> get props => [lat, lon];
}
