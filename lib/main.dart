import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:provider/provider.dart';

main()  {
  runApp(const MoleApp());
}

class MoleApp extends StatelessWidget {
  const MoleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => MoleClient("ws://localhost:5555"),
           //MoleClient("wss://molechess.com/server"),
        child: MaterialApp(
          title: 'Mole Chess',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MyHomePage(title: 'Mole Chess!'),
        ),
      );
  }

  onConnected() {
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Pages { login,chess,chat,options }

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;
  Pages selectedPage = Pages.login;

  @override
  Widget build(BuildContext context) {
    var client = context.watch<MoleClient>();
    var colorScheme = Theme
        .of(context)
        .colorScheme;
    Widget page;
    switch (selectedPage) {
      case Pages.login:
        page = LoginPage(client);
        break;
      case Pages.chess:
        page = ChessPage(client);
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The container for the current page, with its background color
    // and subtle switching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(widget.title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.login),
                      label: 'Login',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.table_bar),
                      label: 'Chess',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      selectedIndex = value;
                      selectedPage = Pages.values.elementAt(selectedIndex);
                    });
                  },
                ),
              )
            ],
          );
        },),
    );
  }
}



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

class LoginPage extends StatelessWidget {

  MoleClient client;
  LoginPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Column(
          children: [
            ElevatedButton(
              onPressed: client.lichessToken == "" ? client.loginWithLichess : client.logoutFromLichess,
              child: client.lichessToken == "" ? const Text("Login with Lichess") : const Text("Logout"),
            ),
          ]
      ),
    );
  }
}

