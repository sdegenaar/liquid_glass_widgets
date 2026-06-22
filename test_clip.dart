import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -50,
                    left: 0,
                    width: 100,
                    height: 200,
                    child: Container(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
