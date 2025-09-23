import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'dart:convert';
import 'searched_screen.dart';

enum CategoryType { region, roadType, transport }

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? activeDropdown;
  bool onlyFavorites = false;
  String _searchQuery = '';
  String? _currentGu;

  // ----------------------------
  // Constants
  // ----------------------------
  static const Map<String, List<String>> tagData = {
    '길 유형': ['포장도로', '비포장도로', '등산로', '짧은 산책로', '긴 산책로', '운동용 산책로'],
    '이동수단': ['걷기', '뜀걸음', '자전거', '휠체어', '유모차'],
  };

  static const List<String> busanGus = [
    '중구','서구','동구','영도구','부산진구','동래구','남구','북구',
    '해운대구','사하구','금정구','강서구','연제구','수영구','사상구','기장군',
  ];

  static const Map<String, List<String>> busanDongs = {
    '중구': ['광복동','남포동','대청동','동광동','보수동','부평동'],
    '서구': ['동대신동','서대신동','암남동','아미동','토성동'],
    '동구': ['초량동','수정동','좌천동','범일동'],
    '영도구': ['남항동','신선동','봉래동','청학동','동삼동'],
    '부산진구': ['부전동','전포동','양정동','범전동','범천동','가야동'],
    '동래구': ['명장동','사직동','안락동','온천동','수안동'],
    '남구': ['대연동','문현동','감만동','용호동','우암동'],
    '북구': ['구포동','덕천동','만덕동','화명동'],
    '해운대구': ['우동','중동','좌동','송정동','재송동'],
    '사하구': ['괴정동','당리동','하단동','장림동','다대동'],
    '금정구': ['장전동','구서동','부곡동','서동','금사동'],
    '강서구': ['명지동','가락동','녹산동','대저1동','대저2동'],
    '연제구': ['연산동'],
    '수영구': ['광안동','남천동','망미동','민락동'],
    '사상구': ['감전동','괘법동','덕포동','모라동'],
    '기장군': ['기장읍','정관읍','일광읍','철마면','장안읍'],
  };

  // 선택된 태그
  final Map<String, Set<String>> selectedTags = {
    '지역': {},
    '길 유형': {},
    '이동수단': {},
  };

  // 매핑: region / roadType / transport → ID
  final Map<String, int> regionToId = {
    '중구/광복동': 1, '중구/남포동': 2, '중구/대청동': 3, '중구/동광동': 4, '중구/보수동': 5, '중구/부평동': 6,
    '서구/동대신동': 7, '서구/서대신동': 8, '서구/암남동': 9, '서구/아미동': 10, '서구/토성동': 11,
    '동구/초량동': 12, '동구/수정동': 13, '동구/좌천동': 14, '동구/범일동': 15,
    '영도구/남항동': 16, '영도구/신선동': 17, '영도구/봉래동': 18, '영도구/청학동': 19, '영도구/동삼동': 20,
    '부산진구/부전동': 21, '부산진구/전포동': 22, '부산진구/양정동': 23, '부산진구/범전동': 24, '부산진구/범천동': 25, '부산진구/가야동': 26,
    '동래구/명장동': 27, '동래구/사직동': 28, '동래구/안락동': 29, '동래구/온천동': 30, '동래구/수안동': 31,
    '남구/대연동': 32, '남구/문현동': 33, '남구/감만동': 34, '남구/용호동': 35, '남구/우암동': 36,
    '북구/구포동': 37, '북구/덕천동': 38, '북구/만덕동': 39, '북구/화명동': 40,
    '해운대구/우동': 41, '해운대구/중동': 42, '해운대구/좌동': 43, '해운대구/송정동': 44, '해운대구/재송동': 45,
    '사하구/괴정동': 46, '사하구/당리동': 47, '사하구/하단동': 48, '사하구/장림동': 49, '사하구/다대동': 50,
    '금정구/장전동': 51, '금정구/구서동': 52, '금정구/부곡동': 53, '금정구/서동': 54, '금정구/금사동': 55,
    '강서구/명지동': 56, '강서구/가락동': 57, '강서구/녹산동': 58, '강서구/대저1동': 59, '강서구/대저2동': 60,
    '연제구/연산동': 61,
    '수영구/광안동': 62, '수영구/남천동': 63, '수영구/망미동': 64, '수영구/민락동': 65,
    '사상구/감전동': 66, '사상구/괘법동': 67, '사상구/덕포동': 68, '사상구/모라동': 69,
    '기장군/기장읍': 70, '기장군/정관읍': 71, '기장군/일광읍': 72, '기장군/철마면': 73, '기장군/장안읍': 74,
  };

  final Map<String, int> roadTypeToId = {
    '포장도로': 101, '비포장도로': 102, '등산로': 103, '짧은 산책로': 104, '긴 산책로': 105, '운동용 산책로': 106,
  };

  final Map<String, int> transportToId = {
    '걷기': 201, '뜀걸음': 202, '자전거': 203, '휠체어': 204, '유모차': 205,
  };

  // ----------------------------
  // Helper Methods
  // ----------------------------
  void toggleDropdown(String name) {
    setState(() {
      if (activeDropdown == name) {
        activeDropdown = null;
      } else {
        activeDropdown = name;
        if (name != '지역') _currentGu = null;
      }
    });
  }

  void toggleTag(String category, String tag) {
    setState(() {
      if (selectedTags[category]!.contains(tag)) {
        selectedTags[category]!.remove(tag);
      } else {
        selectedTags[category]!.add(tag);
      }
    });
  }

  void toggleRegion(String gu, String dong) {
    toggleTag('지역', '$gu/$dong');
  }

  void resetSelection() {
    setState(() {
      for (final key in selectedTags.keys) selectedTags[key]!.clear();
      onlyFavorites = false;
      activeDropdown = null;
      _currentGu = null;
      _searchQuery = '';
    });
  }

  Map<String, List<String>> getFilteredTags() {
    return selectedTags.map((key, value) {
      final sortedList = value.toList()..sort();
      return MapEntry(key, sortedList);
    });
  }

  Map<String, dynamic> getSelectedTagData() {
    final Map<String, dynamic> result = {};
    selectedTags.forEach((category, tags) {
      if (category == '지역') {
        result[category] = tags.map((tag) => regionToId[tag]).whereType<int>().toList();
      } else if (category == '길 유형') {
        result[category] = tags.map((tag) => roadTypeToId[tag]).whereType<int>().toList();
      } else if (category == '이동수단') {
        result[category] = tags.map((tag) => transportToId[tag]).whereType<int>().toList();
      }
    });
    return result;
  }

  // ----------------------------
  // Tag Chip Builder (통합)
  // ----------------------------
  Widget buildTagChip(String category, String tag, {String? gu}) {
    final isSelected = selectedTags[category]!.contains(tag);
    String labelText;

    if (category == '지역' && gu != null) {
      labelText = tag.split('/')[1]; // 동 이름 표시
    } else {
      labelText = tag;
    }

    return FilterChip(
      label: Text(labelText),
      selected: isSelected,
      onSelected: (_) {
        if (category == '지역' && gu != null) {
          toggleRegion(gu, tag.split('/')[1]);
        } else {
          toggleTag(category, tag);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blueAccent.shade100,
      showCheckmark: false,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  List<Widget> buildSelectedTagChips() {
    final List<Widget> chips = [];
    selectedTags.forEach((category, tags) {
      for (final tag in tags) {
        chips.add(buildTagChip(category, tag, gu: category == '지역' ? tag.split('/')[0] : null));
      }
    });
    return chips;
  }

  // ----------------------------
  // UI Builders
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('[현재 지역]', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18)),
            TextButton(
              onPressed: resetSelection,
              child: const Text('초기화', style: TextStyle(color: Colors.blueAccent, fontSize: 14)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                buildDropdownButton('지역'),
                const SizedBox(width: 8),
                buildDropdownButton('길 유형'),
                const SizedBox(width: 8),
                buildDropdownButton('이동수단'),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => onlyFavorites = !onlyFavorites),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: onlyFavorites ? Colors.orangeAccent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Center(
                        child: Text(
                          '즐겨찾기',
                          style: TextStyle(color: onlyFavorites ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  if (activeDropdown != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: _buildDropdownContent(),
                    ),
                  const SizedBox(height: 12),
                  if (selectedTags.values.any((set) => set.isNotEmpty))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Wrap(spacing: 8, runSpacing: 6, children: buildSelectedTagChips()),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _onSearchPressed,
                child: const Text('검색하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdownButton(String title) {
    final bool isActive = activeDropdown == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => toggleDropdown(title),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: isActive ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 6),
              Icon(isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isActive ? Colors.white : Colors.black87),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    switch (activeDropdown) {
      case '지역':
        return buildRegionDropdown();
      case '길 유형':
        return buildSimpleTagGrid('길 유형');
      case '이동수단':
        return buildSimpleTagGrid('이동수단');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildSimpleTagGrid(String category) {
    final tags = tagData[category]!;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags.map((tag) => buildTagChip(category, tag)).toList(),
    );
  }

  Widget buildRegionDropdown() {
    final filteredGus = busanGus.where((gu) {
      return gu.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          busanDongs[gu]!.any((dong) => dong.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: '구 또는 동 검색',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 8),
        ...filteredGus.map((gu) {
          final dongs = busanDongs[gu]!
              .where((dong) => dong.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          final allSelected = dongs.every((dong) => selectedTags['지역']!.contains('$gu/$dong'));

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ExpansionTile(
              initiallyExpanded: false,
              title: Row(
                children: [
                  Icon(Icons.location_city, size: 20, color: Colors.blueAccent),
                  const SizedBox(width: 6),
                  Text(gu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          dongs.forEach((dong) => selectedTags['지역']!.remove('$gu/$dong'));
                        } else {
                          dongs.forEach((dong) => selectedTags['지역']!.add('$gu/$dong'));
                        }
                      });
                    },
                    child: Text(allSelected ? '전체 해제' : '전체 선택', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: dongs.map((dong) {
                      final fullTag = '$gu/$dong';
                      return buildTagChip('지역', fullTag, gu: gu);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // ----------------------------
  // HTTP Search
  // ----------------------------
  Future<void> _onSearchPressed() async {
    final selectedData = getSelectedTagData();
    final url = Uri.parse('${ApiService.baseUrl}/search_routes');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"categories": selectedData, "onlyFavorites": onlyFavorites}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = json.decode(response.body);
        final routes = responseData['routes'] as List<dynamic>;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchedScreen(
              selectedTags: getFilteredTags(),
              onlyFavorites: onlyFavorites,
              searchResults: routes,
            ),
          ),
        );
      } else {
        final error = response.body.isNotEmpty ? json.decode(response.body) : {};
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? "검색 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("에러 발생: $e")),
      );
    }
  }
}
