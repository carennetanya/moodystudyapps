import 'package:flutter/material.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/screens/shop_screen.dart';

/// Menampilkan semua item yang sudah dimiliki user.
/// Bisa dibuka langsung (load dari API) atau dari ShopScreen (pass ownedIds).
class CollectionScreen extends StatefulWidget {
  final Set<String>? ownedIds; // opsional — kalau null, load dari API

  const CollectionScreen({super.key, this.ownedIds});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Set<String> _ownedIds = {};
  bool _loading = true;

  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);
  static const _kBg     = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    if (widget.ownedIds != null) {
      _ownedIds = widget.ownedIds!;
      _loading = false;
    } else {
      _loadFromApi();
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final res = await ApiClient.dio.get('/api/shop/collection');
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _ownedIds = Set<String>.from(body['ownedItemIds'] as List? ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<ShopItem> get _ownedItems =>
      kShopItems.where((item) => _ownedIds.contains(item.id)).toList();

  String _categoryOf(ShopItem item) {
    switch (item.category) {
      case ShopCategory.outfit:
        return item.outfitPart?.label ?? 'Outfit';
      case ShopCategory.accessory:
        return 'Accessory';
      case ShopCategory.theme:
        return 'Theme';
    }
  }

  List<String> _categories(List<ShopItem> items) {
    final cats = <String>{};
    for (final item in items) cats.add(_categoryOf(item));
    return cats.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildTopBar(context),
                  Expanded(child: _ownedItems.isEmpty ? _buildEmpty(context) : _buildList(_ownedItems)),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBlack, width: 2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kYellow, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlack, width: 2),
                boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: const Icon(Icons.arrow_back, color: _kBlack, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Koleksi', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 22, color: _kBlack)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBlack, width: 2),
            ),
            child: Text(
              '${_ownedItems.length} item',
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: _kBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📦', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Koleksi kosong', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 20, color: _kBlack)),
          const SizedBox(height: 8),
          const Text('Beli item di Shop untuk mulai mengoleksi!',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _kYellow, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBlack, width: 2),
                boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(3, 3), blurRadius: 0)],
              ),
              child: const Text('Ke Shop', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 15, color: _kBlack)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ShopItem> owned) {
    final cats = _categories(owned);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: cats.length,
      itemBuilder: (_, ci) {
        final cat = cats[ci];
        final items = owned.where((e) => _categoryOf(e) == cat).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ci > 0) const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _kBlack, borderRadius: BorderRadius.circular(10)),
              child: Text(cat, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _CollectionItemCard(item: items[i]),
            ),
          ],
        );
      },
    );
  }
}
class _CollectionItemCard extends StatelessWidget {
  final ShopItem item;

  static const _kBlack = Color(0xFF111111);
  static const _kGreen = Color(0xFF1EE86F);

  const _CollectionItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = item.bgColor.computeLuminance() < 0.2;

    return Container(
      decoration: BoxDecoration(
        color: item.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen, width: 2.5),
        boxShadow: const [BoxShadow(color: _kGreen, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 52, height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 28, color: isDark ? Colors.white : _kBlack),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(item.name, maxLines: 2, textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white : _kBlack)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBlack, width: 1.5),
                ),
                child: const Text('✓ Owned', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: _kBlack)),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Positioned(
            top: 6, right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 10, color: _kBlack),
            ),
          ),
        ],
      ),
    );
  }
}