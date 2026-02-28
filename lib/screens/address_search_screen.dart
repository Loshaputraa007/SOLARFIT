import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'analysis_loading_screen.dart';
import 'location_picker_screen.dart';
import '../config.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({Key? key}) : super(key: key);

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _addressController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Using Google Geocoding API for address search
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?'
        'address=${Uri.encodeComponent(query)}&'
        'key=${AppConfig.mapsApiKey}'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          setState(() {
            _predictions = (data['results'] as List).take(5).map((result) {
              return {
                'description': result['formatted_address'],
                'latitude': result['geometry']['location']['lat'],
                'longitude': result['geometry']['location']['lng'],
              };
            }).toList();
            _isSearching = false;
          });
        } else {
          setState(() {
            _predictions = [];
            _errorMessage = 'No addresses found. Try a different search.';
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching addresses. Check your internet connection.';
        _isSearching = false;
      });
    }
  }

  void _selectAddress(Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisLoadingScreen(
          address: place['description'],
          latitude: place['latitude'],
          longitude: place['longitude'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Address'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            
            // Search Icon
            Icon(
              Icons.search,
              size: 64,
              color: Colors.orange.shade600,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Where do you want to install solar?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Address Search Field
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: '123 Main St, Austin, TX',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _addressController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _addressController.clear();
                          setState(() {
                            _predictions = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.orange.shade600,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_addressController.text == value) {
                    _searchAddress(value);
                  }
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Pick on Map Button
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationPickerScreen(),
                  ),
                );
                
                if (result != null && result is Map<String, dynamic>) {
                  _selectAddress(result);
                }
              },
              icon: const Icon(Icons.map),
              label: const Text('Pick Location on Map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade600),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Loading indicator
            if (_isSearching)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Search Results
            if (_predictions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: Colors.orange.shade600,
                        ),
                        title: Text(prediction['description']),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _selectAddress(prediction),
                      ),
                    );
                  },
                ),
              ),
            
            // Privacy Notice
            if (_predictions.isEmpty && !_isSearching)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Your address is only used to fetch solar data from satellites. We don\'t store or share your location.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
