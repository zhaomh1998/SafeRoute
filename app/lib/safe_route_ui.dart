// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:location/location.dart' as LocationManager;
import 'api_key.dart' as api_key;
import 'page.dart';

// API Call stuff
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: api_key.kGoogleApiKey);
LatLng origin = LatLng(0, 0);
LatLng destination = LatLng(0, 0);

final LatLngBounds laBounds = LatLngBounds(
  southwest: const LatLng(34.136, -118.665),
  northeast: const LatLng(33.728, -117.785),
);

class MapUiPage extends Page {
  MapUiPage() : super(const Icon(Icons.map), 'SafeRoute');

  @override
  Widget build(BuildContext context) {
    return const MapUiBody();
  }
}

class MapUiBody extends StatefulWidget {
  const MapUiBody();

  @override
  State<StatefulWidget> createState() => MapUiBodyState();
}

class MapUiBodyState extends State<MapUiBody> {
  MapUiBodyState();

  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(34.0522, -118.2437),
    zoom: 11.0,
  );

  GoogleMapController mapController;
  CameraPosition _position = _kInitialPosition;
  bool _isMoving = false;
  bool _compassEnabled = true;
  CameraTargetBounds _cameraTargetBounds = CameraTargetBounds.unbounded;
  MinMaxZoomPreference _minMaxZoomPreference = MinMaxZoomPreference.unbounded;
  MapType _mapType = MapType.normal;
  bool _rotateGesturesEnabled = true;
  bool _scrollGesturesEnabled = true;
  bool _tiltGesturesEnabled = true;
  bool _zoomGesturesEnabled = true;
  bool _myLocationEnabled = true;
  bool _myLocationButtonEnabled = true;
  int _locationButton = 0;
  LatLng _tapped = const LatLng(0, 0);
  LatLng _tappedLong = const LatLng(0, 0);
  LatLng _tappedLocation = const LatLng(0, 0);
  bool _locationReady = false;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  List<PlacesSearchResult> places = [];
  bool isLoading = false;
  String errorMessage;

  @override
  void initState() {
    super.initState();
  }

//  void _onMapChanged() {
//    setState(() {
//      _extractMapInfo();
//    });
//  }

  void _onLocationClick(LatLng location) {
    _tappedLocation = location;
  }

  void _onLocationButtonClick() {
    _locationButton++;
  }

  void _onMapLongTapped(LatLng location) {
    _tappedLong = location;
    destination = location;
    print(
        'Setting destination to ${destination.longitude},${destination.latitude}');
  }

  void _onMapTapped(LatLng location) {
    _tapped = location;
  }

//  void _extractMapInfo() {
//    _position = mapController.cameraPosition;
//    _isMoving = mapController.isCameraMoving;
//  }

  @override
  void dispose() {
//    mapController.removeListener(_onMapChanged);
    super.dispose();
  }

  Widget _compassToggler() {
    return FlatButton(
      child: Text('${_compassEnabled ? 'disable' : 'enable'} compass'),
      onPressed: () {
        setState(() {
          _compassEnabled = !_compassEnabled;
        });
      },
    );
  }

//  Widget _drawerOpener() {
//
//  }

  Widget _mapTypeCycler() {
    final MapType nextType =
        MapType.values[(_mapType.index + 1) % MapType.values.length];
    return FlatButton(
      child: Text('change map type to $nextType'),
      onPressed: () {
        setState(() {
          _mapType = nextType;
        });
      },
    );
  }

  void refresh() async {
    final center = await getUserLocation();
    origin = center;

    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: center == null ? LatLng(0, 0) : center, zoom: 15.0)));
