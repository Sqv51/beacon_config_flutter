import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'custom_drawer.dart';

class DeviceInfo {
  int? rssi;
  String deviceName;
  String? macAddress;
  String? approxDistance;
  String? advertisementData;
  bool isSelected;

  DeviceInfo({
    this.rssi,
    required this.deviceName,
    this.macAddress,
    this.approxDistance,
    this.advertisementData,
    this.isSelected = false,
  });
}

class Device {
  final String mac;
  int rssi;
  String? name;
  String? advData;
  double distance;
  DateTime lastResponseTime;

  Device({
    required this.mac,
    required this.rssi,
    this.name,
    this.advData,
    required this.distance,
    required this.lastResponseTime,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      mac: json['mac'],
      rssi: json['rssi'],
      name: json['name'],
      advData: json['advData'],
      distance: json['distance'].toDouble(),
      lastResponseTime: DateTime.now(),
    );
  }
}

class DevicesResponse {
  final List<Device> devices;

  DevicesResponse({required this.devices});

  factory DevicesResponse.fromJson(Map<String, dynamic> json) {
    var list = json['devices'] as List;
    List<Device> devicesList = list.map((i) => Device.fromJson(i)).toList();
    return DevicesResponse(devices: devicesList);
  }
}

DevicesResponse parseDevicesResponse(String responseBody) {
  final parsed = jsonDecode(responseBody);
  return DevicesResponse.fromJson(parsed);
}

String cleanJsonString(String jsonString) {
  return jsonString.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
}

class RoomPage extends StatefulWidget {
  const RoomPage({Key? key}) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class DeviceDetailWidget extends StatelessWidget {
  final Device device;

  const DeviceDetailWidget({Key? key, required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${device.name ?? 'Unknown'}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('MAC: ${device.mac}'),
            Text('RSSI: ${device.rssi}'),
            Text('Distance: ${device.distance.toStringAsFixed(2)}m'),
            Text('Adv Data: ${device.advData ?? 'N/A'}'),
            Text('Last Response: ${device.lastResponseTime}'),
          ],
        ),
      ),
    );
  }
}

class _RoomPageState extends State<RoomPage> {
  final String devicesUrl = 'http://10.34.82.169/getDevices';
  Map<String, Device> devices = {};
  Map<String, int> deviceNotSeenCount = {};

  @override
  void initState() {
    super.initState();
    fetchDevicesPeriodically();
  }

  void fetchDevicesPeriodically() async {
    for (int i = 0; i < 10; i++) {
      await fetchDevices();
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> fetchDevices() async {
    try {
      final response = await http.get(Uri.parse(devicesUrl));
      if (response.statusCode == 200) {
        DevicesResponse devicesResponse = parseDevicesResponse(cleanJsonString(response.body));
        setState(() {
          var currentTime = DateTime.now();
          devicesResponse.devices.forEach((device) {
            if (devices.containsKey(device.mac)) {
              devices[device.mac]!.rssi = device.rssi;
              devices[device.mac]!.name = device.name;
              devices[device.mac]!.advData = device.advData;
              devices[device.mac]!.distance = device.distance;
              devices[device.mac]!.lastResponseTime = currentTime;
            } else {
              devices[device.mac] = device;
            }
          });
        });
      } else {
        print('Failed to fetch devices: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch devices: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room List'),
      ),
      drawer: CustomDrawer(),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          Device device = devices.values.elementAt(index);
          return DeviceDetailWidget(device: device);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new room functionality
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) => ElevatedButton(
            onPressed: () {
              // Button press functionality
            },
            child: Text('Button ${index + 1}'),
          )),
        ),
      ),
    );
  }
}