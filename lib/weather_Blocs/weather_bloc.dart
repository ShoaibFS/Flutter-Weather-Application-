import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:weather/Models/WeatherResponse';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    on<FetchWeather>(_onFetchWeather);
    on<FetchWeatherByCoordinates>(_onFetchWeatherByCoordinates);
  }

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading(isCurrentLocation: false));
    try {
      final coordinates = await fetchCoordinates(event.city);
      final double? lat = coordinates['lat'];
      final double? lon = coordinates['lon'];

      if (lat != null && lon != null) {
        final weather = await fetchWeather(lat, lon);
        emit(WeatherLoaded(
          city: event.city,
          temperature: weather.main.temp - 273.15,
          feels_like: weather.main.feelsLike - 273.15,
          isCurrentLocation: false,
          weatherIcon: weather.weather.isNotEmpty ? weather.weather[0].icon : null,
          locationName: weather.name,
          weatherdata: weather,
        ));
      } else {
        emit(WeatherError('Coordinates not found'));
      }
    } catch (e) {
      emit(WeatherError('Failed to fetch weather'));
    }
  }

  Future<void> _onFetchWeatherByCoordinates(
    FetchWeatherByCoordinates event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading(isCurrentLocation: true));
    try {
      final weather = await fetchWeather(event.lat, event.lon);
      emit(WeatherLoaded(
        city: weather.name,
        temperature: weather.main.temp - 273.15,
        feels_like: weather.main.feelsLike - 273.15,
        isCurrentLocation: true,
        weatherIcon: weather.weather.isNotEmpty ? weather.weather[0].icon : null,
        locationName: weather.name,
        weatherdata: weather,
      ));
    } catch (e) {
      emit(WeatherError('Failed to fetch weather for current location'));
    }
  }

  Future<Map<String, double?>> fetchCoordinates(String city) async {
    final apiKey = '9bc2b22daeadc23a152024e6d73a5e91';
    final response = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return {
          'lat': data[0]['lat'],
          'lon': data[0]['lon'],
          
        };
      } else {
        throw Exception('City not found');
      }
    } else {
      throw Exception('Failed to load coordinates');
    }
  }

  Future<WeatherResponse> fetchWeather(double lat, double lon) async {
    const apiKey = '9bc2b22daeadc23a152024e6d73a5e91';
    final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonMap = jsonDecode(response.body);
      WeatherResponse weatherResponse = WeatherResponse.fromJson(jsonMap);
      return weatherResponse;
    } else {
      throw Exception('Failed to load weather');
    }
  }
}
