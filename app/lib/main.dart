//import 'package:flutter/material.dart';
//import 'animate_camera.dart';
//import 'safe_route_ui.dart';
////import 'map_ui.dart';
//import 'move_camera.dart';
//import 'page.dart';
//import 'place_marker.dart';
//import 'place_polyline.dart';
//import 'scrolling_map.dart';
//import 'dart:async';
//import 'package:google_maps_webservice/places.dart';
//import 'package:flutter_google_places/flutter_google_places.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:location/location.dart' as LocationManager;
//import 'api_key.dart' as api_key;
//import 'package:flutter/services.dart';
//
//
//final List<Page> _allPages = <Page>[
//  MapUiPage(),
//  AnimateCameraPage(),
//  MoveCameraPage(),
//  PlaceMarkerPage(),
//  PlacePolylinePage(),
//  ScrollingMapPage(),
//];
//
//class MapsDemo extends StatelessWidget {
//  void _pushPage(BuildContext context, Page page) {
//    Navigator.of(context).push(MaterialPageRoute<void>(
//        builder: (_) => Scaffold(
////              appBar: AppBar(title: Text(page.title)),
//              body: page,
//            )));
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
//    return Scaffold(
//      appBar: AppBar(title: const Text('GoogleMaps examples')),
//      body: ListView.builder(
//        itemCount: _allPages.length,
//        itemBuilder: (_, int index) => ListTile(
//              leading: _allPages[index].leading,
//              title: Text(_allPages[index].title),
//              onTap: () => _pushPage(context, _allPages[index]),
//            ),
//      ),
//    );
//  }
//}
//
//void main() {
//  runApp(MaterialApp(home: MapsDemo()));
//}
//
//Future<LatLng> getUserLocation() async {
//  LocationManager.LocationData currentLocation;
//  var location = new LocationManager.Location();
//  try {
//    currentLocation = await location.getLocation();
//    final lat = currentLocation.latitude;
//    final lng = currentLocation.longitude;
//    final center = LatLng(lat, lng);
//    return center;
//  } on Exception {
//    currentLocation = null;
//    return null;
//  }
//}
import 'package:flutter/material.dart';
import 'safe_route_ui.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'SafeRoute',
        theme: new ThemeData(
          fontFamily: 'Product Sans',
//        primarySwatch: Colors.blueGrey,
//        backgroundColor: Colors.blueGrey,
//        scaffoldBackgroundColor: Colors.blueGrey,
//        cardColor: Colors.blueGrey,
//          brightness: Brightness.dark,
          accentColor: Colors.white,
//        primaryColor: Color(0xFF),
        ),
        home: new MapUiBody()
    );
  }
}