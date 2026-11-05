import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_filter.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_sheet_frame.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/common.dart';

/// Filter & sort sheet. Edits a draft copy of the filter and only applies
/// it on "Show N reports", so the count previews the result live.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FilterSheet(),
  );

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late IncidentFilter _draft = context.read<IncidentProvider>().filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<IncidentProvider>();
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    final count = _draft.apply(provider.all, uid: provider.user?.uid).length;

    Widget group(String title, List<Widget> pills) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < pills.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: pills[i]),
              ],
            ],
          ),
        ],
      ),
    );

    Widget section(String title, String hint, Widget body) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(hint, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );

    return BottomSheetFrame(
      title: 'Filter reports',
      trailing: TextButton(
        onPressed: () => setState(() => _draft = IncidentFilter(query: _draft.query)),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        child: const Text('Clear all', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      child: Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(
                'Status',
                'Tap again to show every status',
                TileGrid(
                  columns: 4,
                  children: [
                    for (final st in IncidentStatus.values)
                      IconTile(
                        icon: st.icon,
                        label: st.label,
                        wellColor: st.background,
                        iconColor: st.foreground,
                        selected: _draft.status == st,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(status: () => _draft.status == st ? null : st),
                        ),
                      ),
                  ],
                ),
              ),
              section(
                'Category',
                'Pick one or more',
                TileGrid(
                  children: [
                    for (final c in IncidentCategory.values)
                      CategoryTile(
                        category: c,
                        selected: _draft.categories.contains(c),
                        onTap: () => setState(() {
                          final next = {..._draft.categories};
                          next.contains(c) ? next.remove(c) : next.add(c);
                          _draft = _draft.copyWith(categories: next);
                        }),
                      ),
                  ],
                ),
              ),
              if (!isStaff)
                group('Show', [
                  ChoicePill(
                    label: 'All reports',
                    selected: !_draft.onlyMine,
                    onTap: () => setState(() => _draft = _draft.copyWith(onlyMine: false)),
                  ),
                  ChoicePill(
                    label: 'Only mine',
                    selected: _draft.onlyMine,
                    onTap: () => setState(() => _draft = _draft.copyWith(onlyMine: true)),
                  ),
                ]),
              group('Sort by', [
                ChoicePill(
                  label: 'Newest',
                  selected: _draft.newestFirst,
                  onTap: () => setState(() => _draft = _draft.copyWith(newestFirst: true)),
                ),
                ChoicePill(
                  label: 'Oldest',
                  selected: !_draft.newestFirst,
                  onTap: () => setState(() => _draft = _draft.copyWith(newestFirst: false)),
                ),
              ]),
              AppButton(
                label: count == 1 ? 'Show 1 report' : 'Show $count reports',
                onPressed: () {
                  provider.applyFilter(_draft);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
