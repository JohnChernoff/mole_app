import 'package:flutter/material.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' as dc;

class PlayerHistoryPage extends StatefulWidget {

  final MoleClient client;
  const PlayerHistoryPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _PlayerHistoryPage();
}

class _PlayerHistoryPage extends State<PlayerHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.client.playerHistory["player_data"].toString()),
        Expanded(
            child: widget.client.waitMap["history"] ?? false
                ? const Text("Getting history...")
                : ListView(
                children: List.generate(widget.client.playerHistory.length, (index) => PGNViewer(
                    widget.client.playerHistory["pgn_list"][index]["pgn"].toString()
                )))),
      ],
    );
  }
}

class PGNViewer extends StatefulWidget {
  final String pgn;
  const PGNViewer(this.pgn, {super.key});

  @override
  State<StatefulWidget> createState() => _PGNViewer();
}

class _PGNViewer extends State<PGNViewer> {
  List<dynamic> history = [];
  int ply = 0;

  @override
  void initState() {
    super.initState();
    final pgnGame = dc.PgnGame.parsePgn(widget.pgn);
    dc.Chess game = dc.Chess.fromSetup(dc.Setup.parseFen(dc.kInitialFEN));
    print(pgnGame.headers);
    print("***");

    for (dc.PgnNodeData move in pgnGame.moves.mainline()) {
      print(move.comments?.first);
      final san = game.parseSan(move.san);
      if (san != null) {
        game = dc.Chess.fromSetup(dc.Setup.parseFen(game.play(san).fen));
        history.add({
          "fen": game.fen,
          "comments": move.comments?.first
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        children: [
          Board(
            size: screenWidth / 2,
            data: BoardData(
              interactableSide: InteractableSide.none,
              orientation: Side.white,
              fen: history[ply]["fen"],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    if (ply > 0) {
                      setState(() {
                        ply--;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_left)),
              IconButton(
                  onPressed: () {
                    if (ply < (history.length - 1)) {
                      setState(() {
                        ply++;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_right)),
            ],
          ),
        ],
      ),
    );
  }
}