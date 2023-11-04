import 'package:fast_immutable_collections/fast_immutable_collections.dart';
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
  Map<String,String> headers = {};

  @override
  void initState() {
    super.initState();
    final pgnGame = dc.PgnGame.parsePgn(widget.pgn);
    dc.Chess game = dc.Chess.fromSetup(dc.Setup.parseFen(dc.kInitialFEN));
    headers = pgnGame.headers; //print(headers.toString());

    for (dc.PgnNodeData move in pgnGame.moves.mainline()) {
      List<String> arrowTexts = [];
      final comment = move.comments?.first ?? "";
      final calTxt = comment.split("[%cal ");
      if (calTxt.length > 1) {
        arrowTexts = calTxt[1].replaceAll("]", "").split(",");
      }
      final san = game.parseSan(move.san);
      if (san != null) {
        game = dc.Chess.fromSetup(dc.Setup.parseFen(game.play(san).fen));
        history.add({
          "fen": game.fen,
          "arrows": getArrows(arrowTexts)
        });
      }
    }
  }

  Shape getArrow(String txt) {
    final color = switch(txt.substring(0,1)) {
      "R" => Colors.red,
      "G" => Colors.green,
      "B" => Colors.blue,
      "Y" => Colors.yellow,
      String() => null,
    };
    if (color == null || txt.length != 5) { //TODO: better error checking
      return Circle(color: Colors.black.withOpacity(.1),orig: "a1");
    } else {
      return Arrow(color: color,
        orig: txt.substring(1,3).toLowerCase(),
        dest: txt.substring(3,5).toLowerCase());
    }
  }
  
  ISet<Shape> getArrows(List<String> arrowList) {
    ISet<Shape> arrows = ISet();
    for (String arrowTxt in arrowList) {
      arrows = arrows.add(getArrow(arrowTxt));
    }
    return arrows;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(
        children: [
          Container(
            color: Colors.black,
            width: screenWidth,
            height: 24,
          ),
          Text(headers["Black"].toString() ?? ""),
          Board(
            size: screenWidth / 2,
            data: BoardData(
              interactableSide: InteractableSide.none,
              orientation: Side.white,
              fen: history[ply]["fen"],
              shapes: history[ply]["arrows"]
            ),
          ),
          Text(headers["White"].toString() ?? ""),
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