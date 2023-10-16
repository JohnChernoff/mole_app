import 'dart:math';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'mole_client.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final MoleClient client;
  const HistoryPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  List<BoardArrow> boardArrows = List<BoardArrow>.empty(growable: true);
  String hoverTxt = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
      // action in the IDE, or press "p" in the console), to see the
      // wireframe for each widget.
      //mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ChessBoard(
          size: double.tryParse(MainAxisSize.max.toString()),
          controller: widget.client.historyBoardController,
          boardColor: BoardColor.green,
          arrows: boardArrows,
          boardOrientation: widget.client.orientWhite
              ? PlayerColor.white
              : PlayerColor.black,
        ),
        Container(
            height: 50,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            child: Text(hoverTxt,style: const TextStyle(color: Colors.white),)
        ),
        Expanded(child: GridView(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            mainAxisExtent: 25,
          ),
          children: List.generate(widget.client.currentGame.moves.length, (index) {
            Color playCol = HexColor.fromHex(widget.client.currentGame.moves[index]["selected"]["player"]["play_col"].toString());
            String moveNum = (index ~/ 2 + 1).toString() + (index % 2 == 0 ? "." : "...");
            String moveStr = moveNum + widget.client.currentGame.moves[index]["selected"]["move"]["san"];
            return Container(
                decoration:
                BoxDecoration(border: Border.all(width: 1), color: playCol),
                child: TextButton(
                  onPressed: () {
                    newPosition(index);
                  },
                  onHover: (b) {
                    String newTxt = getVoteTxt(index);
                    setState(() {
                      hoverTxt = newTxt;
                    });
                  },
                  child: Text(moveStr,
                      style: TextStyle(
                          color: playCol == Colors.black
                              ? Colors.white
                              : Colors.black)),
                ));
          }),
        ), ),
      ],
    );
  }

  void newPosition(index) {
    String fen = widget.client.currentGame.moves[index]["fen"].toString();
    widget.client.historyBoardController.loadFen(fen);
    List<BoardArrow> arrows = List<BoardArrow>.empty(growable: true);
    int i = index+1; if (i < widget.client.currentGame.moves.length) {
      for (var move in getMoves(i)) {
        arrows.add(BoardArrow(from: move["from"],to: move["to"],color: move["color"].withOpacity(move["selected"] ? .67 : .36)));
      }
    }
    setState(() {
        boardArrows = arrows;
    });
  }

  List<dynamic> getMoves(i) {
    List<dynamic> moves = List<dynamic>.empty(growable: true);
    moves.add(getMove(widget.client.currentGame.moves[i]["selected"],true));
    for (var alt in widget.client.currentGame.moves[i]["alts"]) {
      moves.add(getMove(alt,false));
    }
    return moves;
  }

  dynamic getMove(json,selected) {
    return {
      "player" : json["player"]["user"]["name"].toString(),
      "san" : json["move"]["san"].toString(),
      "from" :  json["move"]["from"].toString().toLowerCase(),
      "to" :  json["move"]["to"].toString().toLowerCase(),
      "color" : HexColor.fromHex(json["player"]["play_col"].toString()),
      "selected" : selected
    };
  }

  String getVoteTxt(i) {
    String voteTxt = " | ";
    for (var move in getMoves(i)) {
      String pName = move["player"]; if (move["selected"]) pName += "(*)";
      voteTxt += "$pName : ${move["san"]} | ";
    }
    return voteTxt;
  }

}