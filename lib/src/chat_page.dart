import 'package:flutter/material.dart';
import 'mole_client.dart';

class ChatPage extends StatefulWidget {
  final MoleClient client;
  static bool lobby = false;
  static bool hideServerMessages = true;

  const ChatPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController scrollController = ScrollController();

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
                value: ChatPage.hideServerMessages,
                onChanged: (newValue) {
                  setState(() {
                    ChatPage.hideServerMessages = newValue ?? false;
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
        CheckboxListTile(
          title: const Text("Show Lobby Messages"),
          value: ChatPage.lobby,
          onChanged: (newValue) {
            setState(() {
              ChatPage.lobby = newValue!;
            });
          },
          controlAffinity:
              ListTileControlAffinity.leading, //  <-- leading Checkbox
        ),
        TextField(
          //controller: inputControl,
          onSubmitted: (txt) {
            widget.client.sendChat(txt, ChatPage.lobby);
          },
        ),
        Expanded(
            child: ListView.builder(
                //shrinkWrap: true,
                controller: scrollController,
                reverse: false,
                scrollDirection: Axis.vertical,
                padding: const EdgeInsets.all(8),
                itemCount: ChatPage.lobby
                    ? widget.client.lobbyLog.length
                    : widget.client.currentGame.chat.length,
                itemBuilder: (BuildContext context, int index) {
                  var chat = ChatPage.lobby
                      ? widget.client.lobbyLog[index]
                      : widget.client.currentGame.chat[index];
                  String color = chat["color"];
                  String msg = chat["msg"];
                  return Container(
                    height: (ChatPage.hideServerMessages &&
                            chat["player"] == "serv" &&
                            !ChatPage.lobby)
                        ? 0
                        : 50,
                    color: HexColor.fromHex(color), //?? Colors.white,
                    child: Center(child: Text(msg)),
                  );
                }))
      ],
    ));
  }

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
}
