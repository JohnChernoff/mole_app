import 'package:flutter/material.dart';
import 'mole_client.dart';

class ChatPage extends StatefulWidget {
  //TextEditingController inputControl = TextEditingController();
  static final ScrollController scrollController = ScrollController();
  final MoleClient client;
  const ChatPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  bool hideServerMessages = false;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          children: [
            CheckboxListTile(
              title: const Text("Hide Server Messages"),
              value: hideServerMessages,
              onChanged: (newValue) {
                setState(() {
                  hideServerMessages = newValue!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
            ),
            ElevatedButton(onPressed: () {
              ChatPage.scrollController.animateTo(
                ChatPage.scrollController.position.maxScrollExtent,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 300),
              );
            }, child: const Text("Scroll")),
            TextField(
              //controller: inputControl,
              onSubmitted: (txt) { //print("Sending: $txt");
                widget.client.sendChat(txt);
              },
            ),
            Expanded(
                child: ListView.builder(  //shrinkWrap: true,
                    controller: ChatPage.scrollController,
                    reverse: false,
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.client.currentGame.chat.length,
                    itemBuilder: (BuildContext context, int index) {
                      var chat = widget.client.currentGame.chat[index];
                      var color = chat["color"];
                      var msg = chat["msg"];
                      //print("From: ${chat["player"]}");
                      return Container(
                        height: (hideServerMessages && chat["player"] == "serv") ? 0 : 50,
                        color: HexColor.fromHex(color.toString()) ?? Colors.white,
                        child: Center(child: Text('$msg')),
                      );
                    }))
          ],
        ));
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
