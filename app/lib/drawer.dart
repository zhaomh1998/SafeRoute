import 'package:flutter/material.dart';
//import 'package:trust_me/ui/Page/Account.dart';
//import 'package:trust_me/ui/Page/Agreements.dart';
//import 'package:trust_me/ui/Page/Friends.dart';
//import 'package:trust_me/ui/Page/Sign.dart';
//import 'package:trust_me/ui/Page/WebSign.dart';
//import 'package:trust_me/util/AccountHandle.dart';
//import 'package:trust_me/ui/Page/Signature.dart';
//import 'package:trust_me/util/AgreementHandle.dart';

getDrawer(currentBuildContext) => new Drawer(
    child: ListView(
//      padding: EdgeInsets.zero,
      children: <Widget>[
        Container(
          height: 150.0,
          child: new UserAccountsDrawerHeader(
            accountName: new Text(
              "Safe Route",
              style: TextStyle(fontSize: 20.0),
            ),
            accountEmail: null,
            currentAccountPicture: Stack(
              alignment: FractionalOffset.center,
              children: <Widget>[
                Icon(
                  Icons.brightness_1,
                  color: Color(0xA041b3a3),
                  size: 70.0,
                ),
                Text(
                  "S",
                  style: TextStyle(fontSize: 30.0, color: Colors.white),
                )
              ],
            ),
          ),
        ),
        ListTile(
          title: Row(children: <Widget>[
            Icon(Icons.navigation),
            Padding(padding: EdgeInsets.all(10.0)),
            Text("Navigate")
          ]),
//          onTap: () => Navigator.pushReplacement(currentBuildContext,
//              MaterialPageRoute(builder: (context) => Sign())),
        ),
        ListTile(
          title: Row(children: <Widget>[
            Icon(Icons.remove_red_eye),
            Padding(padding: EdgeInsets.all(10.0)),
            Text("Check Area")
          ]),
//          onTap: () => Navigator.pushReplacement(currentBuildContext,
//              MaterialPageRoute(builder: (context) => Agreements())),
        ),
        ListTile(
          title: Row(children: <Widget>[
            Icon(Icons.settings),
            Padding(padding: EdgeInsets.all(10.0)),
            Text("Setting")
          ]),
//          onTap: () => Navigator.pushReplacement(currentBuildContext,
//              MaterialPageRoute(builder: (context) => Signature())),
        ),
      ],
    ));
