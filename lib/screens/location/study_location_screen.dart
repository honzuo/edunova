/// study_location_screen.dart — GPS-based study location tracker.
///
/// Uses [geolocator] for GPS location detection and [flutter_map]
/// with OpenStreetMap tiles to display saved study spots on a map.
/// Supports adding current location as a study spot and deleting spots.
///
/// This feature utilises mobile-unique hardware (GPS sensor) as
/// required by the assignment rubric for advanced features.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class StudyLocationScreen extends StatefulWidget {
  const StudyLocationScreen({super.key});

  @override
  State<StudyLocationScreen> createState() => _StudyLocationScreenState();
}

class _StudyLocationScreenState extends State<StudyLocationScreen> {
  final DatabaseService _db = DatabaseService();
  final MapController _mapCtrl = MapController();
  String get _userId => AuthService().currentUserId ?? 'demo-user';

  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Initialize: request GPS permission and load saved locations.
  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadLocations();
    setState(() => _loading = false);
  }

  /// Request location permission and get current GPS coordinates.
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. '
                  'Please enable in device settings.'),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  /// Load all saved study locations from Supabase.
  Future<void> _loadLocations() async {
    try {
      final data = await _db.getStudyLocations(_userId);
      setState(() => _locations = data);
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  /// Save current GPS location as a new study spot.
  Future<void> _saveCurrentLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    // Show dialog to enter a label for this spot
    final labelCtrl = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Study Spot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currentPosition!.latitude.toStringAsFixed(5)}, '
              '${_currentPosition!.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                hintText: 'Label (e.g. Library, Cafe)',
                prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              labelCtrl.text.trim().isEmpty
                  ? 'Study Spot'
                  : labelCtrl.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    labelCtrl.dispose();

    if (label == null) return; // User cancelled

    // Insert into Supabase
    await _db.insertStudyLocation({
      'user_id': _userId,
      'latitude': _currentPosition!.latitude,
      'longitude': _currentPosition!.longitude,
      'label': label,
      'created_at': DateTime.now().toIso8601String(),
    });

    HapticFeedback.mediumImpact();
    await _loadLocations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📍 "$label" saved!')),
      );
    }
  }

  /// Delete a study location from Supabase.
  Future<void> _deleteLocation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Study Spot?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteStudyLocation(id);
      await _loadLocations();
    }
  }

  // ── Fetch Weather Web API (Advanced Feature) ──
  Future<void> _checkWeather(double lat, double lon, String locName) async {
    final scaffoldMsg = ScaffoldMessenger.of(context);
    scaffoldMsg.showSnackBar(
      const SnackBar(content: Text('☁️ Fetching live weather data...'), duration: Duration(seconds: 1)),
    );

    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (!mounted) return;
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final temp = current['temperature'];
        final windSpeed = current['windspeed'];

        // 判断天气状况给个小建议
        String suggestion = temp > 30 ? 'It is quite hot! A library with AC is recommended. 🥶' : 'Great weather for studying anywhere! ☀️';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Weather at $locName', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌡️ ', style: TextStyle(fontSize: 24)),
                    Text('$temp °C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('💨 Wind Speed: $windSpeed km/h'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF5AC8FA).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                  child: Text(suggestion, style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMsg.showSnackBar(const SnackBar(content: Text('Failed to fetch weather. Check internet.')));
    }
  }

  // ═══════════════════════════════
  // ── Build UI ──
  // ═══════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Default map center: current position or Kuala Lumpur
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(3.1390, 101.6869); // KL default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Locations'),
        actions: [
          // Refresh GPS button
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: () async {
              await _getCurrentLocation();
              if (_currentPosition != null) {
                _mapCtrl.move(
                  LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude),
                  15,
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Map (top half) ──
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14,
                    ),
                    children: [
                      // OpenStreetMap tile layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.edunova.app',
                        maxZoom: 19,
                      ),

                      // Markers for saved study locations
                      MarkerLayer(
                        markers: [
                          // Current position marker (blue)
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: cs.primary, width: 2),
                                ),
                                child: Icon(Icons.person_rounded,
                                    size: 20, color: cs.primary),
                              ),
                            ),

                          // Saved study spot markers (orange)
                          ..._locations.map((loc) {
                            final lat =
                                (loc['latitude'] as num?)?.toDouble() ?? 0;
                            final lng =
                                (loc['longitude'] as num?)?.toDouble() ?? 0;
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _deleteLocation(
                                    (loc['id'] as num).toInt()),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 36,
                                  color: Color(0xFFFF9500),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Location List (bottom half) ──
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Study Spots',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_locations.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // GPS status
                      if (_currentPosition != null)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '📡 GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                            '${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Location list
                      Expanded(
                        child: _locations.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_off_rounded,
                                        size: 40, color: Colors.grey[300]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No study spots saved yet',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14),
                                    ),
                                    Text(
                                      'Tap + to save your current location',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: _locations.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final loc = _locations[i];
                            final lat = (loc['latitude'] as num?)?.toDouble() ?? 0;
                            final lng = (loc['longitude'] as num?)?.toDouble() ?? 0;

                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9500).withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 22,
                                    color: Color(0xFFFF9500),
                                  ),
                                ),
                                title: Text(
                                  loc['label'] as String? ?? 'Study Spot',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500]),
                                ),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.cloud_outlined, color: Color(0xFF5AC8FA)),
                                      tooltip: 'Check Weather',
                                      onPressed: () => _checkWeather(lat, lng, loc['label'] as String? ?? 'this spot'),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: Colors.grey[400]),
                                      onPressed: () => _deleteLocation(
                                          (loc['id'] as num).toInt()),
                                    ),
                                  ],
                                ),

                                onTap: () {
                                  _mapCtrl.move(LatLng(lat, lng), 16);
                                },
                              ),
                            );
                          },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_location',
        onPressed: _saveCurrentLocation,
        child: const Icon(Icons.add_location_alt_rounded),
      ),
    );
  }
}
