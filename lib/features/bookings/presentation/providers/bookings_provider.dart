import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/booking_repository.dart';
import '../../domain/booking_model.dart';

// ── Repository provider ──────────────────────────────────────────────────────
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(),
);

// ── Bookings list provider ───────────────────────────────────────────────────
class BookingsNotifier
    extends StateNotifier<AsyncValue<List<BookingModel>>> {
  BookingsNotifier(this._repo, this._filter)
      : super(const AsyncValue.loading()) {
    load();
  }

  final BookingRepository _repo;
  final BookingFilter _filter;
  String _search = '';

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repo.getOwnerBookings(
        filter: _filter,
        search: _search.isNotEmpty ? _search : null,
      );
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    _search = query;
    await load();
  }

  Future<void> updateStatus(
    int bookingId,
    String status, {
    String? cancellationReason,
  }) async {
    await _repo.updateBookingStatus(
      bookingId,
      status: status,
      cancellationReason: cancellationReason,
    );
    await load();
  }
}

// Separate providers for each filter tab
final upcomingBookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingsNotifier(
    ref.watch(bookingRepositoryProvider),
    BookingFilter.upcoming,
  ),
);

final ongoingBookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingsNotifier(
    ref.watch(bookingRepositoryProvider),
    BookingFilter.ongoing,
  ),
);

final completedBookingsProvider =
    StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>(
  (ref) => BookingsNotifier(
    ref.watch(bookingRepositoryProvider),
    BookingFilter.completed,
  ),
);
