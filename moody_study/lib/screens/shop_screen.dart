import 'package:flutter/material.dart';
import 'package:moody_study/services/api_client.dart';
import 'package:moody_study/screens/collection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ShopCategory { outfit, accessory, theme }

enum OutfitPart { skin, hair, top, jacket }

extension OutfitPartLabel on OutfitPart {
  String get label {
    switch (this) {
      case OutfitPart.skin:   return 'Skin';
      case OutfitPart.hair:   return 'Hair';
      case OutfitPart.top:    return 'Top';
      case OutfitPart.jacket: return 'Jacket';
    }
  }
  IconData get icon {
    switch (this) {
      case OutfitPart.skin:   return Icons.face_rounded;
      case OutfitPart.hair:   return Icons.air_rounded;
      case OutfitPart.top:    return Icons.checkroom_rounded;
      case OutfitPart.jacket: return Icons.dry_cleaning_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class ShopItem {
  final String id;
  final String name;
  final IconData icon;
  final int price;
  final ShopCategory category;
  final OutfitPart? outfitPart;
  final Color bgColor;
  final String? avatarFile;

  const ShopItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.price,
    required this.category,
    this.outfitPart,
    required this.bgColor,
    this.avatarFile,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Catalogue
// ─────────────────────────────────────────────────────────────────────────────

const kShopItems = [
  // ── SKIN (semua free) ──
  ShopItem(id: 's_fair',   name: 'Fair',        icon: Icons.face_rounded,           price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.skin, bgColor: Color(0xFFFFF4D6), avatarFile: 'fair.avif'),
  ShopItem(id: 's_warm',   name: 'Warm Beige',  icon: Icons.face_3_rounded,         price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.skin, bgColor: Color(0xFFFFE4C4), avatarFile: 'warm-beige.avif'),
  ShopItem(id: 's_honey',  name: 'Honey',       icon: Icons.face_4_rounded,         price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.skin, bgColor: Color(0xFFFFD59E), avatarFile: 'honey.avif'),
  ShopItem(id: 's_brown',  name: 'Brown Sugar', icon: Icons.face_5_rounded,         price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.skin, bgColor: Color(0xFFE8C49A), avatarFile: 'brown-sugar.avif'),
  ShopItem(id: 's_deep',   name: 'Deep',        icon: Icons.face_6_rounded,         price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.skin, bgColor: Color(0xFFD4956A), avatarFile: 'deep.avif'),
  // ── HAIR ──
  ShopItem(id: 'h_black',   name: 'Jet Black',   icon: Icons.person_rounded,        price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFE8E8E8)),
  ShopItem(id: 'h_brown',   name: 'Choco Brown', icon: Icons.person_2_rounded,      price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFF5E6D3)),
  ShopItem(id: 'h_blonde',  name: 'Blonde',      icon: Icons.person_3_rounded,      price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFFFF4D6)),
  ShopItem(id: 'h_pink',    name: 'Sakura Pink', icon: Icons.person_4_rounded,      price: 800,  category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFFFF0F8)),
  ShopItem(id: 'h_blue',    name: 'Ocean Blue',  icon: Icons.person_pin_rounded,    price: 800,  category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFE8F4FF)),
  ShopItem(id: 'h_green',   name: 'Matcha',      icon: Icons.person_outline_rounded,price: 1000, category: ShopCategory.outfit, outfitPart: OutfitPart.hair, bgColor: Color(0xFFDFF5E3)),
  // ── TOP ──
  ShopItem(id: 't_uniform', name: 'School Shirt', icon: Icons.checkroom_rounded,     price: 0,    category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFE8F4FF)),
  ShopItem(id: 't_hoodie',  name: 'Cozy Hoodie',  icon: Icons.dry_cleaning_rounded,  price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFEDE8FF)),
  ShopItem(id: 't_crop',    name: 'Crop Tee',     icon: Icons.style_rounded,         price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFFFF0F8)),
  ShopItem(id: 't_polo',    name: 'Polo Shirt',   icon: Icons.badge_rounded,         price: 30,   category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFDFF5E3)),
  ShopItem(id: 't_lab',     name: 'Lab Coat',     icon: Icons.science_rounded,       price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFF5F5F5)),
  ShopItem(id: 't_astro',   name: 'Astro Suit',   icon: Icons.rocket_launch_rounded, price: 2000, category: ShopCategory.outfit, outfitPart: OutfitPart.top, bgColor: Color(0xFFE8F4FF)),
  // ── JACKET ──
  ShopItem(id: 'j_denim',    name: 'Denim',       icon: Icons.layers_rounded,        price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.jacket, bgColor: Color(0xFFE8F4FF)),
  ShopItem(id: 'j_bomber',   name: 'Bomber',      icon: Icons.flight_rounded,        price: 800,  category: ShopCategory.outfit, outfitPart: OutfitPart.jacket, bgColor: Color(0xFFDFF5E3)),
  ShopItem(id: 'j_cardigan', name: 'Cardigan',    icon: Icons.grain_rounded,         price: 40,   category: ShopCategory.outfit, outfitPart: OutfitPart.jacket, bgColor: Color(0xFFFFF4D6)),
  ShopItem(id: 'j_varsity',  name: 'Varsity',     icon: Icons.sports_rounded,        price: 800,  category: ShopCategory.outfit, outfitPart: OutfitPart.jacket, bgColor: Color(0xFFFFEBEB)),
  ShopItem(id: 'j_trench',   name: 'Trench Coat', icon: Icons.umbrella_rounded,      price: 1500, category: ShopCategory.outfit, outfitPart: OutfitPart.jacket, bgColor: Color(0xFFF5E6D3)),
  // ── ACCESSORY ──
  ShopItem(id: 'acc_headphone', name: 'Headphones',    icon: Icons.headphones_rounded,      price: 800, category: ShopCategory.accessory, bgColor: Color(0xFFDFF5E3)),
  ShopItem(id: 'acc_glasses',   name: 'Study Glasses', icon: Icons.visibility_rounded,      price: 30,  category: ShopCategory.accessory, bgColor: Color(0xFFFFF4D6)),
  ShopItem(id: 'acc_cap',       name: 'Lucky Cap',     icon: Icons.sports_baseball_rounded, price: 30,  category: ShopCategory.accessory, bgColor: Color(0xFFE8F4FF)),
  ShopItem(id: 'acc_bag',       name: 'Bookbag Pro',   icon: Icons.backpack_rounded,        price: 800, category: ShopCategory.accessory, bgColor: Color(0xFFEDE8FF)),
  ShopItem(id: 'acc_bow',       name: 'Hair Bow',      icon: Icons.favorite_rounded,        price: 30,  category: ShopCategory.accessory, bgColor: Color(0xFFFFF0F8)),
  ShopItem(id: 'acc_earring',   name: 'Star Earrings', icon: Icons.star_rounded,            price: 500, category: ShopCategory.accessory, bgColor: Color(0xFFFFF4D6)),
  // ── THEME ──
  ShopItem(id: 'theme_night',  name: 'Night Owl',    icon: Icons.nights_stay_rounded,   price: 3000, category: ShopCategory.theme, bgColor: Color(0xFF1A1A2E)),
  ShopItem(id: 'theme_ocean',  name: 'Ocean Depth',  icon: Icons.water_rounded,         price: 3000, category: ShopCategory.theme, bgColor: Color(0xFFE8F4FF)),
  ShopItem(id: 'theme_sakura', name: 'Sakura Bloom', icon: Icons.local_florist_rounded, price: 3000, category: ShopCategory.theme, bgColor: Color(0xFFFFF0F8)),
];

