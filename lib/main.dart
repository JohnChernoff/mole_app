import 'package:flutter/material.dart';
import 'package:mole_app/src/chat_page.dart';
import 'package:mole_app/src/chess_page.dart';
import 'package:mole_app/src/lobby_page.dart';
import 'package:mole_app/src/login_page.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:provider/provider.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

main()  {
  WidgetsFlutterBinding.ensureInitialized();
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
          navigatorKey: globalNavigatorKey,
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

enum Pages { chess,lobby,chat,options,login }

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
      case Pages.lobby:
        page = LobbyPage(client);
        break;
      case Pages.chat:
        page = ChatPage(client);
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
                    //BottomNavigationBarItem(
                    //  icon: Icon(Icons.login),
                    //  label: 'Login',
                    //),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.table_bar),
                      label: 'Chess',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.local_bar),
                      label: 'Lobby',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: 'Chat',
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

