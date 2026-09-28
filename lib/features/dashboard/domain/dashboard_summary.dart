import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookings/domain/booking_model.dart';
import '../../bookings/presentation/providers/bookings_provider.dart';
import '../../properties/domain/hotel_model.dart';
import '../../properties/presentation/providers/properties_provider.dart';

class DashboardSummary {
  final List<HotelModel> properties;
  final List<BookingModel> upcomingBookings;
  final List<BookingModel> ongoingBookings;
  final List<BookingModel> completedBookings;

  const DashboardSummary({
    this.properties = const [],
    this.upcomingBookings = const [],
    this.ongoingBookings = const [],
    this.completedBookings = const [],
  });

  int get totalActiveBookings => ongoingBookings.length;

  List<BookingModel> get todayCheckIns {
    final today = DateTime.now();
    return upcomingBookings.where((b) {
      final ci = b.checkInDate;
      if (ci == null) return false;
      return ci.year == today.year &&
          ci.month == today.month &&
          ci.day == today.day;
    }).toList();
  }

  List<BookingModel> get todayCheckOuts {
    final today = DateTime.now();
    return ongoingBookings.where((b) {
      final co = b.checkOutDate;
      if (co == null) return false;
      return co.year == today.year &&
          co.month == today.month &&
          co.day == today.day;
    }).toList();
  }

  double get totalRevenue {
    return completedBookings.fold(0, (sum, b) => sum + (b.price ?? 0));
  }

  String get revenueDisplay {
    final currency = completedBookings.isNotEmpty
        ? completedBookings.first.displayCurrency
        : 'LKR';
    return '$currency ${totalRevenue.toStringAsFixed(0)}';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final propRepo = ref.read(propertyRepositoryProvider);
  final bookingRepo = ref.read(bookingRepositoryProvider);

  final properties = await propRepo.getMyHotels();
  final upcoming = await bookingRepo.getOwnerBookings(filter: BookingFilter.upcoming);
  final ongoing = await bookingRepo.getOwnerBookings(filter: BookingFilter.ongoing);
  final completed = await bookingRepo.getOwnerBookings(filter: BookingFilter.completed, limit: 20);

  return DashboardSummary(
    properties: properties,
    upcomingBookings: upcoming,
    ongoingBookings: ongoing,
    completedBookings: completed,
  );
});
