//import 'package:flutter/material.dart';
//import 'animate_camera.dart';
//import 'safe_route_ui.dart';
//import 'move_camera.dart';
//import 'page.dart';
//import 'place_marker.da-rt';
//import 'place_polyline.dart';
//import 'scrolling_map.dart';
//import 'dart:async';
//import 'package:google_maps_webservice/places.dart';
//import 'package:flutter_google_places/flutter_google_places.dart';
//import 'package:flutter/material.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:location/location.dart' as LocationManager;
//import 'place_detail.dart';
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


// Example location search


import 'dart:async';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LocationManager;
import 'place_detail.dart';
import 'api_key.dart' as api_key;

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: api_key.kGoogleApiKey);

void main() {
  runApp(MaterialApp(
    title: "PlaceZ",
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController mapController;
  List<PlacesSearchResult> places = [];
  bool isLoading = false;
  String errorMessage;

  @override
  Widget build(BuildContext context) {
    Widget expandedChild;
    if (isLoading) {
      expandedChild = Center(child: CircularProgressIndicator(value: null));
    } else if (errorMessage != null) {
      expandedChild = Center(
        child: Text(errorMessage),
      );
    }
    else {
      expandedChild = Center(child: Text("Loaded"));
    }

    return Scaffold(
        key: homeScaffoldKey,
        appBar: AppBar(
          title: const Text("PlaceZ"),
          actions: <Widget>[
            isLoading
                ? IconButton(
                    icon: Icon(Icons.timer),
                    onPressed: () {},
                  )
                : IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      refresh();
                    },
                  ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _handlePressButton();
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Container(
              child: SizedBox(
                  height: 200.0,
                  child: GoogleMap(
                      onMapCreated: _onMapCreated,
                          myLocationEnabled: true,
                          initialCameraPosition:
                              const CameraPosition(target: LatLng(0.0, 0.0))
                      )),
            ),
            Expanded(child: expandedChild)
          ],
        ));
  }

  void refresh() async {
    final center = await getUserLocation();

    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: center == null ? LatLng(0, 0) : center, zoom: 15.0)));
//    getNearbyPlaces(center);
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    refresh();
  }

  Future<LatLng> getUserLocation() async {
    LocationManager.LocationData currentLocation;
    var location = new LocationManager.Location();
    try {
      currentLocation = await location.getLocation();
      final lat = currentLocation.latitude;
      final lng = currentLocation.longitude;
      final center = LatLng(lat, lng);
      return center;
    } on Exception {
      currentLocation = null;
      return null;
    }
  }

  void getNearbyPlaces(LatLng center) async {
    setState(() {
      this.isLoading = true;
      this.errorMessage = null;
    });

    final location = Location(center.latitude, center.longitude);
    final result = await _places.searchNearbyWithRadius(location, 2500);
    setState(() {
      this.isLoading = false;
      if (result.status == "OK") {
        this.places = result.results;
        result.results.forEach((f) {
          final markerOptions = MarkerOptions(
              position:
                  LatLng(f.geometry.location.lat, f.geometry.location.lng),
              infoWindowText: InfoWindowText("${f.name}", "${f.types?.first}"));
          mapController.addMarker(markerOptions);
        });
      } else {
        this.errorMessage = result.errorMessage;
      }
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton() async {
    LatLng targetLocation = await _searchLocation();
    print("${targetLocation.latitude.toString()}, ${targetLocation.longitude.toString()}");
    if(targetLocation != null) {
      final markerOptions = MarkerOptions(
          position: targetLocation,
          infoWindowText: InfoWindowText("Arg1", "Arg2"));
      mapController.addMarker(markerOptions);
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: targetLocation, zoom: 15.0)));
    }
  }
  Future<LatLng> _searchLocation() async {
    try {
      final center = await getUserLocation();
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          strictbounds: false,
//          strictbounds: center == null ? false : true,
          apiKey: api_key.kGoogleApiKey,
          onError: onError,
          mode: Mode.fullscreen,
          language: "en",
          location: center == null
              ? null
              : Location(center.latitude, center.longitude),
          radius: center == null ? null : 10000);

//      print(_places.getDetailsByPlaceId(p.placeId));
      PlacesDetailsResponse chosenPlace = await _places.getDetailsByPlaceId(p.placeId);
      var chosenLocation = chosenPlace.result.geometry.location;
      return LatLng(chosenLocation.lat, chosenLocation.lng);
//      showDetailPlace(p.placeId);
    } catch (e) {
      return null;
    }
  }

  Future<Null> showDetailPlace(String placeId) async {
    if (placeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlaceDetailWidget(placeId)),
      );
    }
  }
}
