import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testen/TestingLocationPage.dart';
import 'package:testen/DataModel.dart';
import 'package:testen/main.dart';

class LocationListPage extends StatefulWidget {
  @override
  _LocationListPageState createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage> {
  List<TestingLocation> locations = [];

  Future<List<TestingLocation>> fetchLocations() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/GesundheitRegister/Covid/GetCovidTestLocationMassTest?betriebe=0'));
      if (response.statusCode == 200) {
        List<dynamic> json = kDebugMode ? jsonDecode(response.body) : jsonDecode(response.body)['contents'];
        return json.map((e) => e['key'].toString()).map((e) => TestingLocation.fromString(e)).toList();
      }
    } catch (e) {
      print(e);
    }

    return null;
  }

  void saveLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('location', locations.map((loc) => loc.id).toList());
  }

  void loadLoaction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> loadedLocations = prefs.getStringList('location');
    print(loadedLocations);
    if (loadedLocations == null) return;
    if (loadedLocations.isEmpty) return;
    List<TestingLocation> testingLocations =
        loadedLocations.map((location) => TestingLocation.fromString(location)).toList();
    locations = testingLocations;
    Navigator.push(context, MaterialPageRoute(builder: (context) => TestingLocationPage(locations: testingLocations)));
  }

  @override
  void initState() {
    super.initState();
    loadLoaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Testorte Vorarlberg')),
      body: FutureBuilder<List<TestingLocation>>(
        future: fetchLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildLocationChips(context),
              ),
              Expanded(
                child: SearchableLocationList(
                  itemlist: snapshot.data,
                  builder: (location) => ListTile(
                    title: Text(location.name),
                    subtitle: Text(location.address ?? ''),
                    onTap: () {
                      if (!locations.map((e) => e.id).contains(location.id)) {
                        setState(() {
                          locations.add(location);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationChips(BuildContext context) {
    Widget chips = Wrap(
      children: locations
          .map((location) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: Chip(
                  label: Text(location.name),
                  onDeleted: () => setState(() {
                    locations.remove(location);
                  }),
                ),
              ))
          .toList(),
    );
    Widget button = ElevatedButton(
      style: ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
      onPressed: () async {
        saveLocation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TestingLocationPage(locations: locations)),
        );
      },
      child: Text('Testtermine anzeigen'),
    );

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chips,
          SizedBox(height: 8),
          button,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: chips),
          FractionallySizedBox(heightFactor: 1.0, child: button),
        ],
      ),
    );
  }
}

class SearchableLocationList extends StatefulWidget {
  final List<TestingLocation> itemlist;
  final Widget Function(TestingLocation) builder;

  SearchableLocationList({Key key, @required this.itemlist, @required this.builder}) : super(key: key);

  @override
  _SearchableLocationListState createState() => new _SearchableLocationListState();
}

class _SearchableLocationListState extends State<SearchableLocationList> {
  TextEditingController editingController = TextEditingController();
  List<TestingLocation> items = [];

  @override
  void initState() {
    items.addAll(widget.itemlist);
    super.initState();
  }

  void filterSearchResults(String query) {
    List<TestingLocation> dummySearchList = [];
    dummySearchList.addAll(widget.itemlist);
    if (query.isNotEmpty) {
      List<TestingLocation> dummyListData = [];
      dummySearchList.forEach((item) {
        if (item.id.toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(widget.itemlist);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              filterSearchResults(value);
            },
            controller: editingController,
            decoration: InputDecoration(
                labelText: "Search",
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0)))),
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return widget.builder(items[index]);
            },
          ),
        ),
      ],
    );
  }
}