// ─────────────────────────────────────────────────────────────────────────────
// ShopScreen
// ─────────────────────────────────────────────────────────────────────────────

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopCategory _selectedCategory = ShopCategory.outfit;
  OutfitPart _selectedPart = OutfitPart.skin;

  int _totalCoins = 0;
  Set<String> _ownedIds = {};
  bool _loading = true;
  String _activeSkinId = 's_fair';

  static const _skinAvatarMap = {
    's_fair':  'fair.avif',
    's_warm':  'warm-beige.avif',
    's_honey': 'honey.avif',
    's_brown': 'brown-sugar.avif',
    's_deep':  'deep.avif',
  };

  String get _currentAvatarFile =>
      _skinAvatarMap[_activeSkinId] ?? 'fair.avif';

  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);
  static const _kBg     = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    _loadCollection();
    _loadActiveSkin();
  }

  Future<void> _loadCollection() async {
    try {
      final res = await ApiClient.dio.get('/api/shop/collection');
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _totalCoins = (body['totalCoins'] as num?)?.toInt() ?? 0;
        _ownedIds = Set<String>.from(body['ownedItemIds'] as List? ?? []);
        final ownedSkin = _skinAvatarMap.keys.firstWhere(
          (id) => _ownedIds.contains(id),
          orElse: () => 's_fair',
        );
        _activeSkinId = ownedSkin;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buyItem(ShopItem item) async {
    try {
      final res = await ApiClient.dio.post('/api/shop/buy', data: {
        'itemId': item.id,
        'price': item.price,
      });
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _ownedIds.add(item.id);
        _totalCoins = (body['remainingCoins'] as num?)?.toInt() ?? _totalCoins;
        if (item.outfitPart == OutfitPart.skin) {
          _activeSkinId = item.id;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(item.price == 0 ? '${item.name} berhasil didapatkan! 🎉' : '${item.name} berhasil dibeli! 🪙'),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains('PAYMENT_REQUIRED') || e.toString().contains('402')
          ? 'Coin tidak cukup!'
          : e.toString().contains('CONFLICT') || e.toString().contains('409')
              ? 'Item sudah dimiliki'
              : 'Gagal membeli item';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _equipSkin(ShopItem item) {
    setState(() => _activeSkinId = item.id);
    _saveActiveSkin(item.id);
  }

  Future<void> _saveActiveSkin(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_skin_id', skinId);
  }

  Future<void> _loadActiveSkin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('active_skin_id');
    if (saved != null && _skinAvatarMap.containsKey(saved)) {
      setState(() => _activeSkinId = saved);
    }
  }

  List<ShopItem> get _filteredItems {
    if (_selectedCategory == ShopCategory.outfit) {
      return kShopItems.where((e) => e.category == ShopCategory.outfit && e.outfitPart == _selectedPart).toList();
    }
    return kShopItems.where((e) => e.category == _selectedCategory).toList();
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
                  _buildCurrencyRow(),
                  const SizedBox(height: 12),
                  _buildCategoryTabs(),
                  if (_selectedCategory == ShopCategory.outfit) ...[
                    const SizedBox(height: 10),
                    _buildOutfitPartTabs(),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: _selectedCategory == ShopCategory.outfit && _selectedPart == OutfitPart.skin
                        ? _buildSkinPicker()
                        : _buildGrid(),
                  ),
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
          const Text('Shop', style: TextStyle(fontFamily: 'BlackHanSans', fontSize: 22, color: _kBlack)),
          const Spacer(),
          // Tombol ke Collection
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CollectionScreen(ownedIds: _ownedIds)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kGreen, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBlack, width: 2),
                boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_rounded, size: 14, color: _kBlack),
                  SizedBox(width: 4),
                  Text('Koleksi', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: _kBlack)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBlack, width: 2),
        boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(3, 3), blurRadius: 0)],
      ),
      child: Row(
        children: [
          // Avatar preview
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: _kBlack, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/avatars/$_currentAvatarFile',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.face_rounded, size: 28, color: _kBlack),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(color: _kYellow, shape: BoxShape.circle, border: Border.all(color: _kBlack, width: 1.5)),
                    child: const Center(child: Text('🪙', style: TextStyle(fontSize: 10))),
                  ),
                  const SizedBox(width: 6),
                  Text('$_totalCoins Coins', style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 16, color: _kBlack)),
                ],
              ),
              const SizedBox(height: 2),
              Text('${_ownedIds.length} item dimiliki', style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final cats = [
      (ShopCategory.outfit,    Icons.style_rounded,        'Outfit'),
      (ShopCategory.accessory, Icons.auto_awesome_rounded, 'Accessory'),
      (ShopCategory.theme,     Icons.palette_rounded,      'Theme'),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (cat, icon, label) = cats[i];
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = cat;
              if (cat == ShopCategory.outfit) _selectedPart = OutfitPart.skin;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _kYellow : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _kBlack, width: 2),
                boxShadow: sel ? const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: _kBlack),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: _kBlack)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutfitPartTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: OutfitPart.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final part = OutfitPart.values[i];
          final sel = _selectedPart == part;
          return GestureDetector(
            onTap: () => setState(() => _selectedPart = part),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _kGreen : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? _kBlack : const Color(0xFFCCCCCC), width: sel ? 2 : 1.5),
                boxShadow: sel ? const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(part.icon, size: 14, color: sel ? _kBlack : const Color(0xFF666666)),
                  const SizedBox(width: 5),
                  Text(part.label, style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: sel ? _kBlack : const Color(0xFF666666))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkinPicker() {
    final skinItems = kShopItems.where((e) => e.outfitPart == OutfitPart.skin).toList();
    return Column(
      children: [
        // ── Avatar preview besar ──
        Expanded(
          child: Center(
            child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBlack, width: 3),
                  boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(4, 4), blurRadius: 0)],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/avatars/$_currentAvatarFile',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.face_rounded, size: 100, color: _kBlack),
                    ),
                  ),
                ),
              ),
          ),
        ),
        // ── Label nama skin aktif ──
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            skinItems.firstWhere((e) => e.id == _activeSkinId, orElse: () => skinItems.first).name,
            style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 18, color: _kBlack),
          ),
        ),
        // ── Color swatches ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: skinItems.map((item) {
              final owned = _ownedIds.contains(item.id);
              final isActive = _activeSkinId == item.id;
              return GestureDetector(
                onTap: () {
                  if (owned || item.price == 0) {
                    _ownedIds.add(item.id);
                    _equipSkin(item);
                  } else {
                    _showBuyDialog(item);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? _kBlack : (owned ? _kGreen : const Color(0xFFCCCCCC)),
                      width: isActive ? 3 : 2,
                    ),
                    boxShadow: isActive
                        ? const [BoxShadow(color: _kBlack, offset: Offset(3, 3), blurRadius: 0)]
                        : owned
                            ? [const BoxShadow(color: _kGreen, offset: Offset(3, 3), blurRadius: 0)]
                            : null,
                  ),
                  child: Stack(
                    children: [
                      if (isActive)
                        const Center(child: Icon(Icons.check_rounded, size: 22, color: _kBlack)),
                      if (!owned)
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _kYellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kBlack, width: 1),
                            ),
                            child: const Text('🆓', style: TextStyle(fontSize: 8)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    final items = _filteredItems;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final owned = _ownedIds.contains(item.id);
        final isActive = item.outfitPart == OutfitPart.skin && _activeSkinId == item.id;
        return _ShopItemCard(
          item: item,
          owned: owned,
          isActive: isActive,
          canAfford: _totalCoins >= item.price,
          onBuy: owned
              ? (item.outfitPart == OutfitPart.skin ? () => _equipSkin(item) : null)
              : () => _showBuyDialog(item),
        );
      },
    );
  }

  void _showBuyDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (_) => _BuyDialog(
        item: item,
        currentCoins: _totalCoins,
        onConfirm: () => _buyItem(item),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop item card
// ─────────────────────────────────────────────────────────────────────────────

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool isActive;
  final bool canAfford;
  final VoidCallback? onBuy;

  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);

  const _ShopItemCard({required this.item, required this.owned, required this.isActive, required this.canAfford, this.onBuy});

  @override
  Widget build(BuildContext context) {
    final isDark = item.bgColor.computeLuminance() < 0.2;
    final dimmed = !owned && !canAfford;

    return GestureDetector(
      onTap: onBuy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: dimmed ? item.bgColor.withOpacity(0.5) : item.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? _kYellow : (owned ? _kGreen : _kBlack), width: isActive ? 3 : (owned ? 2.5 : 2)),
          boxShadow: [BoxShadow(color: isActive ? _kYellow : (owned ? _kGreen : _kBlack), offset: const Offset(3, 3), blurRadius: 0)],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.outfitPart == OutfitPart.skin && item.avatarFile != null
                        ? Image.asset(
                            'assets/images/avatars/${item.avatarFile}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Icon(item.icon, size: 28, color: isDark ? Colors.white : _kBlack)),
                          )
                        : Center(
                            child: Icon(item.icon, size: 28, color: isDark ? Colors.white : _kBlack),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(item.name, maxLines: 2, textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white : _kBlack)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? _kYellow : (owned ? _kGreen : (canAfford ? _kYellow : const Color(0xFFDDDDDD))),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBlack, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isActive ? '✓' : (owned ? '✓' : '🪙'), style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          isActive ? 'Equipped' : (owned ? 'Owned' : (item.price == 0 ? 'Free' : item.price.toString())),
                          style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: _kBlack),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (isActive)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: _kYellow, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: _kBlack),
                ),
              )
            else if (owned)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: _kBlack),
                ),
              ),
            if (dimmed)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buy dialog
