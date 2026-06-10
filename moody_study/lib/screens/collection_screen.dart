import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/screens/shop_screen.dart';
import 'package:moody_study/utils/app_localizations.dart';

/// Edit Avatar screen — preview avatar di atas, tab kategori, grid item owned.
/// Tap item → equip (simpan ke SharedPreferences).
class CollectionScreen extends StatefulWidget {
  final Set<String>? ownedIds; // opsional — kalau null, load dari API

  const CollectionScreen({super.key, this.ownedIds});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);
  static const _kBg     = Color(0xFFF5F5F0);

  static const _skinAvatarMap = {
    's_fair':  'fair.png',
    's_warm':  'warm-beige.png',
    's_honey': 'honey.png',
    's_brown': 'brown-sugar.png',
    's_deep':  'deep.png',
  };

  Set<String> _ownedIds = {};
  bool _loading = true;

  // Equip state — active per OutfitPart
  String _activeSkinId = 's_fair';

  // Category tab
  late TabController _tabController;

  // Tab order - OutfitPart (4) + Accessory + Theme = 6 tabs
  static const _tabParts = [
    OutfitPart.skin,
    OutfitPart.hair,
    OutfitPart.top,
    OutfitPart.jacket,
  ];

  static const _tabIcons = [
    Icons.face_rounded,
    Icons.air_rounded,
    Icons.checkroom_rounded,
    Icons.dry_cleaning_rounded,
    Icons.auto_awesome_rounded,
    Icons.palette_rounded,
  ];

  static const _totalTabs = 6;

  String get _currentAvatarFile =>
      _skinAvatarMap[_activeSkinId] ?? 'fair.png';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _totalTabs, vsync: this);
    _loadActiveSkin().then((_) {
      if (widget.ownedIds != null) {
        setState(() {
          _ownedIds = widget.ownedIds!;
          _loading = false;
        });
      } else {
        _loadFromApi();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSkin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_skin_id');
    if (saved != null && _skinAvatarMap.containsKey(saved)) {
      if (mounted) setState(() => _activeSkinId = saved);
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final res = await ApiClient.dio.get('/api/shop/collection');
      final body = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _ownedIds = Set<String>.from(body['ownedItemIds'] as List? ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ShopItem> _ownedItemsFor(OutfitPart part) {
    return kShopItems
        .where((item) =>
            item.outfitPart == part &&
            (item.price == 0 || _ownedIds.contains(item.id)))
        .toList();
  }

  bool _isEquipped(ShopItem item) {
    if (item.outfitPart == OutfitPart.skin) {
      return item.id == _activeSkinId;
    }
    return false; // For other parts — extend when more equip state is added
  }

  Future<void> _equipItem(ShopItem item) async {
    if (item.outfitPart == OutfitPart.skin) {
      setState(() => _activeSkinId = item.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_skin_id', item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kYellow, strokeWidth: 3),
            )
          : Column(
              children: [
                // ── Avatar preview header ────────────────────────────────
                _buildHeader(context),

                // ── Category tabs ────────────────────────────────────────
                _buildTabBar(),

                // ── Grid items ───────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ..._tabParts.map((part) => _buildItemGrid(part: part)),
                      _buildCategoryGrid(ShopCategory.accessory),
                      _buildCategoryGrid(ShopCategory.theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Header: avatar preview ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kYellow,
        border: Border(bottom: BorderSide(color: _kBlack, width: 2)),
      ),
      child: Stack(
        children: [
          // Decorative dots
          Positioned(top: 50, left: 30,
              child: _Dot(size: 12, color: _kBlack.withOpacity(0.07))),
          Positioned(top: 80, right: 50,
              child: _Dot(size: 18, color: _kBlack.withOpacity(0.05))),
          Positioned(top: 150, left: 80,
              child: _Dot(size: 8, color: _kBlack.withOpacity(0.06))),

          // Top bar: X + title + DONE
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // X button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _kBlack, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: _kBlack, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context).collectionTitle,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 18,
                        color: _kBlack,
                      ),
                    ),
                    const Spacer(),
                    // DONE button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kBlack,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(context).collectionDone,
                          style: const TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 13,
                            color: _kYellow,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar image — centered bottom
          Positioned(
            bottom: 0,
            left: 0, right: 0,
            child: Center(
              child: SizedBox(
                height: 190,
                child: Image.asset(
                  'assets/images/avatars/$_currentAvatarFile',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab bar ─────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    final l = AppLocalizations.of(context);
    final tabLabels = [l.shopSkin, l.shopHair, l.shopTop, l.shopJacket, l.shopAccessory, l.shopTheme];
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _kBlack,
        indicatorWeight: 2.5,
        labelColor: _kBlack,
        unselectedLabelColor: const Color(0xFFAAAAAA),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: List.generate(_totalTabs, (i) {
          return Tab(
            height: 56,
            child: SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_tabIcons[i], size: 20),
                  const SizedBox(height: 3),
                  Text(
                    tabLabels[i],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Item grid ───────────────────────────────────────────────────────────────

  Widget _buildItemGrid({OutfitPart? part}) {
    final items = kShopItems
        .where((item) =>
            item.outfitPart == part &&
            (item.price == 0 || _ownedIds.contains(item.id)))
        .toList();

    if (items.isEmpty) {
      return _buildEmptyTab();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final equipped = _isEquipped(item);
        return _ItemCard(
          item: item,
          equipped: equipped,
          onTap: equipped ? null : () => _equipItem(item),
        );
      },
    );
  }

  Widget _buildCategoryGrid(ShopCategory category) {
    final items = kShopItems
        .where((item) =>
            item.category == category &&
            (item.price == 0 || _ownedIds.contains(item.id)))
        .toList();

    if (items.isEmpty) {
      return _buildEmptyTab();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final equipped = _isEquipped(item);
        return _ItemCard(
          item: item,
          equipped: equipped,
          onTap: equipped ? null : () => _equipItem(item),
        );
      },
    );
  }

  Widget _buildEmptyTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛍️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).shopNoItems,
            style: const TextStyle(
              fontFamily: 'BlackHanSans',
              fontSize: 16,
              color: _kBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).shopBuyToUnlock,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _kYellow,
                border: Border.all(color: _kBlack, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: _kBlack, offset: Offset(3, 3), blurRadius: 0)
                ],
              ),
              child: Text(
                AppLocalizations.of(context).shopGoToShop,
                style: const TextStyle(
                    fontFamily: 'BlackHanSans',
                    fontSize: 13,
                    color: _kBlack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  final bool equipped;
  final VoidCallback? onTap;

  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);

  const _ItemCard({
    required this.item,
    required this.equipped,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = item.bgColor.computeLuminance() < 0.2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: equipped ? _kBlack : const Color(0xFFCCCCCC),
            width: equipped ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: equipped ? _kBlack : const Color(0xFFCCCCCC),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Avatar image for skin, icon for others
                Container(
                  width: 52, height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.outfitPart == OutfitPart.skin &&
                          item.avatarFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/avatars/${item.avatarFile}',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(item.icon,
                          size: 28,
                          color: isDark ? Colors.white : _kBlack),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : _kBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Equipped / Pakai badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: equipped ? _kBlack : _kYellow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kBlack, width: 1.5),
                  ),
                  child: Text(
                    equipped ? '✓ Equipped' : 'Pakai',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: equipped ? _kYellow : _kBlack,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            // Equipped checkmark badge
            if (equipped)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 10, color: _kBlack),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final double size;
  final Color color;
  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}