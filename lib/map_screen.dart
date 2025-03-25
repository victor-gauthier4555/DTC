import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  List<Marker> allMarkers = [];
  List<Marker> visibleMarkers = [];
  double currentZoom = 12.0;

  @override
  void initState() {
    super.initState();
    loadMarkers();
    mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && event.source == MapEventSource.onMultiFinger) {
        setState(() {
          currentZoom = event.camera.zoom;
          updateVisibleMarkers();
        });
      }
    });
  }

  Future<void> loadMarkers() async {
    final String jsonString = await rootBundle.loadString('assets/terrains_flutter.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    List<Marker> markers = jsonData.map((item) {
      return Marker(
        point: LatLng(item['coordonnees']['lat'], item['coordonnees']['lon']),
        width: 40.0,
        height: 40.0,
        child: Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 30.0,
        ),
      );
    }).toList();

    setState(() {
      allMarkers = markers;
      updateVisibleMarkers();
    });
  }

  void updateVisibleMarkers() {
    setState(() {
      visibleMarkers = allMarkers.where((marker) {
        return currentZoom > 10; // Afficher seulement si le zoom > 10
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte des City-Stades"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(48.8566, 2.3522), // Paris par défaut
              initialZoom: currentZoom,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: visibleMarkers),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  child: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      currentZoom += 1;
                      mapController.move(mapController.camera.center, currentZoom);
                      updateVisibleMarkers();
                    });
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      currentZoom -= 1;
                      mapController.move(mapController.camera.center, currentZoom);
                      updateVisibleMarkers();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





