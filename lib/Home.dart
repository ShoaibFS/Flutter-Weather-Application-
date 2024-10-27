import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_icons/weather_icons.dart'; // Import Weather Icons package
import 'package:weather/weather_Blocs/weather_bloc.dart';
import 'package:weather/weather_Blocs/weather_event.dart';
import 'package:weather/weather_Blocs/weather_state.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _cityController = TextEditingController();
  late WeatherBloc weatherBloc;

  // List of entered cities and their weather data
  Map<String, WeatherData> cityWeatherMap = {};
  WeatherData? currentLocationWeather; // Store current location weather

  @override
  void initState() {
    super.initState();
    weatherBloc = BlocProvider.of<WeatherBloc>(context);
    _loadSavedCities(); // Load previously saved cities
    _getCurrentLocation(); // Fetch weather for current location
  }

  // Load cities from SharedPreferences
  Future<void> _loadSavedCities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedCities = prefs.getStringList('savedCities');
    if (savedCities != null) {
      setState(() {
        cityWeatherMap = {
          for (var city in savedCities) city: WeatherData() // Initialize with empty weather data
        };
        // Trigger fetch weather for each saved city to update the data
        for (var city in savedCities) {
          weatherBloc.add(FetchWeather(city: city));
        }
      });
    }
  }

  // Save cities to SharedPreferences
  Future<void> _saveCities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setStringList('savedCities', cityWeatherMap.keys.toList());
    if (!success) {
      print('Failed to save cities');
    }
  }

  // Get current location and fetch weather
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        print('Location permission denied.');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      weatherBloc.add(FetchWeatherByCoordinates(lat: position.latitude, lon: position.longitude));
    } catch (e) {
      print('Error getting current position: $e');
    }
  }

  // Helper method to get weather icons dynamically based on the icon code from OpenWeatherMap
  IconData _getWeatherIcon(String? iconCode) {
    switch (iconCode) {
      case '01d':
        return WeatherIcons.day_sunny;
      case '01n':
        return WeatherIcons.night_clear;
      case '02d':
      case '02n':
        return WeatherIcons.cloudy;
      case '03d':
      case '03n':
        return WeatherIcons.cloud;
      case '04d':
      case '04n':
        return WeatherIcons.cloudy_windy;
      case '09d':
      case '09n':
        return WeatherIcons.rain;
      case '10d':
        return WeatherIcons.day_rain;
      case '10n':
        return WeatherIcons.night_rain;
      case '11d':
      case '11n':
        return WeatherIcons.thunderstorm;
      case '13d':
      case '13n':
        return WeatherIcons.snow;
      case '50d':
      case '50n':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.cloud;
    }
  }

  
  Widget _cityWeatherBox() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cityWeatherMap.entries.map((entry) {
          final city = entry.key;
          final weatherData = entry.value;
          return GestureDetector(
            onLongPress: () => _removeCity(city),
            onTap: () => _showWeatherBottomSheet(city, weatherData),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    city,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Icon(
                    WeatherIcons.day_sunny, 
                    size: 30,
                    color: Colors.orange,
                  ),
                  Text(
                    '${weatherData.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Method to remove city from the list
  void _removeCity(String city) {
    setState(() {
      cityWeatherMap.remove(city);
    });
    _saveCities(); // Save cities after removing one
  }

  void _showWeatherBottomSheet(String city, WeatherData weatherData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Weather Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text('City: $city'),
              Text('Temperature: ${weatherData.temperature.toStringAsFixed(1)}°C'),
              Text('Feels Like: ${weatherData.feelsLike.toStringAsFixed(1)}°C'),
            ],
          ),
        );
      },
    );
  }

  // Bottom sheet to add city
  void _showAddCityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _addCity();
                    },
                  ),
                ),
                onSubmitted: (value) => _addCity(), 
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Add city and fetch weather
  void _addCity() {
    String newCity = _cityController.text.trim();
    if (newCity.isNotEmpty) {
      weatherBloc.add(FetchWeather(city: newCity));
      Navigator.pop(context); 
    }
    _cityController.clear();
  }

  Widget forecastCard() {
    return Container(
      width: 60,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5),
          Icon(
            WeatherIcons.day_sunny,
            size: 30,
            color: Colors.orange,
          ),
          SizedBox(height: 5),
          Text(
            '19°C',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WeatherBloc, WeatherState>(
      listener: (context, state) {
        if (state is WeatherError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch weather: ${state.message}')),
          );
        } else if (state is WeatherLoaded) {
          if (state.isCurrentLocation) {
            setState(() {
              currentLocationWeather = WeatherData(
                temperature: state.temperature,
                feelsLike: state.feels_like,
              );
            });
          } else {
            setState(() {
              cityWeatherMap[state.city] = WeatherData(
                temperature: state.temperature,
                feelsLike: state.feels_like,
              );
            });
            _saveCities(); // Save cities when a new one is added
          }
        }
      },
      child: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          return Scaffold(
            body: Stack(
              children: [
                // Background Images (Sky and House)
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/Image.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/images/House2.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Main Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (currentLocationWeather != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Current Location',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    WeatherIcons.day_sunny,
                                    size: 50,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${currentLocationWeather!.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        _cityWeatherBox(), // Scrollable city weather
                      ],
                    ),
                  ),
                ),
                // Floating Action Button
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () { 
                      _showAddCityBottomSheet(); 
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, size: 28),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WeatherData {
  double temperature;
  double feelsLike;

  WeatherData({
    this.temperature = 0.0,
    this.feelsLike = 0.0,
  });
}
