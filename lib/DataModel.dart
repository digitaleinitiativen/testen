import 'package:intl/intl.dart';
import 'package:time_machine/time_machine.dart';

class TestingLocation {
  final String id;
  final String name;
  final String address;

  TestingLocation({this.id, this.name, this.address});

  factory TestingLocation.fromString(String location) {
    List<String> locationParts = location.split(',');
    return TestingLocation(
      id: location,
      name: locationParts[0].trim(),
      address: locationParts.length > 1 ? locationParts[1].trim() : null,
    );
  }
}

class TestingSlot {
  final String id;
  final int slotid;
  final TestingLocation location;
  final DateTime startTime;
  final DateTime endTime;
  final int availableTestCount;

  LocalDateTime get localStartTime => LocalDateTime.dateTime(startTime.add(Duration(hours: 1)));
  LocalDateTime get localEndTime => LocalDateTime.dateTime(endTime.add(Duration(hours: 1)));

  TestingSlot({this.id, this.slotid, this.location, this.startTime, this.endTime, this.availableTestCount});

  factory TestingSlot.fromString(String slot, int slotid, TestingLocation location) {
    String slotRemovedLocation = slot.substring(slot.indexOf(':') + 1, slot.length).trim();
    List<String> splitSlot = slotRemovedLocation.replaceAll(')', '').split(' ');
    return TestingSlot(
      id: slot,
      slotid: slotid,
      location: location,
      startTime: DateFormat("dd.MM.yyyy HH:mm").parse('${splitSlot[1]} ${splitSlot[2]}'),
      endTime: DateFormat("dd.MM.yyyy HH:mm").parse('${splitSlot[1]} ${splitSlot[4]}'),
      availableTestCount: int.tryParse(splitSlot[7]),
    );
  }
}
