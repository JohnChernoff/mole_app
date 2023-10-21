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
  final ScrollController scrollControl = ScrollController(); //unused
  List<BoardArrow> boardArrows = List<BoardArrow>.empty(growable: true);
  String hoverTxt = "";
  int movePly = 0;

  void _handleScrollNotification() {
    int move = (widget.client.currentGame.moves.length *
        (scrollControl.position.pixels/scrollControl.position.maxScrollExtent)).floor() - 1;
    newPosition(move);
  }

  @override
  void initState() {
    //scrollControl.addListener(_handleScrollNotification);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
      // action in the IDE, or press "p" in the console), to see the
      // wireframe for each widget.
      //mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
            height: 50,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            child: Text(hoverTxt,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            )
        ),
        ChessBoard(
          size: double.tryParse(MainAxisSize.max.toString()),
          controller: widget.client.historyBoardController,
          boardColor: BoardColor.green,
          arrows: boardArrows,
          boardOrientation: widget.client.orientWhite
              ? PlayerColor.white
              : PlayerColor.black,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () {
              newPosition(movePly-1); setHoverTxt(movePly);
            }, icon: const Icon(Icons.arrow_left)),
            IconButton(onPressed: () {
              newPosition(movePly+1); setHoverTxt(movePly);
            }, icon: const Icon(Icons.arrow_right)),
          ],
        ),
        Expanded(
          child: GridView(
            shrinkWrap: false,
            scrollDirection: Axis.vertical,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              mainAxisExtent: 36,
            ),
            children: List.generate(widget.client.currentGame.moves.length,
                    (index) {
                  Color playCol = HexColor.fromHex(widget.client.currentGame
                      .moves[index]["selected"]["player"]["play_col"]
                      .toString());
                  String moveNum = (index ~/ 2 + 1).toString() +
                      (index % 2 == 0 ? "." : "...");
                  String moveStr = moveNum +
                      widget.client.currentGame.moves[index]["selected"]["move"]["san"];
                  return Container(
                  decoration: BoxDecoration(
                      color: movePly == index ? Colors.black : playCol, //Colors.green : Colors.white,
                      border: Border.all(width: 1)), // color: playCol),
                  child: TextButton(
                    onPressed: () {
                      newPosition(index);
                      setHoverTxt(index);
                    },
                    onHover: (b) {
                      setHoverTxt(index);
                    },
                    child: Text(moveStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(  //fontFamily: "FancyFonts",
                            fontSize: 16,
                            color: movePly == index ? Colors.white : Colors.black)),
                      ));
                }),
          ),
        )
      ],
    );
  }

  void setHoverTxt(index) {
    String newTxt = getVoteTxt(index);
    setState(() {
      hoverTxt = newTxt;
    });
  }

  void newPosition(index) {
    if (widget.client.currentGame.moves.isEmpty) return;
    movePly = index < 0 ? 0 : index;
    if (movePly >= widget.client.currentGame.moves.length) movePly = widget.client.currentGame.moves.length - 1;
    if (movePly < 0) movePly = 0;
    String fen = widget.client.currentGame.moves[movePly]["fen"].toString();
    widget.client.historyBoardController.loadFen(fen);
    List<BoardArrow> arrows = List<BoardArrow>.empty(growable: true);
    int i = movePly + 1;
    if (i < widget.client.currentGame.moves.length) {
      for (var move in getMoves(i)) {
        arrows.add(BoardArrow(
            from: move["from"],
            to: move["to"],
            color: move["color"].withOpacity(move["selected"] ? .67 : .36)));
      }
    }
    setState(() {
      boardArrows = arrows;
    });
  }

  List<dynamic> getMoves(i) {
    List<dynamic> moves = List<dynamic>.empty(growable: true);
    if (widget.client.currentGame.moves.isEmpty) return moves;
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
    String voteTxt = "";
    for (var move in getMoves(i)) {
      String pName = move["player"]; //if (move["selected"]) pName += "(*)";
      voteTxt += "$pName ${move["san"]} : ";
    }
    return (voteTxt.length > 2) ? voteTxt.substring(0,voteTxt.length-2) : voteTxt;
  }

}

class InterpolatedSquare extends CustomPainter {
  Color fromCol;
  Color toCol;
  InterpolatedSquare(this.fromCol,this.toCol);

  @override
  void paint(Canvas canvas, Size size) { //print(size.width); print("$fromCol -> $toCol");
    Paint p = Paint();
    for (double x=0; x<size.width; x++) {
      //print(x); p.blendMode = BlendMode.xor;
      p.color = Color.lerp(fromCol, toCol, x/size.width)!;
      canvas.drawLine(Offset(x,0),Offset(x,size.height),p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}