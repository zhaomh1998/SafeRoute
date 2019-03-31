import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:location/location.dart' as LocationManager;
import 'api_key.dart' as api_key;
import 'page.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'drawer.dart';
import 'package:android_intent/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

// API Call stuff
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: api_key.kGoogleApiKey);
LatLng origin = LatLng(0, 0);
LatLng destination = LatLng(0, 0);
DirectionResponse pathResponse;

final LatLngBounds laBounds = LatLngBounds(
  southwest: const LatLng(34.105999, -118.465381),
  northeast: const LatLng(34.016907, -118.138795),
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
  // Init config
  MapUiBodyState();

  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(34.0522, -118.2437),
    zoom: 11.0,
  );
  double deviceWidth;
  double deviceHeight;
  double mapHeight;
  double mapScalingFactor = 0.87;
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
  bool _readyToNavigate = false;

  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  List<PlacesSearchResult> places = [];
  bool isLoading = false;
  String errorMessage;

  @override
  void initState() {
    super.initState();
  }


  // Map Callbacks -------------------------------------------------------------
  void _onMapLongTapped(LatLng location) {
    _tappedLong = location;
    _onSelectedLocation(location, true);
  }
  void _onMapTapped(LatLng location) {
    _tapped = location;
    _onSelectedLocation(location, false);
  }
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
  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }
  void _onSelectedLocation(LatLng location, bool isDestination) async {
    if (isDestination) {
      destination = location;
      _addMarker(location);
      getRiskScore(location);
    }
    else
      _addOrigin(location);
  }


  // Map Helpers----------------------------------------------------------------
  void _draw_polyline(List<LatLng> waypts, {bool readjustView: true}) {
    mapController.addPolyline(PolylineOptions(
        points: waypts,
        color: Colors.blue.withOpacity(0.8).value,
        width: 20,
        visible: true));
    if (readjustView) {
      var origLoc = LatLng(waypts[0].latitude, waypts[0].longitude);
      var newLoc = LatLng(waypts[waypts.length - 1].latitude,
          waypts[waypts.length - 1].longitude);
      var swLoc = LatLng(min(origLoc.latitude, newLoc.latitude),
          min(origLoc.longitude, newLoc.longitude));
      var neLoc = LatLng(max(origLoc.latitude, newLoc.latitude),
          max(origLoc.longitude, newLoc.longitude));
      mapController.moveCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: swLoc, northeast: neLoc),
          50.0,
        ),
      );
    }
  }
  void refresh() async {
    final center = await getUserLocation();
    origin = center;

    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: center == null ? LatLng(0, 0) : center, zoom: 15.0)));
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
  Future<void> _handleSearch() async {
    LatLng targetLocation = await _searchLocation();
    if (targetLocation != null) {
      _onSelectedLocation(targetLocation, true);
    }
  }
  void _addMarker(LatLng location, {bool moveCamera: true, double zoom: 15.0}) {
    final markerOptions = MarkerOptions(
        position: location,
        infoWindowText:
        InfoWindowText("${location.latitude}", "${location.longitude}"));
    mapController.addMarker(markerOptions);
    mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.0)));
  }
  void _addOrigin(LatLng location) {
    final markerOptions = MarkerOptions(
        position: location,
        infoWindowText:
        InfoWindowText("Origin", "${location.latitude},${location.longitude}"),
        rotation: 30.0);
    mapController.addMarker(markerOptions);
    origin = location;
  }
  void _launchGMap(LatLng originLocation, LatLng destinationLocation) async {
    String origin="${originLocation.latitude},${originLocation.longitude}";  // lat,long like 123.34,68.56
    String destination="${destinationLocation.latitude},${destinationLocation.longitude}";
    if (Platform.isAndroid) {
      final AndroidIntent intent = new AndroidIntent(
          action: 'action_view',
          data: Uri.encodeFull(
              "https://www.google.com/maps/dir/?api=1&origin=" +
                  origin + "&destination=" + destination + "&travelmode=walking&dir_action=navigate"),
          package: 'com.google.android.apps.maps');
      intent.launch();
    }
    else {
      String url = "https://www.google.com/maps/dir/?api=1&origin=" + origin + "&destination=" + destination + "&travelmode=walking&dir_action=navigate";
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  } // TODO: add biking mode
  @override
  void dispose() {
    super.dispose();
  }


  // Widget Builders------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
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

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      drawer: getDrawer(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildMap(googleMap, context),
          buildBottomBar(),
        ],
      ),
    );
  }
  Widget buildMap(GoogleMap googleMap, BuildContext context) {
    return Center(
        child: Stack(
      children: <Widget>[
        SizedBox(
          width: deviceWidth,
          height: deviceHeight * mapScalingFactor,
          child: googleMap,
        ),
        Padding(
            // Search bar
            padding: const EdgeInsets.all(12.0),
            child: Center(
                child: Container(
                    padding: const EdgeInsets.all(0.1),
                    width: deviceWidth / 1.05,
                    height: deviceWidth / 7.0,
                    decoration: new BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        const Radius.circular(10.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.8),
                          blurRadius: 3,      // softening shadow
                          spreadRadius: 0.25, // extending shadow
                          offset: Offset(0.5, 0.5)
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        MaterialButton(
                          onPressed: () => print("SearchBarBtnPressed!"),
                          child: Icon(
                            Icons.dehaze,
                            size: 25.0,
                          ),
                          height: 100.0,
                          minWidth: 50.0,
                        ),
                        Expanded(
                            child: InkWell(
                          onTap: _handleSearch,
                          child: Container(
//                              padding: EdgeInsets.all(24.0),
                            child: Text(
                              "Search Location...                        ",
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ))
                      ],
                    ))))
      ],
    ));
  }
  Widget buildBottomBar() {
    return Column(
        children: <Widget>[
          buildMiddleCards(),
          Row(
            // Navigate Button
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(padding: EdgeInsets.all(10.0), child: SizedBox(
                height: deviceHeight / 15,
                width: deviceWidth * 0.6,
                child: Text("hi"),
              )),
              // Navigate Button
              Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                      padding: const EdgeInsets.all(0.1),
                      width: deviceWidth / 4,
                      height: deviceHeight / 15,
                      decoration: new BoxDecoration(
                        color: Color.fromARGB(255, 58, 120, 231),
                        borderRadius: BorderRadius.all(
                          const Radius.circular(30.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.8),
                            blurRadius: 3,
                            // has the effect of softening the shadow
                            spreadRadius: 0.25,
                            // has the effect of extending the shadow
                            offset: Offset(
                              0.5, // horizontal, move right 10
                              0.5, // vertical, move down 10
                            ),
                          )
                        ],
                      ),
                      child: InkWell(
                          onTap: () {
                            setState(() {
                              mapScalingFactor = 0.6;
                              _readyToNavigate = !_readyToNavigate;
                              if(_readyToNavigate)
                                navigateProcedure();
                              else
                                _launchGMap(origin, destination);
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                Icons.navigation,
                                size: 25.0,
                                color: Colors.white,
                              ),
                              Text(
                                _readyToNavigate ? "Navigate" : "Safe Route",
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ))))
            ],
          ),
        ]
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
  Widget buildMiddleCards() {
    if (_locationReady) {
      // TODO: Render decoded polylines
      // TODO: Send path points to GCP backend, await response, update polylines and safety score on widget
      _locationReady = false;
      return FutureBuilder<DirectionResponse>(
        future: getPathScore(),
        builder: (context, snapshot) {
          if(snapshot.hasData)
            return constructDirectionCard(false);
          else if(snapshot.hasError)
            return Text("${snapshot.error}");
          return constructDirectionCard(true);
        },
      );
    } else
      return Text("");
  }

  Widget constructDirectionCard(bool isWaiting) {
    var nCards = pathResponse.routes.length;
    List<Widget> listOfCards = [];

    for (int i = 0; i < nCards; i++) {
      // Add card for each path
      listOfCards.add(Card(
        elevation: 1,
        margin: EdgeInsets.symmetric(
            horizontal: deviceWidth / 30, vertical: deviceHeight / 120),
        child: Container(
          height: deviceHeight / 12,
          decoration: BoxDecoration(
              color: Color.fromRGBO(212, 216, 223, 0.8)),
          child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                  horizontal: deviceWidth / 20, vertical: deviceHeight / 200),
              leading: Container(
                padding: EdgeInsets.only(right: 20.0),
                decoration: new BoxDecoration(
                    border: new Border(
                        right:
                        new BorderSide(width: 1.0, color: Colors.white24))),
                child: Icon(Icons.trip_origin, color: Colors.white),
              ),
              title: Text(isWaiting? "Loading Safety Data..." : pathResponse.routes[i].score.toString(),
                style: TextStyle(
                    color: Colors.black45, fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: <Widget>[
                  Text(pathResponse.routes[i].distance, style: TextStyle(color: Colors.white))
                ],
              ),
              trailing: Text(pathResponse.routes[i].duration)),
        ),
      ));
    }

    return ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: listOfCards);
  }
  Future<void> navigateProcedure() async {
    if (origin.longitude != 0 &&
        origin.latitude != 0 &&
        destination.longitude != 0 &&
        destination.latitude != 0) {
      // Step 1. Retrieve Directions
      pathResponse = await getGMapDirection(origin, destination);
      var routes = pathResponse.routes;
      // Step 2. Draw Polyline
      for (int i = 0; i < routes.length; i++) {
        print(routes[i].polyLineStr);
        _draw_polyline(routes[i].waypoints);
      }
      setState(() {
        pathResponse = pathResponse;
        _locationReady = true;
      });
      // Step 3. Request from Database TODO, edit
      getPathScore();
      // TODO
      // Step 4. Update UI
    }
    return null;
  }

}


