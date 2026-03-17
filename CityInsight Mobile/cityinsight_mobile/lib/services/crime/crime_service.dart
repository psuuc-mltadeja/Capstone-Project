import 'package:cloud_firestore/cloud_firestore.dart';

class CrimeDataService {
  Future<Map<String, int>> getCrimesGroupedByBarangay() async {
    final crimesCollection = FirebaseFirestore.instance.collection('crimes');
    final querySnapshot = await crimesCollection.get();

    // Group crimes by barangay
    Map<String, int> barangayCrimeCount = {};
    for (var doc in querySnapshot.docs) {
      String barangay = doc['brgy'];
      barangayCrimeCount[barangay] = (barangayCrimeCount[barangay] ?? 0) + 1;
    }
    return barangayCrimeCount;
  }
}
