import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:qbit/allConstants/app_constants.dart';
import 'package:qbit/allConstants/constants.dart';
import 'package:qbit/main.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;
  const FullPhotoPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white: Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.fullPhotoTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
      ),
    );
  }
}
