import 'dart:convert';
import 'dart:math';
import 'mole_sock.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

class MoleClient {
  late MoleSock sock;
  late String fen;
  ChessBoardController controller = ChessBoardController();
  bool orientWhite = true;
  int counter = 0;

  MoleClient(address) {
    print("Connecting to $address");
    sock = MoleSock(address,_connected);
    fen = controller.getFen();
    //controller.addListener(() {});
  }

  void _connected() {
    print("Connected!");
    send("login","ZugClient");
  }

  void rndMove() {
    counter++;
    List<Move> moves = controller.getPossibleMoves();
    var move =
        controller.getPossibleMoves().elementAt(Random().nextInt(moves.length));
    final promotion = move.promotion;
    if (promotion != null) {
      controller.makeMoveWithPromotion(
          from: move.fromAlgebraic,
          to: move.toAlgebraic,
          pieceToPromoteTo: promotion.name);
    } else {
      controller.makeMove(from: move.fromAlgebraic, to: move.toAlgebraic);
    }
    fen = controller.getFen();
  }

  void handleMove() {
    print(controller.game.history.last.move.fromAlgebraic);
    print(controller.game.history.last.move.toAlgebraic);
    print(controller.game.history.last.move.promotion);
    controller.loadFen(fen);
  }

  void flipBoard() {
    orientWhite = !orientWhite;
  }

  void send(String type, String data) {
    sock.send(jsonEncode( { "type": type, "data": data } ) );
  }

}