// ─────────────────────────────────────────────────────────────────────────────

class _BuyDialog extends StatelessWidget {
  final ShopItem item;
  final int currentCoins;
  final VoidCallback onConfirm;

  static const _kBlack  = Color(0xFF111111);
  static const _kYellow = Color(0xFFF2EA05);
  static const _kGreen  = Color(0xFF1EE86F);

  const _BuyDialog({required this.item, required this.currentCoins, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final canAfford = currentCoins >= item.price;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _kBlack, width: 2.5)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBlack, width: 2)),
              clipBehavior: Clip.antiAlias,
              child: item.outfitPart == OutfitPart.skin && item.avatarFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/avatars/${item.avatarFile}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(item.icon, size: 32, color: _kBlack),
                      ),
                    )
                  : Icon(item.icon, size: 32, color: _kBlack),
            ),
            const SizedBox(height: 12),
            Text(item.name, style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 18, color: _kBlack)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  item.price == 0 ? 'Free!' : '${item.price} Coins',
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: _kBlack),
                ),
              ],
            ),
            if (item.price > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Saldo kamu: $currentCoins Coins',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: canAfford ? const Color(0xFF888888) : Colors.red),
              ),
              if (!canAfford)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Coin tidak cukup!', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.red, fontWeight: FontWeight.w700)),
                ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBlack, width: 2),
                        boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: const Center(child: Text('Cancel', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: _kBlack))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: canAfford ? () { Navigator.of(context).pop(); onConfirm(); } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: canAfford ? _kGreen : const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBlack, width: 2),
                        boxShadow: const [BoxShadow(color: _kBlack, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: Center(child: Text(
                        item.price == 0 ? 'Get it!' : 'Buy!',
                        style: const TextStyle(fontFamily: 'BlackHanSans', fontSize: 14, color: _kBlack),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}