//    getNearbyPlaces(center);
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

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton() async {
    LatLng targetLocation = await _searchLocation();
    print(
        "${targetLocation.latitude.toString()}, ${targetLocation.longitude.toString()}");
    if (targetLocation != null) {
      final markerOptions = MarkerOptions(
          position: targetLocation,
          infoWindowText: InfoWindowText(
              "${targetLocation.latitude}", "${targetLocation.longitude}"));
      mapController.addMarker(markerOptions);
      mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: targetLocation, zoom: 15.0)));
    }
  }

  Future<LatLng> _searchLocation() async {
    try {
      final center = await getUserLocation();
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          strictbounds: false,
          apiKey: api_key.kGoogleApiKey,
          onError: onError,
          mode: Mode.fullscreen,
          language: "en",
          location: center == null
              ? null
              : Location(center.latitude, center.longitude),
          radius: center == null ? null : 10000);

//      print(_places.getDetailsByPlaceId(p.placeId));
      PlacesDetailsResponse chosenPlace =
          await _places.getDetailsByPlaceId(p.placeId);
      var chosenLocation = chosenPlace.result.geometry.location;
      return LatLng(chosenLocation.lat, chosenLocation.lng);
//      showDetailPlace(p.placeId);
    } catch (e) {
      return null;
    }
  }

  Widget _myLocationButtonToggler() {
    return FlatButton(
      child: Text(
          '${_myLocationButtonEnabled ? 'disable' : 'enable'} my location button'),
      onPressed: () {
        setState(() {
          _myLocationButtonEnabled = !_myLocationButtonEnabled;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GoogleMap googleMap = GoogleMap(
        onMapCreated: onMapCreated,
        initialCameraPosition: _kInitialPosition,
        trackCameraPosition: true,
        compassEnabled: _compassEnabled,
        cameraTargetBounds: _cameraTargetBounds,
        minMaxZoomPreference: _minMaxZoomPreference,
        mapType: _mapType,
        rotateGesturesEnabled: _rotateGesturesEnabled,
        scrollGesturesEnabled: _scrollGesturesEnabled,
        tiltGesturesEnabled: _tiltGesturesEnabled,
        zoomGesturesEnabled: _zoomGesturesEnabled,
        myLocationEnabled: _myLocationEnabled,
        myLocationButtonEnabled: _myLocationButtonEnabled);
    final List<Widget> columnChildren = <Widget>[
//      Padding(
//        padding: const EdgeInsets.all(10.0),
//        child:
//      ),
      Center(
          child: Stack(
        children: <Widget>[
          SizedBox(
            width: 500.0,
            height: 500.0,
            child: googleMap,
          ),
          Padding(
              // Search bar
              padding: const EdgeInsets.all(20.0),
              child: Center(
                  child: Container(
                      padding: const EdgeInsets.all(20.0),
                      width: 350.0,
                      height: 60.0,
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          const Radius.circular(10.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2,
                            // has the effect of softening the shadow
                            spreadRadius: 0.25,
                            // has the effect of extending the shadow
                            offset: Offset(
                              0.5, // horizontal, move right 10
                              0.5, // vertical, move down 10
                            ),
                          )
                        ],
//                        borderRadius: new BorderRadius.all(),
//                        gradient: new LinearGradient(...),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          MaterialButton(
                            onPressed: () => print("Hello"),
                            child: Icon(Icons.dehaze),
                          ),
                          InkWell(
                            onTap: _handlePressButton,
                            child: Container(
                              color: Colors.grey,
//                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                "Fukuuuu",
                                textAlign: TextAlign.start,
                              ),
                            ),
                          )
                        ],
                      ))))
        ],
      )),
    ];

    if (mapController != null) {
      columnChildren.add(Text("Reserved space..."));
      columnChildren.add(MaterialButton(
        onPressed: getDirection,
        child: Icon(Icons.send),
      ));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
//    mapController.addListener(_onMapChanged);  // For moving map and get new cam location // Don't forget to remove this listened in dispose!
    mapController.onMapLongTapped.add(_onMapLongTapped);
    mapController.onMapTapped.add(_onMapTapped);
//    _extractMapInfo();
    refresh();
    setState(() {
      _myLocationButtonEnabled = false;
    });
  }

  Widget responseList() {
    if (_locationReady) {
      // TODO: Render decoded polylines
      // TODO: Send path points to FB, awaith response, update polylines and safety score on widget
      return Text("This is decoded result direction list");
    } else
      return null;
  }
}

// API Calls
class Route {
  final List<LatLng> waypoints;
  final String polyLineStr;
  final String duration;
  final String distance;

  Route({this.waypoints, this.polyLineStr, this.duration, this.distance});

  factory Route.parseRoute(dynamic route) {
    return Route(
        waypoints: decodePolyline(route['overview_polyline']['points']),
        polyLineStr: route['overview_polyline']['points'],
        duration: route['legs'][0]['duration']['text'],
        distance: route['legs'][0]['distance']['text']);
  }
}

class DirectionResponse {
  final List<Route> routes;

  DirectionResponse({this.routes});

  factory DirectionResponse.fromJson(Map<String, dynamic> json) {
    var input = json['routes'];
    List<Route> decodedRoutes = [];
    for (int i = 0; i < input.length; i++) {
      var parsedRoute = Route.parseRoute(input[i]);
      decodedRoutes.add(parsedRoute);
    }
    return DirectionResponse(routes: decodedRoutes);
  }
}

Future<void> fbTest() async {
  final response = await http
      .get('https://us-central1-saferoute-d749c.cloudfunctions.net/helloWorld');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    return print(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

Future<DirectionResponse> getDirection() async {
  if (origin.longitude != 0 &&
      origin.latitude != 0 &&
      destination.longitude != 0 &&
      destination.latitude != 0) {
    var decodedDirections = await fetchDirections(origin, destination);
    return decodedDirections;
  }
  return null;
}

Future<DirectionResponse> fetchDirections(LatLng origin, LatLng dest) async {
  var request_url = 'https://maps.googleapis.com/maps/api/directions/json?' +
      'origin=${origin.latitude},${origin.longitude}&' +
      'destination=${dest.latitude},${dest.longitude}&' +
      'mode=walking&alternatives=true&key=${api_key.kGoogleApiKey}';
  final response = await http.get(request_url);

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    var responseDecode = json.decode(response.body);
    if (responseDecode['status'] != 'OK')
      throw Exception('Response status ${responseDecode['status']}');
    else
      return DirectionResponse.fromJson(responseDecode);
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

// Author: RaimundWege https://github.com/johnpryan/flutter_map/issues/91
List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = new List<LatLng>();
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = new LatLng(lat / 1E5, lng / 1E5);
    points.add(p);
  }
  return points;
}
