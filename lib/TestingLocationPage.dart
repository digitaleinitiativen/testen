import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:testen/DataModel.dart';
import 'package:testen/main.dart';
import 'package:time_machine/time_machine.dart';
import 'package:timetable/timetable.dart';
import 'package:url_launcher/url_launcher.dart';

class TestingLocationPage extends StatelessWidget {
  final List<TestingLocation> locations;

  TestingLocationPage({this.locations, Key key}) : super(key: key);

  Future<Map<TestingLocation, List<TestingSlot>>> fetchSlots() async {
    Map<TestingLocation, List<TestingSlot>> testingLocationSlots = {};
    for (TestingLocation location in locations) {
      final response = await http.post(
        Uri.parse('$baseUrl/GesundheitRegister/Covid/GetCovidTestDatesMassTest'),
        body: {'ort': location.id},
      );
      if (response.statusCode == 200) {
        List<dynamic> json = kDebugMode ? jsonDecode(response.body) : jsonDecode(response.body)['contents'];
        testingLocationSlots[location] = json
            .map((e) => TestingSlot.fromString(e['value'].toString(), int.tryParse(e['key'].toString()), location))
            .toList();
      }
    }
    return testingLocationSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Testtermine')),
      body: FutureBuilder<Map<TestingLocation, List<TestingSlot>>>(
        future: fetchSlots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      children: locations
                          .map((location) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Chip(label: Text(location.name)),
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: TimetableExample(
                      locationSlots: snapshot.data,
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
  final Map<TestingLocation, List<TestingSlot>> locationSlots;
  final bool isPortrait;

  const TimetableExample({Key key, this.locationSlots, this.isPortrait = true}) : super(key: key);

  @override
  _TimetableExampleState createState() => _TimetableExampleState();
}

class _TimetableExampleState extends State<TimetableExample> {
  TimetableController<BasicEvent> _controller;

  void generateController() {
    List<TestingSlot> allSlots = widget.locationSlots.values.expand((e) => e).toList();
    int maxTestsPerSlot = allSlots.map((s) => s.availableTestCount).reduce((v, e) => (v > e ? v : e));
    LocalTime startTime = allSlots.map((s) => s.localStartTime.clockTime).reduce((v, e) => (v < e ? v : e));
    LocalTime endTime = allSlots.map((s) => s.localEndTime.clockTime).reduce((v, e) => (v > e ? v : e));

    _controller = TimetableController(
      eventProvider: EventProvider.list(
        allSlots
            .map((slot) => BasicEvent(
                  id: slot.id,
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
          onTap: () => _showSnackBar(event.id),
        );
      },
    );
  }

  void _showSnackBar(String content) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(content),
    ));
  }
}
