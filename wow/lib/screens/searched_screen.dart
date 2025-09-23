import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'more_path_screen.dart';
import 'running_start.dart';

class SearchedScreen extends StatefulWidget {
  final Map<String, dynamic> selectedTags; // 쉼표로 연결된 ID 문자열
  final bool onlyFavorites;
  final List<dynamic> searchResults;

  const SearchedScreen({
    Key? key,
    required this.selectedTags,
    required this.onlyFavorites,
    required this.searchResults,
  }) : super(key: key);

  @override
  _SearchedScreenState createState() => _SearchedScreenState();
}

class _SearchedScreenState extends State<SearchedScreen> {
  Map<String, dynamic>? selectedRoute;
  Position? currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _sortRoutes();
  }

  void _sortRoutes() {
    widget.searchResults.sort((a, b) {
      final nameA = a['route_name'] ?? '';
      final nameB = b['route_name'] ?? '';
      return nameA.compareTo(nameB);
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = pos;
    });

    _fitMapBounds();
  }

  void _fitMapBounds() {
    List<LatLng> points = [];

    if (currentPosition != null) {
      points.add(LatLng(currentPosition!.latitude, currentPosition!.longitude));
    }
    if (selectedRoute != null) {
      points.addAll(_convertToLatLngList(selectedRoute!['polyline']));
    }

    if (points.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesToShow = (widget.searchResults.length > 3
        ? widget.searchResults.sublist(0, 3)
        : widget.searchResults)
        .cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('지도 (선택 경로)', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 선택된 태그 표시
          if (widget.selectedTags.values.any((str) => str.isNotEmpty))
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _buildSelectedTagChips(),
              ),
            ),

          // 지도 영역
          Expanded(
            flex: 4,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : const LatLng(35.1796, 129.0756),
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (selectedRoute != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _convertToLatLngList(selectedRoute!['polyline']),
                        color: Colors.blueAccent.shade400,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withOpacity(0.7),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 선택한 경로 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSelectedRouteCard(selectedRoute),
          ),
          const SizedBox(height: 8),

          // 경로 목록
          Expanded(
            flex: 5,
            child: ListView.builder(
              itemCount: routesToShow.length + 1,
              itemBuilder: (context, index) {
                if (index == routesToShow.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MorePathScreen(
                                allRoutes: widget.searchResults.cast<Map<String, dynamic>>(),
                                selectedTags: widget.selectedTags
                                    .map((key, value) => MapEntry(key, value.toString())), // <- 여기서 변환
                                onRouteSelected: (route) {
                                  setState(() {
                                    selectedRoute = route;
                                  });
                                  _fitMapBounds();
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF577590),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('더 많은 경로 보기',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  );
                }

                final route = routesToShow[index];
                final routeName = route['route_name'] ?? '이름 없음';
                final creatorName = route['nickname'] ?? '알 수 없음';
                final favoriteCount = route['favoriteCount'] ?? 0;
                final rating = route['rating'] ?? 0.0;
                final isSelected = selectedRoute == route;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRoute = route;
                    });
                    _fitMapBounds();
                  },
                  child: Card(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    elevation: isSelected ? 4 : 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(routeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('생성자: $creatorName'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: Colors.red, size: 16),
                              const SizedBox(width: 4),
                              Text('$favoriteCount'),
                              const SizedBox(width: 12),
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSelectedTagChips() {
    final List<Widget> chips = [];
    final sortedCategories = widget.selectedTags.keys.toList()..sort();
    for (final category in sortedCategories) {
      final tagStr = widget.selectedTags[category]!; // dynamic 타입 처리
      if (tagStr.isEmpty) continue;

      final tagIds = tagStr.toString().split(',');
      for (final tag in tagIds) {
        String label;
        if (category == '지역') {
          label = tag.replaceAll('/', ' - ');
        } else {
          label = _mapIdToLabel(category, int.tryParse(tag) ?? 0);
        }
        chips.add(
          Chip(
            label: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            backgroundColor: Colors.grey.shade200,
          ),
        );
      }
    }
    return chips;
  }

  String _mapIdToLabel(String category, int id) {
    if (category == '길 유형') {
      switch (id) {
        case 101: return '포장도로';
        case 102: return '비포장도로';
        case 103: return '등산로';
        case 104: return '짧은 산책로';
        case 105: return '긴 산책로';
        case 106: return '운동용 산책로';
      }
    } else if (category == '이동수단') {
      switch (id) {
        case 201: return '걷기';
        case 202: return '뜀걸음';
        case 203: return '자전거';
        case 204: return '휠체어';
        case 205: return '유모차';
      }
    }
    return id.toString();
  }

  Widget _buildSelectedRouteCard(Map<String, dynamic>? route) {
    final routeName = route?['route_name'] ?? '경로를 선택해주세요.';
    final creatorName = route?['nickname'] ?? '-';
    final favoriteCount = route?['favoriteCount'] ?? 0;
    final rating = route?['rating'] ?? 0.0;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('생성자: $creatorName'),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text('$favoriteCount'),
                const SizedBox(width: 12),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: route != null
                    ? () {
                  final polylinePoints = _convertToLatLngList(route['polyline']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RunningStartScreen(
                        userId: creatorName,
                        routeName: routeName,
                        polylinePoints: polylinePoints,
                        intervalMinutes: 0,
                        intervalSeconds: 0,
                      ),
                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: route != null ? const Color(0xFF3CAEA3) : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                ),
                child: const Text('산책 시작'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LatLng> _convertToLatLngList(List<dynamic>? polyline) {
    if (polyline == null) return [];
    return polyline.map<LatLng>((p) {
      if (p is List && p.length >= 2) return LatLng(p[0], p[1]);
      return const LatLng(0, 0);
    }).toList();
  }
}
