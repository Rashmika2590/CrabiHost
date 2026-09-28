import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/property_repository.dart';
import '../../domain/hotel_model.dart';

// ── Repository provider ──────────────────────────────────────────────────────
final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => PropertyRepository(),
);

// ── Properties notifier ──────────────────────────────────────────────────────
class PropertiesNotifier
    extends StateNotifier<AsyncValue<List<HotelModel>>> {
  PropertiesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final PropertyRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final hotels = await _repo.getMyHotels();
      state = AsyncValue.data(hotels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleEnabled(int hotelId, {required bool enable}) async {
    await _repo.toggleHotelEnabled(hotelId, enable: enable);
    // Optimistic update
    if (state.value != null) {
      state = AsyncValue.data(
        state.value!.map((h) {
          if (h.id == hotelId) return h.copyWith(enableByOwner: enable);
          return h;
        }).toList(),
      );
    }
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<HotelModel>>>(
  (ref) => PropertiesNotifier(ref.watch(propertyRepositoryProvider)),
);

// Selected property ID for filtering
final selectedPropertyIdProvider = StateProvider<int?>((ref) => null);
