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

  void loadLoaction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String location = prefs.getString('location');
    print(location);
    if (location != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestingLocationPage(location: TestingLocation.fromString(location)),
          ));
    }
  }

  @override
  void initState() {
    super.initState();
    loadLoaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Testorte Vorarlberg'),
      ),
      body: FutureBuilder<List<TestingLocation>>(
        future: fetchLocations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          return SearchableLocationList(
            itemlist: snapshot.data,
            builder: (location) => ListTile(
              title: Text(location.name),
              subtitle: Text(location.address ?? ''),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestingLocationPage(location: location),
                ),
              ),
            ),
          );
        },
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
