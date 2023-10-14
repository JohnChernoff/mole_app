import 'package:flutter/material.dart';
import 'mole_client.dart';

class ChatPage extends StatefulWidget {
  final MoleClient client;
  const ChatPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //TextEditingController inputControl = TextEditingController();
  final ScrollController scrollController = ScrollController();

  _scrollDown(int millis) {
    Future.delayed(Duration(milliseconds: millis), () { //allow build time
      if (scrollController.hasClients) { //in case user switched away
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  bool hideServerMessages = false;
  @override
  Widget build(BuildContext context) {
    _scrollDown(500);
    return Center(
        child: Column(
      children: [
        Row(
          children: [
            Flexible(
              child: CheckboxListTile(
                title: const Text("Hide Server Messages"),
                value: hideServerMessages,
                onChanged: (newValue) {
                  setState(() {
                    hideServerMessages = newValue!;
                  });
                },
                controlAffinity:
                    ListTileControlAffinity.leading, //  <-- leading Checkbox
              ),
            ),
            IconButton(
              onPressed: () {
                _scrollDown(50);
              },
              icon: const Icon(Icons.move_down),
            ),
          ],
        ),
        TextField( //controller: inputControl,
              onSubmitted: (txt) {
                widget.client.sendChat(txt);
              },
            ),
            Expanded(
                child: ListView.builder(  //shrinkWrap: true,
                    controller: scrollController,
                    reverse: false,
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.client.currentGame.chat.length,
                    itemBuilder: (BuildContext context, int index) {
                      var chat = widget.client.currentGame.chat[index];
                      String color = chat["color"];
                      String msg = chat["msg"];
                      return Container(
                        height: (hideServerMessages && chat["player"] == "serv") ? 0 : 50,
                        color: HexColor.fromHex(color), //?? Colors.white,
                        child: Center(child: Text(msg)),
                      );
                    }))
          ],
        ));
  }
}


