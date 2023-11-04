import 'package:flutter/material.dart';
import 'package:mole_app/src/chat_page.dart';
import 'package:mole_app/src/chess_page.dart';
import 'package:mole_app/src/dialogs.dart';
import 'package:mole_app/src/game_history_page.dart';
import 'package:mole_app/src/lobby_page.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:mole_app/src/options_page.dart';
import 'package:mole_app/src/splash_page.dart';
import 'package:provider/provider.dart';

const remoteAddress = "wss://molechess.com/server";
const localServer = false;
enum Platforms { android, ios, windows, web }
const platform = Platforms.android;

main()  {
  WidgetsFlutterBinding.ensureInitialized();
  final address = switch(platform) {
    Platforms.android => localServer ? "ws://10.0.2.2:5555" : remoteAddress,
    Platforms.ios => localServer ? "ws://localhost:5555" : remoteAddress,
    Platforms.windows => localServer ? "ws:/localhost:5555" : remoteAddress,
    Platforms.web => localServer ? "ws:/localhost:5555" : remoteAddress,
  };
  runApp(MoleApp(client: MoleClient(address)));
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
          ),
          home: MoleHomePage(client: client),
        ),
      );
  }
}

class MoleHomePage extends StatefulWidget {
  final MoleClient client;
  const MoleHomePage({super.key, required this.client});

  @override
  State<MoleHomePage> createState() => _MoleHomePageState();
}

enum Pages { chess,lobby,chat,options,history,splash }

class _MoleHomePageState extends State<MoleHomePage> {

  @override
  initState() {
    super.initState();
    _countdownLoop(20);
  }

  bool countdown = false;
  var selectedIndex = 0;
  Pages selectedPage = Pages.splash;

  setPage(Pages page) {
    setState(() {
      selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    var client = context.watch<MoleClient>(); // Provider.of(context);
    var colorScheme = Theme
        .of(context)
        .colorScheme;
    Widget page;
    if (selectedPage == Pages.splash && client.isLoggedIn) {
      selectedPage = Pages.lobby;
    }
    switch (selectedPage) {
      case Pages.history:
        page = GameHistoryPage(client);
        break;
      case Pages.chess:
        page = ChessPage(client);
        break;
      case Pages.lobby:
        page = MainLobbyPage(client);
        break;
      case Pages.chat:
        page = ChatPage(client);
        break;
      case Pages.options:
        page = OptionsPage(client);
        break;
      case Pages.splash:
        page = SplashPage(client);
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
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Options',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    if (!Dialogs.dialog) {
                      setState(() {
                        selectedIndex = value;
                        selectedPage = Pages.values.elementAt(selectedIndex);
                        if (selectedPage == Pages.options) {
                          widget.client.send("get_opt",
                              data: widget.client.currentGame.title);
                        }
                      });
                    }
                  },
                ),
              )
            ],
          );
        },),
    );
  }

  void _countdownLoop(int millis) async {
    print("Starting countdown"); //int tick = 0;
    countdown = true;
    while(countdown) {
      int t = selectedPage == Pages.chess ? millis : 1000;
      await Future.delayed(Duration(milliseconds: t), () {
        widget.client.currentGame.countdown["currentTime"] -= (t/1000);
        if (widget.client.currentGame.countdown["currentTime"] < 0) {
          widget.client.currentGame.countdown["currentTime"] = 0.0;
        }
        else {
          if (selectedPage == Pages.chess) {
            widget.client.notifyListeners();
          }
        }
       //print("tick: ${tick++}");
       //print("tick: ${widget.client.currentGame.countdown.toString()}");
      });
    }
    print("Ending countdown");
  }
}

