/// Chef profile model
class ChefProfile {
  final String userId;
  final String name;
  final String bio;
  final String phone;
  final List<String> specialties;
  final String location;
  final String address;
  final String profileImage;
  final bool isActive;
  final bool isVerified;
  final double rating;
  final int totalOrders;
  final double totalEarnings;
  final Map<String, WorkingHours> workingHours;
  final DeliverySettings deliverySettings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChefProfile({
    required this.userId,
    required this.name,
    this.bio = '',
    this.phone = '',
    this.specialties = const [],
    this.location = '',
    this.address = '',
    this.profileImage = '',
    this.isActive = true,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.totalEarnings = 0.0,
    this.workingHours = const {},
    this.deliverySettings = const DeliverySettings(),
    this.createdAt,
    this.updatedAt,
  });

  factory ChefProfile.fromJson(Map<String, dynamic> json) {
    // Parse working hours
    Map<String, WorkingHours> hours = {};
    if (json['workingHours'] != null) {
      (json['workingHours'] as Map<String, dynamic>).forEach((key, value) {
        hours[key] = WorkingHours.fromJson(value);
      });
    }

    return ChefProfile(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      location: json['location'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profileImage'] ?? '',
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      workingHours: hours,
      deliverySettings: json['deliverySettings'] != null
          ? DeliverySettings.fromJson(json['deliverySettings'])
          : const DeliverySettings(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> hours = {};
    workingHours.forEach((key, value) {
      hours[key] = value.toJson();
    });

    return {
      'userId': userId,
      'name': name,
      'bio': bio,
      'phone': phone,
      'specialties': specialties,
      'location': location,
      'address': address,
      'profileImage': profileImage,
      'isActive': isActive,
      'isVerified': isVerified,
      'rating': rating,
      'totalOrders': totalOrders,
      'totalEarnings': totalEarnings,
      'workingHours': hours,
      'deliverySettings': deliverySettings.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ChefProfile copyWith({
    String? userId,
    String? name,
    String? bio,
    String? phone,
    List<String>? specialties,
    String? location,
    String? address,
    String? profileImage,
    bool? isActive,
    bool? isVerified,
    double? rating,
    int? totalOrders,
    double? totalEarnings,
    Map<String, WorkingHours>? workingHours,
    DeliverySettings? deliverySettings,
  }) {
    return ChefProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      specialties: specialties ?? this.specialties,
      location: location ?? this.location,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      workingHours: workingHours ?? this.workingHours,
      deliverySettings: deliverySettings ?? this.deliverySettings,
    );
  }
}

class WorkingHours {
  final String open;
  final String close;
  final bool isOpen;

  const WorkingHours({
    this.open = '09:00',
    this.close = '21:00',
    this.isOpen = true,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      open: json['open'] ?? '09:00',
      close: json['close'] ?? '21:00',
      isOpen: json['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'isOpen': isOpen,
    };
  }
}

class DeliverySettings {
  final bool offersDelivery;
  final double deliveryFee;
  final int deliveryRadius; // km

  const DeliverySettings({
    this.offersDelivery = true,
    this.deliveryFee = 3.0,
    this.deliveryRadius = 10,
  });

  factory DeliverySettings.fromJson(Map<String, dynamic> json) {
    return DeliverySettings(
      offersDelivery: json['offersDelivery'] ?? true,
      deliveryFee: (json['deliveryFee'] ?? 3.0).toDouble(),
      deliveryRadius: json['deliveryRadius'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offersDelivery': offersDelivery,
      'deliveryFee': deliveryFee,
      'deliveryRadius': deliveryRadius,
    };
  }
}

/// Chef statistics model
class ChefStats {
  final int todayOrders;
  final double todayEarnings;
  final int pendingOrders;
  final int preparingOrders;
  final int totalOrders;
  final double totalEarnings;
  final int dishesCount;
  final double averageRating;
  final int reviewsCount;
  final bool isActive;

  ChefStats({
    this.todayOrders = 0,
    this.todayEarnings = 0.0,
    this.pendingOrders = 0,
    this.preparingOrders = 0,
    this.totalOrders = 0,
    this.totalEarnings = 0.0,
    this.dishesCount = 0,
    this.averageRating = 0.0,
    this.reviewsCount = 0,
    this.isActive = false,
  });

  factory ChefStats.fromJson(Map<String, dynamic> json) {
    return ChefStats(
      todayOrders: json['todayOrders'] ?? 0,
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      pendingOrders: json['pendingOrders'] ?? 0,
      preparingOrders: json['preparingOrders'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      dishesCount: json['dishesCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}
