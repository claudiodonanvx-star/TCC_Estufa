import 'package:flutter/material.dart';
import 'package:flutter_application_1/contactIconsRow.dart';
import 'package:flutter_application_1/profile.dart';

class ProfilePage extends StatelessWidget {
  final Profile profile;

  ProfilePage({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(profile.imagePath),
          ),
          SizedBox(height: 16),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ContactIconsRow(),
          SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                profile.about,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
