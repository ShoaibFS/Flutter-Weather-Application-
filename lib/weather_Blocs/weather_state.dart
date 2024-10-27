import 'package:equatable/equatable.dart';

abstract class WeatherState extends Equatable {
  @override
  List<Object> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {
  final bool isCurrentLocation;

  WeatherLoading({required this.isCurrentLocation});

  @override
  List<Object> get props => [isCurrentLocation];
}

class WeatherLoaded extends WeatherState {
  final String city;
  final double temperature;
  final double feels_like;
  final bool isCurrentLocation;
  final String? weatherIcon;
  final String? locationName;
  final dynamic weatherdata;
  final String? weatherCondition;

  WeatherLoaded({
    required this.city,
    required this.temperature,
    required this.feels_like,
    required this.isCurrentLocation,
    this.weatherIcon,
    this.locationName,
    this.weatherdata,
    this.weatherCondition,
  });

  @override
  List<Object> get props => [
        city,
        temperature,
        feels_like,
        isCurrentLocation,
        if (weatherIcon != null) weatherIcon!,
        if (locationName != null) locationName!,
        if (weatherdata != null) weatherdata!,
        if (weatherCondition != null) weatherCondition!,
      ];
}

class WeatherError extends WeatherState {
  final String message;

  WeatherError(this.message);

  @override
  List<Object> get props => [message];
}
