import 'package:flutter/material.dart';

class TrackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Tracks")),
      body: Center(
        child: Text("Track Management Screen", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}