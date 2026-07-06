import 'dart:math';

/// All recognised areas / localities of Belagavi (Belgaum) city.
/// Coordinates are verified from OpenStreetMap / Google Maps reference points
/// so that the centroid-fallback "nearest area" function is accurate.

class BelgaumArea {
  final String name;
  final String group;
  final double lat;
  final double lng;
  const BelgaumArea(this.name, this.group, this.lat, this.lng);
}

const _c = 'Central & Popular';
const _g = 'Growing Residential';
const _i = 'Industrial & Commercial';
const _v = 'Villages / Outskirts';

const belgaumAreas = <BelgaumArea>[
  // ── Central & Popular Residential ─────────────────────────────────────────
  BelgaumArea('Tilakwadi',            _c, 15.8638, 74.5086),
  BelgaumArea('Hindwadi',             _c, 15.8560, 74.5010),
  BelgaumArea('Shahapur',             _c, 15.8672, 74.5148),
  BelgaumArea('Vadgaon',              _c, 15.8728, 74.5063),
  BelgaumArea('Camp',                 _c, 15.8490, 74.5091),
  BelgaumArea('Bhagyanagar',          _c, 15.8572, 74.5048),
  BelgaumArea('Ganeshpur',            _c, 15.8548, 74.5135),
  BelgaumArea('Sadashiv Nagar',       _c, 15.8618, 74.5072),
  BelgaumArea('Mahantesh Nagar',      _c, 15.8530, 74.5058),
  BelgaumArea('Hanuman Nagar',        _c, 15.8602, 74.5041),
  BelgaumArea('Rani Chennamma Nagar', _c, 15.8476, 74.5062),
  BelgaumArea('Nehru Nagar',          _c, 15.8512, 74.5098),
  BelgaumArea('Shahu Nagar',          _c, 15.8482, 74.5085),
  BelgaumArea('Subhash Nagar',        _c, 15.8505, 74.5016),
  BelgaumArea('Shivaji Nagar',        _c, 15.8525, 74.5035),
  BelgaumArea('Gandhi Nagar',         _c, 15.8540, 74.4952),
  BelgaumArea('Sahyadri Nagar',       _c, 15.8435, 74.5010),
  BelgaumArea('Kuvempu Nagar',        _c, 15.8452, 74.4988),
  BelgaumArea('Jadhav Nagar',         _c, 15.8705, 74.5158),

  // ── Growing Residential ────────────────────────────────────────────────────
  BelgaumArea('Angol',                _g, 15.8382, 74.4935),
  BelgaumArea('Nanawadi',             _g, 15.8420, 74.5015),
  BelgaumArea('Kanbargi',             _g, 15.8762, 74.5268),
  BelgaumArea('Ujwal Nagar',          _g, 15.8658, 74.4948),
  BelgaumArea('Kaveri Nagar',         _g, 15.8574, 74.4928),
  BelgaumArea('Mahadev Nagar',        _g, 15.8495, 74.5148),
  BelgaumArea('Azam Nagar',           _g, 15.8455, 74.5072),
  BelgaumArea('Guruprasad Nagar',     _g, 15.8550, 74.5198),
  BelgaumArea('Chidambar Nagar',      _g, 15.8515, 74.5168),
  BelgaumArea('Vijayanagar',          _g, 15.8472, 74.4862),
  BelgaumArea('Vaibhav Nagar',        _g, 15.8435, 74.4878),
  BelgaumArea('Bhavani Nagar',        _g, 15.8642, 74.4882),
  BelgaumArea('Laxmi Nagar',          _g, 15.8558, 74.4912),
  BelgaumArea('Ayodhya Nagar',        _g, 15.8415, 74.5102),

  // ── Industrial & Commercial ────────────────────────────────────────────────
  BelgaumArea('Udyambag',             _i, 15.8392, 74.5148),
  BelgaumArea('Auto Nagar',           _i, 15.8345, 74.5092),
  BelgaumArea('Angol Industrial Estate', _i, 15.8352, 74.4938),
  BelgaumArea('Machhe',               _i, 15.8912, 74.4968),
  BelgaumArea('Sambra',               _i, 15.9095, 74.4758),
  BelgaumArea('Kanbargi Industrial Area', _i, 15.8815, 74.5312),

  // ── Villages / Outskirts ──────────────────────────────────────────────────
  BelgaumArea('Hindalga',             _v, 15.8298, 74.5352),
  BelgaumArea('Kakati',               _v, 15.9215, 74.5148),
  BelgaumArea('Kangrali Khurd',       _v, 15.8195, 74.4658),
  BelgaumArea('Kangrali BK',          _v, 15.8142, 74.4705),
  BelgaumArea('Savgaon',              _v, 15.8808, 74.4762),
  BelgaumArea('Mandoli',              _v, 15.8918, 74.5258),
  BelgaumArea('Basavan Kudachi',      _v, 15.8092, 74.4858),
  BelgaumArea('Piranwadi',            _v, 15.8962, 74.4858),
  BelgaumArea('Anagol',               _v, 15.8712, 74.5462),
  BelgaumArea('Yellur',               _v, 15.9012, 74.5358),
  BelgaumArea('Sulebhavi',            _v, 15.8608, 74.5462),
  BelgaumArea('Kinaye',               _v, 15.8508, 74.5512),
];

// ─────────────────────────────────────────────────────────────────────────────
// Haversine centroid fallback — used when reverse-geocode is unavailable
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the area name whose centre is closest to [lat]/[lng].
String nearestArea(double lat, double lng) {
  BelgaumArea? best;
  double bestDist = double.infinity;
  for (final a in belgaumAreas) {
    final d = _haversineKm(lat, lng, a.lat, a.lng);
    if (d < bestDist) { bestDist = d; best = a; }
  }
  return best?.name ?? belgaumAreas.first.name;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─────────────────────────────────────────────────────────────────────────────
// Nominatim locality → known area matcher
// ─────────────────────────────────────────────────────────────────────────────

/// Given a list of locality/suburb strings from a reverse-geocode response,
/// returns the first matching known Belagavi area name.
///
/// Match priority:
///   1. Exact case-insensitive
///   2. Nominatim string contains a known area name
///   3. Known area name contains the Nominatim string (min 5 chars)
String? matchNominatimToArea(List<String> candidates) {
  for (final candidate in candidates) {
    final c = candidate.toLowerCase().trim();
    if (c.isEmpty) continue;

    for (final area in belgaumAreas) {
      if (area.name.toLowerCase() == c) return area.name;
    }
    for (final area in belgaumAreas) {
      if (c.contains(area.name.toLowerCase())) return area.name;
    }
    for (final area in belgaumAreas) {
      if (area.name.toLowerCase().contains(c) && c.length >= 5) {
        return area.name;
      }
    }
  }
  return null;
}

/// Sorted list of group names in display order.
const belgaumAreaGroups = <String>[_c, _g, _i, _v];
