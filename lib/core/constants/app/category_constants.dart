// lib/core/constants/app/category_constants.dart
//
// FAZ 11 — F11-01: Kategori metadata (slug, etiket, ikon, grup)

enum CategoryGroup { level, domain }

class CategoryInfo {
  final String slug;
  final String label;
  final String icon;
  final CategoryGroup group;

  const CategoryInfo({
    required this.slug,
    required this.label,
    required this.icon,
    required this.group,
  });
}

class CategoryConstants {
  CategoryConstants._();

  static const List<CategoryInfo> all = [
    // ── Dil Seviyeleri ──────────────────────────────────────────────────────
    CategoryInfo(slug: 'a1', label: 'A1', icon: '🌱', group: CategoryGroup.level),
    CategoryInfo(slug: 'a2', label: 'A2', icon: '🌿', group: CategoryGroup.level),
    CategoryInfo(slug: 'b1', label: 'B1', icon: '🌳', group: CategoryGroup.level),
    CategoryInfo(slug: 'b2', label: 'B2', icon: '🏔', group: CategoryGroup.level),
    CategoryInfo(slug: 'c1', label: 'C1', icon: '⭐', group: CategoryGroup.level),
    CategoryInfo(slug: 'c2', label: 'C2', icon: '💎', group: CategoryGroup.level),

    // ── Alan Kategorileri ────────────────────────────────────────────────────
    CategoryInfo(slug: 'business', label: 'İş', icon: '💼', group: CategoryGroup.domain),
    CategoryInfo(
      slug: 'engineering-and-manufacturing',
      label: 'Mühendislik',
      icon: '⚙',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'finance-and-accounting',
      label: 'Finans',
      icon: '💰',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'hospitality-and-tourism',
      label: 'Turizm',
      icon: '✈',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'it-and-software-development',
      label: 'Yazılım',
      icon: '💻',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'legal-and-law',
      label: 'Hukuk',
      icon: '⚖',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'marketing-and-advertising',
      label: 'Pazarlama',
      icon: '📢',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'medical-and-healthcare',
      label: 'Tıp',
      icon: '🏥',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'oxford-american',
      label: 'Oxford',
      icon: '📚',
      group: CategoryGroup.domain,
    ),
    CategoryInfo(
      slug: 'science-and-research',
      label: 'Bilim',
      icon: '🔬',
      group: CategoryGroup.domain,
    ),
  ];

  static List<CategoryInfo> get levels =>
      all.where((c) => c.group == CategoryGroup.level).toList();

  static List<CategoryInfo> get domains =>
      all.where((c) => c.group == CategoryGroup.domain).toList();

  /// Slug'a göre kategori bilgisi döner, bulunamazsa null.
  static CategoryInfo? findBySlug(String slug) {
    for (final c in all) {
      if (c.slug == slug) return c;
    }
    return null;
  }
}
