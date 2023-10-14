import 'package:flutter/material.dart';
import 'mole_client.dart';

class LobbyPage extends StatelessWidget {

  MoleClient client;
  LobbyPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        const Text("Select Game:"),
        DropdownButton(
            value: client.currentGame.title == MoleClient.dummyTitle ? null : client.currentGame.title,
            items:
            client.games.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? title) {
              client.switchGame(title!);
            }),
        ElevatedButton(
            onPressed: () => getTitle(context).then((title) => client.newGame(title)),
            child: const Text("New Game")),
        ElevatedButton(
            onPressed: () => client.startCurrentGame(),
            child: const Text("Start Game")),
      ]),
    );
  }

  Future<String> getTitle(BuildContext context) async {
    TextEditingController titleControl = TextEditingController();
    return await showDialog(
    context: context,
    builder: (BuildContext context) {
      titleControl.text = "Whee";
      return Center(
        child: SimpleDialog(
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
        ),
      );
    });
  }
}
