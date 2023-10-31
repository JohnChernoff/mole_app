import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'mole_client.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  final MoleClient client;
  const HistoryPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  ISet<Shape>? boardArrows = ISet();
  List<Widget> hoverVotes = List.empty(growable: true);
  int movePly = 0;
  String fen = initialFen;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: <Widget>[
        Container(
          alignment: Alignment.center,
            height: 36,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: hoverVotes,
            )
        ),
        Board(
          settings: const BoardSettings(
            colorScheme: BoardColorScheme.grey, //boardColorScheme,
            pieceAssets: PieceSet.californiaAssets,
          ),
          size: screenWidth,
          data: BoardData(
            interactableSide: InteractableSide.none,
            orientation: widget.client.orientWhite ? Side.white : Side.black,
            fen: fen,
            shapes: boardArrows,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () {
              newPosition(movePly-1); setHoverVotes(movePly);
            }, icon: const Icon(Icons.arrow_left)),
            IconButton(onPressed: () {
              newPosition(movePly+1); setHoverVotes(movePly);
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
                      color: movePly == index ? Colors.green : Colors.white, //Colors.black : playCol,
                      border: Border.all(width: 1)), // color: playCol),
                  child: TextButton(
                    onPressed: () {
                      newPosition(index);
                      setHoverVotes(index);
                    },
                    onHover: (b) {
                      setHoverVotes(index);
                    },
                    child: Text(moveStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(  //fontFamily: "FancyFonts",
                            fontSize: 12,
                            color: movePly == index ? Colors.white : Colors.black)),
                      ));
                }),
          ),
        )
      ],
    );
  }

  void setHoverVotes(index) {
    final moves = getMoves(index);
    final votes = List.generate(
        moves.length,
        (index) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "${moves[index]['player']}: ${moves[index]['san']}",
                style: TextStyle(color: moves[index]["color"]),
              ),
            ));
    setState(() {
      hoverVotes = votes;
    });
  }

  void newPosition(index) {
    if (widget.client.currentGame.moves.isEmpty) return;
    movePly = index < 0 ? 0 : index;
    if (movePly >= widget.client.currentGame.moves.length) movePly = widget.client.currentGame.moves.length - 1;
    if (movePly < 0) movePly = 0;
    fen = widget.client.currentGame.moves[movePly]["fen"].toString();
    int i = movePly + 1;
    ISet<Shape> arrows = ISet();
    if (i < widget.client.currentGame.moves.length) {
      for (var move in getMoves(i)) {
        arrows = arrows.add(
            Arrow(color: move["color"].withOpacity(move["selected"] ? .67 : .36),
                orig: move["from"],
                dest: move["to"]));
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

}

class InterpolatedSquare extends CustomPainter {
  Color fromCol;
  Color toCol;
  InterpolatedSquare(this.fromCol,this.toCol);

  @override
  void paint(Canvas canvas, Size size) { //print(size.width); print("$fromCol -> $toCol");
    Paint p = Paint();
    for (double x=0; x<size.width; x++) { //print(x); p.blendMode = BlendMode.xor;
      p.color = Color.lerp(fromCol, toCol, x/size.width)!;
      canvas.drawLine(Offset(x,0),Offset(x,size.height),p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}