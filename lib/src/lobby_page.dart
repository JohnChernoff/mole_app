import 'package:flutter/material.dart';
import 'mole_client.dart';

class LobbyPage extends StatelessWidget {

  MoleClient client;
  LobbyPage(this.client, {super.key});
  final Map<int,Color> colorMap = {
    -1 : Colors.grey,
    0 : Colors.black,
    1: Colors.white
  };

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
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
              onPressed: () =>
                  getTitle(context).then((title) => client.newGame(title)),
              child: const Text("New Game")),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton(
              onPressed: () => client.startCurrentGame(),
              child: const Text("Start Game")),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(

                columnSpacing: 16,
                  dataRowColor: MaterialStateProperty.resolveWith((Set states) {
                    return Colors.grey; //Theme.of(context).colorScheme.inversePrimary;
                  }),
                  headingRowColor:
                      MaterialStateProperty.resolveWith((Set states) {
                    return Theme.of(context).colorScheme.onSecondary;
                  }),
                  columns: _gameColumns(),
                  rows: _gameRows()),
            ),
          ),
        )
      ]),
    );
  }

  List<DataColumn> _gameColumns() {
    return [
      const DataColumn(label: Text('Player')),
      const DataColumn(label: Text('Color')),
      const DataColumn(label: Text('Rating')),
      const DataColumn(label: Text('Vote')),
      const DataColumn(label: Text('Accuse')),
      const DataColumn(label: Text('Kick')),
    ];
  }

  List<DataRow> _gameRows() {
    List<DataRow> rows = List<DataRow>.empty(growable: true);
    final List<dynamic> bucket = client.currentGame.jsonData?["bucket"] ?? List.empty();
    final List<dynamic> teams = client.currentGame.jsonData?["teams"] ?? List.empty();
    List<dynamic> players = bucket;
    if (players.isEmpty) {
      for (dynamic team in teams) {
        for (dynamic p in team["players"]) {
          players.add(p);
        }
      }
    }
    for (dynamic player in players) { print("Player: $player");
      String pName = player["user"]["name"];
      Color pColor = HexColor.fromHex(player["play_col"]);
      rows.add(DataRow(cells: [
        DataCell(Text(pName,textScaleFactor: 1.5, style : TextStyle(backgroundColor: Colors.black, color: pColor))),
        DataCell(Container(color: colorMap[player["game_col"]])),
        DataCell(Text(player["user"]["blitz"].toString())),
        DataCell(Text(player["votename"])),
        DataCell(getIconButton(pName, Icons.where_to_vote,"voteoff")),
        DataCell(getIconButton(pName, player["kickable"] ? Icons.remove_circle_outline : Icons.not_interested,"kickoff")),
      ]));
    }
    return rows;
  }

  IconButton getIconButton(String targetName, IconData iconData, String action) {
    return IconButton(
        onPressed: () {
          client.send(action, data: { "player" : targetName, "game" : client.currentGame.title});
        },
        icon: Icon(
          iconData,
        ));
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
