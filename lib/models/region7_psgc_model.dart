class BarangayModel {
  final String name;
  final String code;

  BarangayModel({required this.name, required this.code});

  factory BarangayModel.fromList(List<dynamic> data) {
    return BarangayModel(name: data[0], code: data[1]);
  }
}

class CityModel {
  final String name;
  final String code;
  final List<BarangayModel> barangays;

  CityModel({required this.name, required this.code, required this.barangays});

  factory CityModel.fromList(List<dynamic> data) {
    var barangaysData = data[2] as List<dynamic>;
    List<BarangayModel> barangays = barangaysData
        .map((b) => BarangayModel.fromList(b))
        .toList();
    return CityModel(name: data[0], code: data[1], barangays: barangays);
  }
}

class ProvinceModel {
  final String name;
  final String code;
  final List<CityModel> cities;

  ProvinceModel({required this.name, required this.code, required this.cities});

  factory ProvinceModel.fromList(List<dynamic> data) {
    var citiesData = data[2] as List<dynamic>;
    List<CityModel> cities = citiesData
        .map((c) => CityModel.fromList(c))
        .toList();
    return ProvinceModel(name: data[0], code: data[1], cities: cities);
  }
}

class RegionModel {
  final String name;
  final String code;
  final List<ProvinceModel> provinces;

  RegionModel({
    required this.name,
    required this.code,
    required this.provinces,
  });

  factory RegionModel.fromList(List<dynamic> data) {
    var provincesData = data[2] as List<dynamic>;
    List<ProvinceModel> provinces = provincesData
        .map((p) => ProvinceModel.fromList(p))
        .toList();
    return RegionModel(name: data[0], code: data[1], provinces: provinces);
  }
}
