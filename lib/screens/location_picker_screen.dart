import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selectedLocation = const LatLng(37.42796133580664, -122.085749655962); // Google HQ
  // ignore: unused_field
  GoogleMapController? _mapController;
  bool _isReversing = false;
  String? _selectedAddress;

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() {
      _isReversing = true;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'latlng=${location.latitude},${location.longitude}&'
        'key=${AppConfig.mapsApiKey}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          setState(() {
            _selectedAddress = data['results'][0]['formatted_address'];
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    } finally {
      setState(() {
        _isReversing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedAddress != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'description': _selectedAddress,
                  'latitude': _selectedLocation.latitude,
                  'longitude': _selectedLocation.longitude,
                });
              },
              child: const Text(
                'SELECT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _reverseGeocode(_selectedLocation);
            },
            onTap: (location) {
              setState(() {
                _selectedLocation = location;
              });
              _reverseGeocode(location);
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.hybrid,
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isReversing)
                      const LinearProgressIndicator()
                    else
                      Text(
                        _selectedAddress ?? 'Tap on map to select roof',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap exactly on the roof for best accuracy',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _selectedAddress == null || _isReversing
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'description': _selectedAddress,
                                'latitude': _selectedLocation.latitude,
                                'longitude': _selectedLocation.longitude,
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Confirm Location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
