import '../core/constants.dart';
import '../models/incident.dart';

/// Immutable description of what the Reports list should show.
/// Kept separate from the provider so it can be unit-tested on its own.
class IncidentFilter {
  const IncidentFilter({
    this.status,
    this.categories = const {},
    this.onlyMine = false,
    this.newestFirst = true,
    this.query = '',
  });

  final IncidentStatus? status; // null = any
  final Set<IncidentCategory> categories; // empty = any
  final bool onlyMine;
  final bool newestFirst;
  final String query;

  bool get isDefault => status == null && categories.isEmpty && !onlyMine && newestFirst;

  /// Number of sheet filters applied (shown as a badge on the filter button).
  int get activeCount =>
      (status != null ? 1 : 0) + categories.length + (onlyMine ? 1 : 0) + (newestFirst ? 0 : 1);

  IncidentFilter copyWith({
    IncidentStatus? Function()? status,
    Set<IncidentCategory>? categories,
    bool? onlyMine,
    bool? newestFirst,
    String? query,
  }) => IncidentFilter(
    status: status != null ? status() : this.status,
    categories: categories ?? this.categories,
    onlyMine: onlyMine ?? this.onlyMine,
    newestFirst: newestFirst ?? this.newestFirst,
    query: query ?? this.query,
  );

  List<Incident> apply(List<Incident> all, {String? uid}) {
    final q = query.trim();
    final out = all.where((i) {
      if (status != null && i.status != status) return false;
      if (categories.isNotEmpty && !categories.contains(i.category)) return false;
      if (onlyMine && !i.isOwnedBy(uid)) return false;
      return i.matchesQuery(q);
    }).toList();
    out.sort((a, b) => newestFirst ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
    return out;
  }
}