// API Stuff -------------------------------------------------------------------
// API Response Factories
class Route {
  final List<LatLng> waypoints;
  final String polyLineStr;
  final String duration;
  final String distance;
  double score;

  Route({this.waypoints, this.polyLineStr, this.duration, this.distance, this.score});

  factory Route.parseRoute(dynamic route) {
    return Route(
        waypoints: decodePolyline(route['overview_polyline']['points']),
        polyLineStr: route['overview_polyline']['points'],
        duration: route['legs'][0]['duration']['text'],
        distance: route['legs'][0]['distance']['text'],
        score: -1
    );
  }
}

class DirectionResponse {
  final List<Route> routes;

  DirectionResponse({this.routes});

  factory DirectionResponse.fromJson(Map<String, dynamic> json) {
    var input = json['routes'];
    List<Route> decodedRoutes = [];
    for (int i = 0; i < input.length; i++) {
      decodedRoutes.add(Route.parseRoute(input[i]));
    }
    return DirectionResponse(routes: decodedRoutes);
  }
}

// API Callers
Future<DirectionResponse> getGMapDirection(LatLng origin, LatLng dest) async {
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

Future<void> getRiskScore(LatLng location) async {
  var now = new DateTime.now();
  final response = await http.get(
      'https://saferoute-d749c.appspot.com//riskScore?hour=${now.hour}&' +
          'latitude=${location.latitude}&longitude=${location.longitude}');

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    print("RiskScore=${json.decode(response.body)['score']}");
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

//Future<DirectionResponse> getPathScore(DirectionResponse paths) async {
//  var now = new DateTime.now();
//  List<String> polyLineStrs = [];
//  paths.routes.forEach((aRoute) => polyLineStrs.add(aRoute.polyLineStr));
//  String req = jsonEncode({"hour": now.hour, "polyline": polyLineStrs});
//  print(req);
//  final response = await http.post(
//      'https://saferoute-d749c.appspot.com//pathRiskScore',
//      body: req,
//      headers: {'Content-Type': 'application/json; charset=UTF-8'});
//  if (response.statusCode == 200) {
//    // If the call to the server was successful, parse the JSON
//    var responseDecode = json.decode(response.body);
//    assert(responseDecode['data'].length == paths.routes.length);
//    for(int i = 0; i > paths.routes.length; i++) {
//      paths.routes[i].score = responseDecode.data[i];
//    }
//    return paths;
//  } else {
//    // If that call was not successful, throw an error.
//    throw Exception('Failed to load post');
//  }
//}

Future<DirectionResponse> getPathScore() async {
  var now = new DateTime.now();
  List<String> polyLineStrs = [];
  pathResponse.routes.forEach((aRoute) => polyLineStrs.add(aRoute.polyLineStr));
  String req = jsonEncode({"hour": now.hour, "polyline": polyLineStrs});
  print(req);
  final response = await http.post(
      'https://saferoute-d749c.appspot.com//pathRiskScore',
      body: req,
      headers: {'Content-Type': 'application/json; charset=UTF-8'});
  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    var responseDecode = json.decode(response.body);
    assert(responseDecode['data'].length == pathResponse.routes.length);
    for(int i = 0; i < pathResponse.routes.length; i++) {
      pathResponse.routes[i].score = responseDecode['data'][i].toDouble();
    }
    print("Query Safe Score: ${responseDecode}");
    return pathResponse;
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
}

// Decoder Util
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
