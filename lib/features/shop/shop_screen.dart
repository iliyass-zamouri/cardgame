import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/dependency_injection.dart';
import '../../core/constants/camo_colors.dart';
import '../../core/constants/camo_spacing.dart';
import '../../core/constants/camo_typography.dart';
import '../../core/widgets/camo_buttons.dart';
import '../../core/widgets/camo_scaffold.dart';
import '../../core/widgets/game_background.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  List<dynamic> _items = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/shop/catalog');
      setState(() => _items = res['items'] as List? ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CamoScaffold(
      title: 'Shop',
      onBack: () => context.pop(),
      body: GameBackground(
        child: Padding(
        padding: const EdgeInsets.all(CamoSpacing.xl),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: CamoTypography.bodyLg(CamoColors.danger)),
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: CamoSpacing.sm),
                itemBuilder: (context, i) {
                  final item = Map<String, dynamic>.from(_items[i] as Map);
                  return CamoPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['id'].toString(),
                            style:
                                CamoTypography.headlineMd(CamoColors.onSurface),
                          ),
                        ),
                        CamoMenuButton(
                          label: 'Buy',
                          primary: true,
                          expandWidth: false,
                          onPressed: () async {
                            final api = ref.read(apiClientProvider);
                            await api.post(
                              '/shop/purchase',
                              body: {'itemId': item['id']},
                              idempotencyKey: const Uuid().v4(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            CamoMenuButton(
              label: 'Rewarded Ad (+50)',
              onPressed: () async {
                final api = ref.read(apiClientProvider);
                await api.post('/shop/rewarded-ad');
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}
