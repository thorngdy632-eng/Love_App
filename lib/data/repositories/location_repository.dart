import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';

class LocationRepository {
  final FirebaseFirestore _firestore;
  LocationRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Ensures location services are on and permission is granted.
  /// Throws a [String] message (Khmer) on failure — caller should catch and show it.
  Future<Position> getCurrentPosition() async {
    if (kIsWeb) {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return position;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'សូមបើកទីតាំង (GPS) ជាមុនសិន';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'សូមអនុញ្ញាតការចូលប្រើទីតាំង';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'សូមអនុញ្ញាតការចូលប្រើទីតាំងនៅក្នុងការកំណត់ឧបករណ៍';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> updateMyLocation({required String uid, required Position position}) async {
    await _firestore.collection('users').doc(uid).update({
      'location': GeoPoint(position.latitude, position.longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromMap(doc.data()!, uid) : null,
        );
  }

  double distanceInMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
