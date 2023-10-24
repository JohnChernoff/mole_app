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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: widget.client.submitOptions,
            child: const Text("Submit")
        ),
        Expanded(
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
