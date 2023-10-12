import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'mole_client.dart';
import 'package:flutter/material.dart';

class ChessPage extends StatelessWidget {

  MoleClient client;
  ChessPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    //var client = context.watch<MoleClient>();
    // This method is rerun every time setState is called
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
        // action in the IDE, or press "p" in the console), to see the
        // wireframe for each widget.
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ChessBoard(
            onMove: client.handleMove,
            size: double.tryParse(MainAxisSize.max.toString()),
            controller: client.controller,
            boardColor: BoardColor.green,
            boardOrientation: client.orientWhite
                ? PlayerColor.white
                : PlayerColor.black,
          ),
          const Text(
            'You have pushed the button this many times:',
          ),
          Text(
            '${client.counter}',
            style: Theme
                .of(context)
                .textTheme
                .headlineMedium,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.amber,
            ),
            onPressed: () { client.rndMove(); },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.question_mark_rounded),
                Text(" Random Move"),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => { client.flipBoard()},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.invert_colors),
                Text(" Flip"),
              ],
            ),
          )
        ],
      ),
    );
  }
}