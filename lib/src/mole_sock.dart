import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class MoleSock {
  late final WebSocketChannel _channel;
  Function onClose;

  MoleSock(address,onConnect,onMsg,this.onClose) {
    _channel = WebSocketChannel.connect(
      Uri.parse(address),
    );
    _channel.ready.then((val){
      _channel.stream.listen((message) {
        onMsg(message);
      }, onDone: () {
        print("Websocket Closed");
        onClose();
      }, onError: (error) {
        print("Websocket Error: ${error.toString()}");
        close();
        onClose();
      });
      onConnect();
    });
  }

  void send(msg) {
    if ((_channel.closeCode ?? 0) > 0) { //print("Closed socket!");
      onClose();
    }
    else { //print(_channel.closeCode);
      _channel.sink.add(msg);
    }
  }

  void close() {
    _channel.sink.close();
  }

}