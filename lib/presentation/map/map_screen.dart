import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_cache.dart';
import '../../core/widgets/romantic_card.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationRepository _locationRepo = LocationRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<UserModel?>? _partnerSub;
  ll.LatLng? _myLocation;
  ll.LatLng? _partnerLocation;
  UserModel? _myUser;
  UserModel? _partnerUser;
  String? _errorMessage;
  bool _loading = true;
  bool _showRoute = false;
  List<ll.LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _partnerSub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid ?? auth.repository.currentAuthorizedUser?.uid;
    final partnerUid = auth.partnerUid;
    if (myUid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final myUser = await _profileRepo.getUser(myUid);
    if (mounted) setState(() => _myUser = myUser);

    try {
      final position = await _locationRepo.getCurrentPosition();
      if (mounted) {
        setState(() {
          _myLocation = ll.LatLng(position.latitude, position.longitude);
          _loading = false;
        });
      }
      await _locationRepo.updateMyLocation(uid: myUid, position: position);

      _positionSub = _locationRepo.positionStream().listen((pos) async {
        setState(() => _myLocation = ll.LatLng(pos.latitude, pos.longitude));
        await _locationRepo.updateMyLocation(uid: myUid, position: pos);
        _fetchRoute();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }

    if (partnerUid != null) {
      _partnerSub?.cancel();
      _partnerSub = _locationRepo.userStream(partnerUid).listen((partner) {
        if (partner?.location != null) {
          setState(() {
            _partnerLocation = ll.LatLng(partner!.location!.latitude, partner.location!.longitude);
            _partnerUser = partner;
          });
          _fetchRoute();
        }
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_myLocation == null || _partnerLocation == null || !_showRoute) return;
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_myLocation!.longitude},${_myLocation!.latitude};'
        '${_partnerLocation!.longitude},${_partnerLocation!.latitude}'
        '?geometries=geojson&overview=full',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final coords = data['routes']?[0]?['geometry']?['coordinates'] as List?;
      if (coords == null) return;
      if (mounted) {
        setState(() {
          _routePoints = coords.map((c) => ll.LatLng(c[1], c[0])).toList();
        });
      }
    } catch (_) {}
  }

  double? get _distanceKm {
    if (_myLocation == null || _partnerLocation == null) return null;
    final meters = _locationRepo.distanceInMeters(
      lat1: _myLocation!.latitude,
      lon1: _myLocation!.longitude,
      lat2: _partnerLocation!.latitude,
      lon2: _partnerLocation!.longitude,
    );
    return meters / 1000;
  }

  void _showProfile(UserModel user, String label, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (user.profileImageUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                        body: PhotoView(imageProvider: cachedMemoryImage(user.profileImageUrl)),
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: color.withValues(alpha: 0.2),
                backgroundImage: user.profileImageUrl.isNotEmpty
                    ? cachedMemoryImage(user.profileImageUrl)
                    : null,
                child: user.profileImageUrl.isEmpty
                    ? Icon(Icons.person, size: 40, color: color)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 18, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight)),
            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(user.bio, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myName = _myUser?.name ?? auth.currentUser?.name ?? KhmerText.mapMyLocation;

    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.mapTitle)),
      body: _loading
          ? const LoadingWidget(message: KhmerText.loading)
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off, size: 56, color: AppColors.primaryLight),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _startTracking();
                          },
                          child: const Text('ព្យាយាមម្តងទៀត', style: TextStyle(fontFamily: 'KantumruyPro')),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _myLocation ?? const ll.LatLng(11.5564, 104.9282),
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.love_app',
                        ),
                        if (_myLocation != null && _partnerLocation != null) ...[
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [_myLocation!, _partnerLocation!],
                                strokeWidth: 2,
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              if (_routePoints.isNotEmpty)
                                Polyline(
                                  points: _routePoints,
                                  strokeWidth: 4,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ],
                        MarkerLayer(
                          markers: [
                            if (_myLocation != null)
                              Marker(
                                point: _myLocation!,
                                width: 120,
                                height: 80,
                                child: _UserMarker(
                                  label: myName,
                                  color: AppColors.primary,
                                  imageBase64: _myUser?.profileImageUrl,
                                  onTap: () {
                                    if (_myUser != null) _showProfile(_myUser!, myName, AppColors.primary);
                                  },
                                ),
                              ),
                            if (_partnerLocation != null && _partnerUser != null)
                              Marker(
                                point: _partnerLocation!,
                                width: 120,
                                height: 80,
                                child: _UserMarker(
                                  label: _partnerUser!.name,
                                  color: AppColors.gold,
                                  imageBase64: _partnerUser!.profileImageUrl,
                                  onTap: () => _showProfile(_partnerUser!, _partnerUser!.name, AppColors.gold),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: RomanticCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.social_distance, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      KhmerText.mapDistance,
                                      style: TextStyle(color: AppColors.textLight, fontFamily: 'KantumruyPro', fontSize: 12),
                                    ),
                                    Text(
                                      _distanceKm != null ? '${_distanceKm!.toStringAsFixed(2)} គីឡូម៉ែត្រ' : '---',
                                      style: TextStyle(color: AppColors.textDark, fontFamily: 'KantumruyPro', fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showRoute ? Icons.route : Icons.route_outlined, color: _showRoute ? AppColors.primary : AppColors.textLight),
                                tooltip: 'បង្ហាញផ្លូវ',
                                onPressed: () {
                                  setState(() => _showRoute = !_showRoute);
                                  if (_showRoute) _fetchRoute();
                                },
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

class _UserMarker extends StatelessWidget {
  final String label;
  final Color color;
  final String? imageBase64;
  final VoidCallback onTap;

  const _UserMarker({
    required this.label,
    required this.color,
    this.imageBase64,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: imageBase64 != null && imageBase64!.isNotEmpty
                  ? Image.memory(cachedBase64Decode(imageBase64!), fit: BoxFit.cover)
                  : Icon(Icons.person, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            child: Text(
              label,
              style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 10, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
