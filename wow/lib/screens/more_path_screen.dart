import 'package:flutter/material.dart';

class MorePathScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allRoutes; // 전체 경로
  final Map<String, String>? selectedTags; // 현재 선택된 태그
  final Function(Map<String, dynamic>) onRouteSelected; // 선택 시 콜백

  const MorePathScreen({
    Key? key,
    required this.allRoutes,
    this.selectedTags,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  _MorePathScreenState createState() => _MorePathScreenState();
}

class _MorePathScreenState extends State<MorePathScreen> {
  String _selectedAlgorithm = '연관성';
  final List<String> _algorithms = [
    '연관성',
    '좋아요 높은순',
    '좋아요 낮은순',
    '즐겨찾기 높은순',
    '즐겨찾기 낮은순',
  ];

  late List<Map<String, dynamic>> routesToShow;

  @override
  void initState() {
    super.initState();
    routesToShow = widget.allRoutes.toList();
    _sortRoutes();
  }

  void _sortRoutes() {
    setState(() {
      switch (_selectedAlgorithm) {
        case '연관성':
          routesToShow.sort((a, b) =>
              (a['route_name'] ?? '').compareTo(b['route_name'] ?? ''));
          break;
        case '좋아요 높은순':
          routesToShow.sort((b, a) =>
              (a['favoriteCount'] ?? 0).compareTo(b['favoriteCount'] ?? 0));
          break;
        case '좋아요 낮은순':
          routesToShow.sort((a, b) =>
              (a['favoriteCount'] ?? 0).compareTo(b['favoriteCount'] ?? 0));
          break;
        case '즐겨찾기 높은순':
          routesToShow.sort((b, a) =>
              (a['rating'] ?? 0.0).compareTo(b['rating'] ?? 0.0));
          break;
        case '즐겨찾기 낮은순':
          routesToShow.sort((a, b) =>
              (a['rating'] ?? 0.0).compareTo(b['rating'] ?? 0.0));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: DropdownButton<String>(
          value: _selectedAlgorithm,
          dropdownColor: Colors.black,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedAlgorithm = newValue;
                _sortRoutes();
              });
            }
          },
          items: _algorithms.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
      body: ListView.builder(
        itemCount: routesToShow.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final route = routesToShow[index];
          return _buildRouteCard(context, route);
        },
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, Map<String, dynamic> route) {
    final routeName = route['route_name'] ?? '이름 없음';
    final creatorName = route['nickname'] ?? '알 수 없음';
    final favoriteCount = route['favoriteCount'] ?? 0;
    final rating = route['rating'] ?? 0.0;

    // selectedTags를 기반으로 태그 표시
    final tagWidgets = _buildTagWidgets(route['selectedTags'] ?? {});

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // 이미지 플레이스홀더
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(right: 12),
                  child: const Icon(Icons.route, color: Colors.white70),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: const TextStyle(
                          color: Color(0xFF2D2D2D),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('생성자: ',
                              style: TextStyle(color: Colors.grey)),
                          Text(creatorName,
                              style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 4),
                          Text('$favoriteCount',
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(width: 12),
                          const Icon(Icons.star,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onRouteSelected(route);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3CAEA3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('선택',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (tagWidgets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tagWidgets,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTagWidgets(Map<String, String> selectedTags) {
    final List<Widget> chips = [];
    selectedTags.forEach((category, value) {
      if (value.isEmpty) return;
      final tagList = value.split(',');
      for (final tag in tagList) {
        chips.add(
          Chip(
            label: Text(_mapIdToLabel(category, tag),
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
            backgroundColor: Colors.grey.shade200,
          ),
        );
      }
    });
    return chips;
  }

  String _mapIdToLabel(String category, String idStr) {
    final id = int.tryParse(idStr);
    if (category == '길 유형') {
      switch (id) {
        case 101:
          return '포장도로';
        case 102:
          return '비포장도로';
        case 103:
          return '등산로';
        case 104:
          return '짧은 산책로';
        case 105:
          return '긴 산책로';
        case 106:
          return '운동용 산책로';
      }
    } else if (category == '이동수단') {
      switch (id) {
        case 201:
          return '걷기';
        case 202:
          return '뜀걸음';
        case 203:
          return '자전거';
        case 204:
          return '휠체어';
        case 205:
          return '유모차';
      }
    } else if (category == '지역') {
      return idStr.replaceAll('/', ' - ');
    }
    return idStr;
  }
}
