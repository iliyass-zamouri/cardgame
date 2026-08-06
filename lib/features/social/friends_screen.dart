import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../../core/widgets/game_background.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  List<dynamic> _friends = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/friends');
    setState(() => _friends = res['friends'] as List? ?? []);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CamoScaffold(
      title: 'Friends',
      onBack: () => context.pop(),
      body: GameBackground(
        child: Padding(
        padding: const EdgeInsets.all(CamoSpacing.xl),
        child: Column(
          children: [
            CamoPanel(
              child: TextField(
                controller: _search,
                style: CamoTypography.bodyLg(CamoColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search player id',
                  hintStyle:
                      CamoTypography.bodyLg(CamoColors.onSurfaceVariant),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.person_add, color: CamoColors.primary),
                    onPressed: () async {
                      final api = ref.read(apiClientProvider);
                      await api.post('/friends/request', body: {
                        'playerId': _search.text.trim(),
                      });
                      await _load();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: CamoSpacing.lg),
            Expanded(
              child: ListView.separated(
                itemCount: _friends.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: CamoSpacing.sm),
                itemBuilder: (context, i) {
                  final f = Map<String, dynamic>.from(_friends[i] as Map);
                  return CamoPanel(
                    child: Text(
                      '${f['display_name'] ?? f['public_id']} · ${f['status']}',
                      style: CamoTypography.bodyLg(CamoColors.onSurface),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
