import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'more_path_screen.dart';
import 'running_start.dart';

class SearchedScreen extends StatefulWidget {
  final Map<String, dynamic> selectedTags; // { "지역": [1,2], "길 유형": [101], "이동수단": [201] }
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

  // ID → 이름 매핑
  final Map<int, String> idToRegion = {
    1: '중구/광복동', 2: '중구/남포동', 3: '중구/대청동', 4: '중구/동광동', 5: '중구/보수동', 6: '중구/부평동',
    7: '서구/동대신동', 8: '서구/서대신동', 9: '서구/암남동', 10: '서구/아미동', 11: '서구/토성동',
    12: '동구/초량동', 13: '동구/수정동', 14: '동구/좌천동', 15: '동구/범일동',
    16: '영도구/남항동', 17: '영도구/신선동', 18: '영도구/봉래동', 19: '영도구/청학동', 20: '영도구/동삼동',
    21: '부산진구/부전동', 22: '부산진구/전포동', 23: '부산진구/양정동', 24: '부산진구/범전동', 25: '부산진구/범천동', 26: '부산진구/가야동',
    27: '동래구/명장동', 28: '동래구/사직동', 29: '동래구/안락동', 30: '동래구/온천동', 31: '동래구/수안동',
    32: '남구/대연동', 33: '남구/문현동', 34: '남구/감만동', 35: '남구/용호동', 36: '남구/우암동',
    37: '북구/구포동', 38: '북구/덕천동', 39: '북구/만덕동', 40: '북구/화명동',
    41: '해운대구/우동', 42: '해운대구/중동', 43: '해운대구/좌동', 44: '해운대구/송정동', 45: '해운대구/재송동',
    46: '사하구/괴정동', 47: '사하구/당리동', 48: '사하구/하단동', 49: '사하구/장림동', 50: '사하구/다대동',
    51: '금정구/장전동', 52: '금정구/구서동', 53: '금정구/부곡동', 54: '금정구/서동', 55: '금정구/금사동',
    56: '강서구/명지동', 57: '강서구/가락동', 58: '강서구/녹산동', 59: '강서구/대저1동', 60: '강서구/대저2동',
    61: '연제구/연산동',
    62: '수영구/광안동', 63: '수영구/남천동', 64: '수영구/망미동', 65: '수영구/민락동',
    66: '사상구/감전동', 67: '사상구/괘법동', 68: '사상구/덕포동', 69: '사상구/모라동',
    70: '기장군/기장읍', 71: '기장군/정관읍', 72: '기장군/일광읍', 73: '기장군/철마면', 74: '기장군/장안읍',
  };

  final Map<int, String> idToRoadType = {
    101: '포장도로', 102: '비포장도로', 103: '등산로', 104: '짧은 산책로', 105: '긴 산책로', 106: '운동용 산책로',
  };

  final Map<int, String> idToTransport = {
    201: '걷기', 202: '뜀걸음', 203: '자전거', 204: '휠체어', 205: '유모차',
  };

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
          if (widget.selectedTags.values.any((v) => v.isNotEmpty))
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

          // 지도
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

          // 선택된 경로 카드
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
                                    .map((key, value) => MapEntry(key, value.toString())),
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
                          const SizedBox(height: 2),
                          Text('지역: ${idToRegion[route['region_id']] ?? '-'}'),
                          Text('길 유형: ${idToRoadType[route['road_type_id']] ?? '-'}'),
                          Text('이동수단: ${idToTransport[route['transport_id']] ?? '-'}'),
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

    widget.selectedTags.forEach((category, ids) {
      if (ids is List && ids.isNotEmpty) {
        for (final id in ids) {
          String label;
          if (category == '지역') {
            label = idToRegion[id] ?? '';
          } else if (category == '길 유형') {
            label = idToRoadType[id] ?? '';
          } else if (category == '이동수단') {
            label = idToTransport[id] ?? '';
          } else {
            label = id.toString();
          }

          if (label.isNotEmpty) {
            chips.add(
              Chip(
                label: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                backgroundColor: Colors.grey.shade200,
              ),
            );
          }
        }
      }
    });

    return chips;
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
            const SizedBox(height: 4),
            Text('지역: ${idToRegion[route?['region_id']] ?? '-'}'),
            Text('길 유형: ${idToRoadType[route?['road_type_id']] ?? '-'}'),
            Text('이동수단: ${idToTransport[route?['transport_id']] ?? '-'}'),
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
