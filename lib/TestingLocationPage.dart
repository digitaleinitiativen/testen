import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testen/DataModel.dart';
import 'package:testen/main.dart';
import 'package:time_machine/time_machine.dart';
import 'package:timetable/timetable.dart';
import 'package:url_launcher/url_launcher.dart';

class TestingLocationPage extends StatelessWidget {
  final TestingLocation location;

  TestingLocationPage({this.location, Key key}) : super(key: key) {
    saveLocation();
  }

  void saveLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('location', location.id);
  }

  Future<List<TestingSlot>> fetchSlots() async {
    final response = await http
        .post(Uri.parse('$baseUrl/GesundheitRegister/Covid/GetCovidTestDatesMassTest'), body: {'ort': location.id});
    if (response.statusCode == 200) {
      List<dynamic> json = kDebugMode ? jsonDecode(response.body) : jsonDecode(response.body)['contents'];
      print(json);
      return json
          .map((e) => TestingSlot.fromString(e['value'].toString(), int.tryParse(e['key'].toString()), location))
          .toList();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${location.name}'),
      ),
      body: FutureBuilder<List<TestingSlot>>(
        future: fetchSlots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TimetableExample(
                      slots: snapshot.data,
                      isPortrait: MediaQuery.of(context).orientation == Orientation.portrait,
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
                        onPressed: () =>
                            launch('https://vorarlbergtestet.lwz-vorarlberg.at/GesundheitRegister/Covid/Register'),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Zur Anmeldung zum Antigen-Test',
                            style: TextStyle(fontSize: 32),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class TimetableExample extends StatefulWidget {
  final List<TestingSlot> slots;
  final bool isPortrait;

  const TimetableExample({Key key, this.slots, this.isPortrait = true}) : super(key: key);

  @override
  _TimetableExampleState createState() => _TimetableExampleState();
}

class _TimetableExampleState extends State<TimetableExample> {
  TimetableController<BasicEvent> _controller;

  void generateController() {
    int maxTestsPerSlot =
        widget.slots.map((s) => s.availableTestCount).reduce((value, element) => (value > element ? value : element));
    LocalTime startTime = widget.slots
        .map((s) => s.localStartTime.clockTime)
        .reduce((value, element) => (value < element ? value : element));
    LocalTime endTime = widget.slots
        .map((s) => s.localEndTime.clockTime)
        .reduce((value, element) => (value > element ? value : element));

    _controller = TimetableController(
      eventProvider: EventProvider.list(
        widget.slots
            .map((slot) => BasicEvent(
                  id: slot.slotid,
                  title: widget.isPortrait
                      ? slot.availableTestCount.toString()
                      : '${slot.availableTestCount.toString()} Plätze', // ${DateFormat("HH:mm").format(slot.startTime)} - ${DateFormat("HH:mm").format(slot.endTime)}
                  color: Color.lerp(Colors.red, Colors.green, slot.availableTestCount / maxTestsPerSlot),
                  start: slot.localStartTime,
                  end: slot.localEndTime,
                ))
            .toList(),
      ),
      initialTimeRange: InitialTimeRange.range(startTime: startTime, endTime: endTime),
      initialDate: LocalDate.today(),
      visibleRange: VisibleRange.days(widget.isPortrait ? 7 : 14),
      firstDayOfWeek: DayOfWeek.monday,
    );
  }

  @override
  void initState() {
    super.initState();
    generateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Timetable<BasicEvent>(
      controller: _controller,
      theme: TimetableThemeData(
        primaryColor: Colors.teal,
        partDayEventMinimumDuration: Period(minutes: 15),
        partDayEventMinimumDeltaForStacking: Period(minutes: 30),
        partDayEventMinimumHeight: 1,
        dividerColor: widget.isPortrait ? null : Colors.white,
        timeIndicatorColor: widget.isPortrait ? null : Colors.transparent,
      ),
      eventBuilder: (event) {
        return BasicEventWidget(
          event,
          onTap: () => _showSnackBar('Es sind noch ${event.title} Testplätze frei!'),
        );
      },
    );
  }

  void _showSnackBar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }
}
