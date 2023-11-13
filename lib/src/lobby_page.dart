import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:mole_app/src/player_history_page.dart';
import 'package:mole_app/src/top_page.dart';
import 'dialogs.dart';
import 'mole_client.dart';

enum LobbyPages {lobby,top,playerHistory}

class MainLobbyPage extends StatefulWidget {
  final MoleClient client;
  const MainLobbyPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState()  => _MainLobbyPageState();
}

class _MainLobbyPageState extends State<MainLobbyPage> {
  LobbyPages page = LobbyPages.lobby;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            page == LobbyPages.lobby
                ? ElevatedButton(
                    onPressed: () {
                      widget.client.getTop(10);
                      setState(() {
                        page = LobbyPages.top;
                      });
                    },
                    child: const Text("Top"),
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        page = LobbyPages.lobby;
                      });
                    },
                    child: const Text("Lobby"),
                  ),
            page == LobbyPages.lobby
                ? ElevatedButton(
                    onPressed: () {
                      widget.client.getPlayerHistory(widget.client.userName);
                      setState(() {
                        page = LobbyPages.playerHistory;
                      });
                    },
                    child: const Text("History"),
                  )
                : const SizedBox(),
          ],
        ),
        Expanded(
            child: switch (page) {
          LobbyPages.lobby => LobbyPage(widget.client),
          LobbyPages.top => TopPage(widget.client),
          LobbyPages.playerHistory => PlayerHistoryPage(widget.client),
        }),
      ],
    );
  }
}

class LobbyPage extends StatelessWidget {

  final Map<int,Color> colorMap = {
    -1 : Colors.grey,
    0 : Colors.black,
    1: Colors.white
  };

  final MoleClient client;
  LobbyPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Game:"),
            const SizedBox(width: 8,),
            DropdownButton(
                value: client.currentGame.exists ? client.currentGame.title : null,
                items: [
                  const DropdownMenuItem<String>(value: noGameTitle, child: Text(noGameTitle))
                ].concat(client.games.keys.map<DropdownMenuItem<String>>((String title) {  //print("Adding: $title");
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Text(title),
                  );
                }).toList()),
                onChanged: (String? title) {
                  client.switchGame(title); client.update();
                }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                style: getButtonStyle(Colors.greenAccent,Colors.redAccent),
                onPressed: () => Dialogs.getTitle(context, client.userName).then((title) => client.newGame(title)),
                child: const Text("New"),
              )),
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                  style: getButtonStyle(Colors.redAccent, Colors.purpleAccent),
                  onPressed: () => client.gameCmd("status"),
                  child: const Text("Start")),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                  style: getButtonStyle(Colors.blueAccent, Colors.greenAccent),
                  onPressed: () => client.gameCmd("joinGame"),
                  child: const Text("Join")),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                  style: getButtonStyle(Colors.black12, Colors.orangeAccent),
                  onPressed: () => client.gameCmd("partGame"),
                  child: const Text("Leave")),
            ),],
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
    if (!client.currentGame.exists) return rows;
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
    for (dynamic player in players) { //print("Player: $player");
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

  ButtonStyle getButtonStyle(Color c1, Color c2) {
    return ButtonStyle(backgroundColor:
        MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) return c2;
      return c1;
    }));
  }


}
