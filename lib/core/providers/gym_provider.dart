import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/gym_model.dart';
import '../services/location_service.dart';

/// State management for the Nearby Gyms feature.
///
/// Handles:
/// - Location permission flow
/// - Fetching user's current position
/// - Querying Overpass API for nearby fitness centres
/// - Radius filtering
/// - Selected gym tracking for the map
class GymProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _permissionDenied = false;
  String? _errorMessage;

  LatLng? _userLocation;
  List<GymModel> _allGyms = [];
  List<GymModel> _filteredGyms = [];
  GymModel? _selectedGym;
  double _radiusKm = 5.0;

  List<LatLng>? _currentRoute;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get permissionDenied => _permissionDenied;
  String? get errorMessage => _errorMessage;
  LatLng? get userLocation => _userLocation;
  List<GymModel> get gyms => _filteredGyms;
  GymModel? get selectedGym => _selectedGym;
  double get radiusKm => _radiusKm;
  List<LatLng>? get currentRoute => _currentRoute;

  /// Available radius filter options in km.
  static const List<double> radiusOptions = [1, 3, 5, 10, 20, 50];

  // ── Public Methods ────────────────────────────────────────────────────────

  /// Primary entry-point: request permission → get location → fetch gyms.
  Future<void> init() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _permissionDenied = false;
    _currentRoute = null;
    notifyListeners();

    try {
      // 1. Location permission
      final granted = await _locationService.requestPermission();
      if (!granted) {
        _permissionDenied = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Current position
      final position = await _locationService.getCurrentPosition();
      _userLocation = LatLng(position.latitude, position.longitude);

      // 3. Fetch gyms (use max radius to fetch once, then filter client-side)
      _allGyms = await _locationService.fetchNearbyGyms(
        position.latitude,
        position.longitude,
        radiusKm: 50, // fetch everything within 50 km, filter locally
      );

      _applyRadiusFilter();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-centres the map to the user's current position and re-fetches gyms.
  Future<void> recenterAndRefresh() async {
    await init();
  }

  /// Changes the distance filter and triggers a UI refresh.
  void setRadius(double km) {
    _radiusKm = km;
    _applyRadiusFilter();
    notifyListeners();
  }

  /// Selects a gym (highlights on the map, scrolls to card, etc.)
  void selectGym(GymModel? gym) {
    _selectedGym = gym;
    if (gym == null) {
      _currentRoute = null;
    }
    notifyListeners();
  }

  /// Fetches the route from user location to the given gym and updates the map
  Future<void> drawRouteTo(GymModel gym) async {
    if (_userLocation == null) return;
    
    // Set the gym as selected so it gets highlighted
    _selectedGym = gym;
    notifyListeners();

    final route = await _locationService.fetchRoute(
      _userLocation!,
      LatLng(gym.lat, gym.lng),
    );

    if (route != null) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _applyRadiusFilter() {
    _filteredGyms =
        _allGyms.where((g) => g.distanceKm <= _radiusKm).toList();
    // If the previously selected gym is now outside the radius, deselect it
    if (_selectedGym != null &&
        !_filteredGyms.any((g) => g.id == _selectedGym!.id)) {
      _selectedGym = null;
      _currentRoute = null;
    }
  }
}
