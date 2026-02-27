import 'package:flutter/material.dart';

class ContactIconsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.phone),
          onPressed: null, 
        ),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.email),
          onPressed: null, 
        ),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.message),
          onPressed: null, 
        ),
      ],
    );
  }
}