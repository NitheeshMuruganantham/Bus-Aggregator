class BusModel {
  final int id;
  final String operator;
  final String departure;
  final String arrival;
  final String duration;
  final double rating;
  final String layout;
  final int price;
  final List<String> availableSeats;
  final Map<String, int> platforms;
  final String busType;
  final List<String> amenities;

  BusModel({
    required this.id,
    required this.operator,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.rating,
    required this.layout,
    required this.price,
    required this.availableSeats,
    required this.platforms,
    required this.busType,
    required this.amenities,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'] as int,
      operator: json['operator'] as String,
      departure: json['departure'] as String,
      arrival: json['arrival'] as String,
      duration: json['duration'] as String,
      rating: (json['rating'] as num).toDouble(),
      layout: json['layout'] as String,
      price: json['price'] as int,
      availableSeats: List<String>.from(json['availableSeats']),
      platforms: Map<String, int>.from(json['platforms']),
      busType: json['busType'] as String,
      amenities: List<String>.from(json['amenities']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operator': operator,
      'departure': departure,
      'arrival': arrival,
      'duration': duration,
      'rating': rating,
      'layout': layout,
      'price': price,
      'availableSeats': availableSeats,
      'platforms': platforms,
      'busType': busType,
      'amenities': amenities,
    };
  }
}
