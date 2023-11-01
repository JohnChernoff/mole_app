import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'mole_client.dart';

class OptionsPage extends StatefulWidget {

  final MoleClient client;
  const OptionsPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  @override
  void initState() {
    //scrollControl.addListener(_handleScrollNotification);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ElevatedButton(
              onPressed: widget.client.submitOptions,
              child: const Text("Submit Game Options")),
          SizedBox(
            width: screenWidth,
            height: screenHeight/2.5,
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
          const Text("General Options"),
          Container(
            color: Colors.grey,
            width: screenWidth,
            height: screenHeight/4,
            child: ListView(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sound:"),
                    Checkbox(
                        value: widget.client.sound,
                        onChanged: (b) => setState(() {
                          widget.client.sound = b!;
                          if (!b) widget.client.audio.stop();
                        })
                    ),
                  ],
                ),
                Row(
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
    }
    else if (value.runtimeType == int) {
      //print("New val: $value");
      return Container(
        color: Colors.black,
        height: 36,
        width: 36,
        child: NumberPicker(
          textStyle: const TextStyle(
            color: Colors.yellowAccent
          ),
          axis: Axis.vertical,
          value: value,
          itemHeight: 36,
          itemWidth: 36,
          minValue: 1,
          maxValue: 99,
          onChanged: (i) {
            setState(() {
              widget.client.options[key] = i;
            });
          }


        ),
      );
    }
    else {
      return Text(value);
    }
  }

}
