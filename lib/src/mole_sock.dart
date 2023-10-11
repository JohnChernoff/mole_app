import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class MoleSock {
  late final WebSocketChannel _channel;

  MoleSock(address,onConnect,onMsg) {
    _channel = WebSocketChannel.connect(
      Uri.parse(address),
    );
    _channel.ready.then((val){
      _channel.stream.listen((message) {
        onMsg(message);
      });
      onConnect();
    });
  }

  void send(msg) {
    _channel.sink.add(msg);
  }

  void close() {
    _channel.sink.close();
  }

}