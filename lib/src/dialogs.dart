import 'package:flutter/material.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

class Dialogs {

  static bool dialog = false;

  Dialogs();

  static Future<bool> popup (String txt, { String? imgFilename } ) async {
    dialog = true;
    BuildContext? ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return false;
    return showDialog(
        context: ctx,
        builder: (BuildContext context) {
          return Center(
              child: imgFilename == null
                  ? ConfirmDialog(txt)
                  : NotificationDialog(txt, imgFilename));
        }).then((ok)  {
          dialog = false;
          return ok ?? false;
        });
  }

  static Future<String> getTitle(BuildContext context, String title) async {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: TextDialog(title)
        );
      }).then((value) {
        dialog = false;
        return value ?? "";
      });
  }

}

class TextDialog extends StatelessWidget {
  final TextEditingController titleControl = TextEditingController();

  TextDialog(String title, {super.key}) {
    titleControl.text = title;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        backgroundColor: Colors.green,
        elevation: 10,
        title: const Text('Choose Game Title'),
        children: [
          TextField(
            controller: titleControl,
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, titleControl.text);
            },
            child: const Text('Enter'),
          ),
        ],
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String txt;
  const ConfirmDialog(this.txt, {super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Text(txt),
        SimpleDialogOption(
            onPressed: () { //print("True");
              Navigator.pop(context,true);
            },
            child: const Text('OK')),
        SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context,false);
            },
            child: const Text('Cancel')),
      ],
    );
  }
}

class NotificationDialog extends StatelessWidget {
  final String txt;
  final String imageFilename;
  const NotificationDialog(this.txt, this.imageFilename, {super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        Text(txt),
        Image.asset("assets/images/$imageFilename"),
        SimpleDialogOption(
            onPressed: () { //print("True");
              Navigator.pop(context,true);
            },
            child: const Text('Continue')),
      ],
    );
  }
}