  // void _addMarker(QueryDocumentSnapshot doc, String type) {
  //   double latitude = double.tryParse(doc['latitude'].toString()) ?? 0.0;
  //   double longitude = double.tryParse(doc['longitude'].toString()) ?? 0.0;

  //   // Log the latitude and longitude for debugging
  //   print(
  //       'Adding marker for $type at latitude: $latitude, longitude: $longitude');

  //   String formattedDate;
  //   if (doc['date'] is Timestamp) {
  //     DateTime dateTime = (doc['date'] as Timestamp).toDate();
  //     formattedDate = DateFormat('MMMM d, y h:mm a').format(dateTime);
  //   } else {
  //     formattedDate = doc['date'];
  //   }

  //   LatLng markerPosition = LatLng(latitude, longitude);
  //   BitmapDescriptor markerIcon = customIcon;

  //   if (type == 'crime') {
  //     markerIcon = customIcon;
  //     if (_selectedCollection == 'crimes' || _selectedCollection == null) {
  //       _markers.add(Marker(
  //         markerId: MarkerId('crime_${doc.id}'),
  //         position: markerPosition,
  //         icon: markerIcon,
  //         onTap: () {
  //           _showDetailsScreen(doc['type'], doc, formattedDate);
  //         },
  //       ));
  //     }
  //   } else if (type == 'flood') {
  //     print('Adding flood marker for doc: ${doc.id}'); // Add this line
  //     markerIcon =
  //         BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  //     if (_selectedCollection == 'floods' || _selectedCollection == null) {
  //       _markers.add(Marker(
  //         markerId: MarkerId('flood_${doc.id}'),
  //         position: markerPosition,
  //         icon: markerIcon,
  //         onTap: () {
  //           _showDetailsScreen(type, doc, formattedDate);
  //         },
  //       ));
  //     }
  //   }

  //   // Log the total number of markers added
  //   print('Total markers added: ${_markers.length}');
  // }
