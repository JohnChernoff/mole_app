import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'mole_client.dart';

class OptionsPage extends StatefulWidget {
  static int pieceSetIndex = 14;
  static String boardColorScheme = "Horsey";
  static Map<String, BoardColorScheme> boardColorSchemes = {
    "Horsey": BoardColorScheme.horsey,
    "Blue": BoardColorScheme.blue,
    "Grey": BoardColorScheme.grey,
    "Green": BoardColorScheme.green,
    "Brown": BoardColorScheme.brown,
    "Canvas": BoardColorScheme.canvas,
    "Wood": BoardColorScheme.wood
  };

  final MoleClient client;

  const OptionsPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  @override
  void initState() {
    super.initState();
  }

  String getAppInfo() {
    return "${widget.client.packageInfo?.appName ?? 'unknown app name'}, "
        "version ${widget.client.packageInfo?.version ?? "?"}";
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Text(getAppInfo()),
        ElevatedButton(
            onPressed: widget.client.submitOptions,
            child: const Text("Submit Game Options")),
        SizedBox(
          width: screenWidth,
          height: screenHeight / 2.25,
          child: ListView.builder(
            itemCount: widget.client.options.keys.length,
            itemBuilder: (context, index) {
              String key = widget.client.options.keys.elementAt(index);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(key),
                  getWidget(key, widget.client.options[key]),
                ],
              );
            },
          ),
        ),
        Container(
          color: Colors.green,
          width: screenWidth,
          height: 50,
          child: const Center(child: Text("General Options")),
        ),
        Expanded(
          //color: Colors.grey,
          //width: screenWidth,
          //height: screenHeight / 4,
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Piece Set:  "),
                  DropdownButton<int>(
                      value: OptionsPage.pieceSetIndex,
                      items: List.generate(PieceSet.values.length, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(PieceSet.values[index].name),
                        );
                      }, growable: false),
                      onChanged: (value) {
                        setState(() {
                          OptionsPage.pieceSetIndex = value ?? 0;
                        });
                      }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Board Style:  "),
                  DropdownButton<String>(
                      value: OptionsPage.boardColorScheme,
                      items: List.generate(
                          OptionsPage.boardColorSchemes.keys.length, (index) {
                        final schemeTxt =
                            OptionsPage.boardColorSchemes.keys.elementAt(index);
                        return DropdownMenuItem(
                          value: schemeTxt,
                          child: Text(schemeTxt),
                        );
                      }, growable: false),
                      onChanged: (value) {
                        setState(() {
                          OptionsPage.boardColorScheme = value ?? "Horsey";
                        });
                      }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sound:"),
                  Checkbox(
                      value: widget.client.sound,
                      onChanged: (b) => setState(() {
                            widget.client.sound = b!;
                            if (!b) widget.client.audio.stop();
                          })),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Delete Lichess Oauth Token: "),
                  IconButton(
                    onPressed: widget.client.logoutFromLichess,
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget getWidget(String key, dynamic value) {
    if (value.runtimeType == bool) {
      return Checkbox(
        value: value,
        onChanged: (b) => setState(() => widget.client.options[key] = b),
      );
    } else if (value.runtimeType == int) {
      //print("New val: $value");
      return Container(
        color: Colors.black,
        height: 36,
        width: 36,
        child: NumberPicker(
            textStyle: const TextStyle(color: Colors.yellowAccent),
            axis: Axis.vertical,
            value: value,
            itemHeight: 36,
            itemWidth: 36,
            minValue: 1,
            //TODO: fix
            maxValue: 99,
            onChanged: (i) {
              setState(() {
                widget.client.options[key] = i;
              });
            }),
      );
    } else {
      return Text(value);
    }
  }
}
