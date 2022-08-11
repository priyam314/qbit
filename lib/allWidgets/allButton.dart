import 'package:flutter/material.dart';
import '../allProviders/chat_provider.dart';

class GifButton extends StatelessWidget {
  final String name;
  final Function onPress;
  const GifButton({
    Key? key,
    required this.name,
    required this.onPress
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => onPress(name, TypeMessage.sticker),
      child: Image.asset(
          'images/$name.gif',
          width: 50,
          height: 50,
          fit: BoxFit.cover
      ),
    );
  }
}

class PeerViewButton extends StatefulWidget {
  const PeerViewButton({
    Key? key,

  }) : super(key: key);

  @override
  State<PeerViewButton> createState() => _PeerViewButtonState();
}

class _PeerViewButtonState extends State<PeerViewButton> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

