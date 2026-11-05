import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';
import 'filter_sheet.dart';
import 'report_details_screen.dart';

/// Browse, search and filter. Shared by students ("Reports") and staff
/// ("All reports"); filter state lives in IncidentProvider so it survives
/// tab switches and can be set from other screens.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  late final IncidentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<IncidentProvider>();
    _search.text = _provider.filter.query;
    _provider.addListener(_syncSearchText);
  }

  /// Other screens can reset the filter (e.g. Home → "View all"); keep the
  /// search box text in step with the provider's query.
  void _syncSearchText() {
    final q = _provider.filter.query;
    if (_debounce?.isActive != true && _search.text != q) _search.text = q;
  }

  @override
  void dispose() {
    _provider.removeListener(_syncSearchText);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) context.read<IncidentProvider>().setQuery(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);
    final uid = context.select<AuthProvider, String?>((a) => a.uid);
    final provider = context.watch<IncidentProvider>();
    final filter = provider.filter;
    final items = provider.visible;

    final statusTabs = <IncidentStatus?>[null, ...IncidentStatus.values];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  isStaff ? 'All reports' : 'Reports',
                  style: const TextStyle(fontSize: 26, letterSpacing: -0.4, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search reports',
                          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
                          prefixIcon: const Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                            color: AppColors.muted,
                          ),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(PhosphorIconsRegular.x, color: AppColors.muted),
                                  onPressed: () {
                                    _search.clear();
                                    provider.setQuery('');
                                    setState(() {});
                                  },
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppIconButton(
                      icon: PhosphorIconsRegular.slidersHorizontal,
                      tooltip: 'Filter and sort',
                      variant: IconButtonVariant.outline,
                      badge: filter.activeCount - (filter.status != null ? 1 : 0),
                      onPressed: () => FilterSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: statusTabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final s = statusTabs[i];
                      return ChoicePill(
                        label: s?.label ?? 'All',
                        selected: filter.status == s,
                        onTap: () => provider.setStatus(s),
                      );
                    },
                  ),
                ),
                if (filter.onlyMine || filter.categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ActiveFilters(onClear: provider.resetFilter),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (provider.loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (provider.loadError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: PhosphorIconsRegular.cloudSlash,
                title: 'Couldn’t load reports',
                message: provider.loadError,
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: PhosphorIconsRegular.magnifyingGlass,
                title: 'No reports found',
                message: provider.all.isEmpty
                    ? 'Nothing has been reported yet.'
                    : 'Try a different search or clear the filters.',
                actionLabel: filter.isDefault && filter.query.isEmpty ? null : 'Clear filters',
                onAction: () {
                  _search.clear();
                  provider.resetFilter();
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => ReportCard(
                  incident: items[i],
                  showReporter: isStaff,
                  isMine: !isStaff && items[i].isOwnedBy(uid),
                  onTap: () => ReportDetailsScreen.open(context, items[i].id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final f = context.select<IncidentProvider, String>((p) {
      final parts = [
        if (p.filter.onlyMine) 'Only mine',
        ...p.filter.categories.map((c) => c.label),
        if (!p.filter.newestFirst) 'Oldest first',
      ];
      return parts.join(' · ');
    });
    return Row(
      children: [
        const Icon(PhosphorIconsRegular.funnel, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            f,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
