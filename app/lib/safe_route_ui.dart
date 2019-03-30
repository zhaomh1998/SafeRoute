// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'page.dart';

final LatLngBounds sydneyBounds = LatLngBounds(
  southwest: const LatLng(-34.022631, 150.620685),
  northeast: const LatLng(-33.571835, 151.325952),
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
    target: LatLng(-33.852, 151.211),
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

  @override
  void initState() {
    super.initState();
  }

  void _onMapChanged() {
    setState(() {
      _extractMapInfo();
    });
  }

  void _onLocationClick(LatLng location) {
    _tappedLocation = location;
  }

  void _onLocationButtonClick() {
    _locationButton++;
  }

  void _onMapLongTapped(LatLng location) {
    _tappedLong = location;
  }

  void _onMapTapped(LatLng location) {
    _tapped = location;
  }

  void _extractMapInfo() {
    _position = mapController.cameraPosition;
    _isMoving = mapController.isCameraMoving;
  }

  @override
  void dispose() {
    mapController.removeListener(_onMapChanged);
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

  Widget _latLngBoundsToggler() {
    return FlatButton(
      child: Text(
        _cameraTargetBounds.bounds == null
            ? 'bound camera target'
            : 'release camera target',
      ),
      onPressed: () {
        setState(() {
          _cameraTargetBounds = _cameraTargetBounds.bounds == null
              ? CameraTargetBounds(sydneyBounds)
              : CameraTargetBounds.unbounded;
        });
      },
    );
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
              padding: const EdgeInsets.all(30.0),
              child: Center(
                  child: Container(
                      width: 350.0,
                      height: 60.0,
//                      margin: new EdgeInsets.all(10.0),
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          const Radius.circular(15.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 5.0,
                            // has the effect of softening the shadow
                            spreadRadius: 0.5,
                            // has the effect of extending the shadow
//                            offset: Offset(
//                              10.0, // horizontal, move right 10
//                              10.0, // vertical, move down 10
//                            ),
                          )
                        ],
//                        borderRadius: new BorderRadius.all(),
//                        gradient: new LinearGradient(...),
                      ),
                      child: TextField())))
        ],
      )),
    ];

    if (mapController != null) {
      columnChildren.add(Text("Reserved space..."));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.addListener(_onMapChanged);
    mapController.onMapLongTapped.add(_onMapLongTapped);
    mapController.onMapTapped.add(_onMapTapped);
    mapController.onLocationButtonClick.add(_onLocationButtonClick);
    mapController.onLocationClick.add(_onLocationClick);
    mapController.onMapLongTapped.add(_onMapLongTapped);
    _extractMapInfo();
    setState(() {});
  }
}
