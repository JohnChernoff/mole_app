import 'package:flutter/material.dart';
import 'package:mole_app/src/chat_page.dart';
import 'package:mole_app/src/chess_page.dart';
import 'package:mole_app/src/history_page.dart';
import 'package:mole_app/src/lobby_page.dart';
import 'package:mole_app/src/login_page.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:provider/provider.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

main()  {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MoleApp(client: MoleClient("ws://localhost:5555")));
}

class MoleApp extends StatelessWidget {
  final MoleClient client;
  const MoleApp({super.key,required this.client});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => client, //MoleClient("wss://molechess.com/server"),
        child: MaterialApp(
          navigatorKey: globalNavigatorKey,
          title: 'Mole Chess',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
            useMaterial3: true,
              /* scrollbarTheme: ScrollbarThemeData(
                  thumbVisibility: MaterialStateProperty.all(true),
                  thickness: MaterialStateProperty.all(8),
                  thumbColor: MaterialStateProperty.all(Colors.black),
                  radius: const Radius.circular(8),
                  minThumbLength: 100), */
          ),
          home: MoleHomePage(client: client),
        ),
      );
  }

  onConnected() {
  }
}

class MoleHomePage extends StatefulWidget {
  final MoleClient client;
  const MoleHomePage({super.key, required this.client});

  @override
  State<MoleHomePage> createState() => _MoleHomePageState();
}

enum Pages { history,chess,lobby,chat,options,login }

class _MoleHomePageState extends State<MoleHomePage> {

  _MoleHomePageState() {
    _countdownLoop(20);
  }

  bool countdown = false;
  var selectedIndex = 0;
  Pages selectedPage = Pages.login;

  @override
  Widget build(BuildContext context) {
    var client = context.watch<MoleClient>(); // Provider.of(context);
    var colorScheme = Theme
        .of(context)
        .colorScheme;
    Widget page;
    switch (selectedPage) {
      case Pages.login:
        page = LoginPage(client);
        break;
      case Pages.history:
        page = HistoryPage(client);
        break;
      case Pages.chess:
        page = ChessPage(client,this);
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
        title: Text("${client.userName}: ${client.currentGame.exists ? client.currentGame.title : "-"}"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history),
                      label: 'History',
                    ),
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

  void _countdownLoop(int millis) async {
    print("Starting countdown");
    countdown = true;
    while(countdown) {
      await Future.delayed(Duration(milliseconds: millis), () {
        widget.client.currentGame.countdown["currentTime"] -= (millis/1000);
        if (widget.client.currentGame.countdown["currentTime"] < 0) {
          widget.client.currentGame.countdown["currentTime"] = 0.0;
        }
        else {
          if (selectedPage == Pages.chess) {
           //print("tick: ${widget.client.currentGame.countdown.toString()}");
            widget.client.notifyListeners();
          }
        }
      });
    }
    print("Ending countdown");
  }
}

