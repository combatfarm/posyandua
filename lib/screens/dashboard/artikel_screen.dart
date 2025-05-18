import 'package:flutter/material.dart';

class ArtikelScreen extends StatefulWidget {
  @override
  _ArtikelScreenState createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Gizi', 'Imunisasi', 'Kesehatan', 'Tumbuh Kembang'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.1, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _filteredArticles() {
    if (_selectedCategory == 'Semua') {
      return artikelList;
    } else {
      return artikelList.where((artikel) => artikel['category'] == _selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final filteredArticles = _filteredArticles();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: screenSize.height * 0.25,
            pinned: true,
            backgroundColor: Colors.teal.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Artikel Kesehatan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Categories
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal.shade700 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Featured Article
          if (filteredArticles.isNotEmpty) SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artikel Unggulan',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    FeaturedArticleCard(
                      article: filteredArticles.first,
                      onTap: () {
                        // Navigate to article detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Artikel detail akan segera hadir'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Article List
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                filteredArticles.length > 1 ? 'Artikel Lainnya' : 'Artikel',
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Skip the first article if we're showing it as featured
                if (filteredArticles.length > 1 && index == 0) return SizedBox.shrink();
                
                final int actualIndex = filteredArticles.length > 1 ? index + 1 : index;
                if (actualIndex >= filteredArticles.length) return SizedBox.shrink();
                
                final article = filteredArticles[actualIndex];
                
                return Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, index == filteredArticles.length - 1 ? 16 : 0),
                  child: ArticleCard(
                    article: article,
                    index: index,
                    animation: _fadeAnimation,
                    onTap: () {
                      // Navigate to article detail
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Artikel detail akan segera hadir'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: filteredArticles.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade700,
        child: Icon(Icons.search),
        onPressed: () {
          // Show search functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fitur pencarian akan segera hadir'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class FeaturedArticleCard extends StatelessWidget {
  final Map<String, String> article;
  final VoidCallback onTap;

  const FeaturedArticleCard({
    Key? key,
    required this.article,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: article['imageUrl'] != null && article['imageUrl']!.startsWith('http')
                ? Image.network(
                    article['imageUrl']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.teal.shade300,
                    child: Center(
                      child: Icon(
                        getCategoryIcon(article['category'] ?? 'Kesehatan'),
                        size: 60,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getCategoryColor(article['category'] ?? 'Kesehatan'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article['category'] ?? 'Kesehatan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.8)),
                      SizedBox(width: 4),
                      Text(
                        article['date'] ?? '25 Feb 2025',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.white.withOpacity(0.8)),
                      SizedBox(width: 4),
                      Text(
                        article['views'] ?? '248',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Map<String, String> article;
  final int index;
  final Animation<double> animation;
  final VoidCallback onTap;

  const ArticleCard({
    Key? key,
    required this.article,
    required this.index,
    required this.animation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final delay = 0.2 + (index * 0.1);
    final slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.2, curve: Curves.easeOut),
      ),
    );
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: slideAnimation.value,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  color: getCategoryColor(article['category'] ?? 'Kesehatan').withOpacity(0.2),
                  child: article['imageUrl'] != null && article['imageUrl']!.startsWith('http')
                    ? Image.network(
                        article['imageUrl']!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          getCategoryIcon(article['category'] ?? 'Kesehatan'),
                          size: 40,
                          color: getCategoryColor(article['category'] ?? 'Kesehatan'),
                        ),
                      ),
                ),
              ),
              // Article details
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category and date
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getCategoryColor(article['category'] ?? 'Kesehatan'),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              article['category'] ?? 'Kesehatan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Spacer(),
                          Text(
                            article['date'] ?? '25 Feb 2025',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Title
                      Text(
                        article['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Description
                      Text(
                        article['description'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Helper functions
IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Gizi':
      return Icons.restaurant;
    case 'Imunisasi':
      return Icons.vaccines;
    case 'Tumbuh Kembang':
      return Icons.child_care;
    default:
      return Icons.healing;
  }
}

Color getCategoryColor(String category) {
  switch (category) {
    case 'Gizi':
      return Colors.orange.shade700;
    case 'Imunisasi':
      return Colors.purple.shade700;
    case 'Tumbuh Kembang':
      return Colors.blue.shade700;
    default:
      return Colors.teal.shade700;
  }
}

// Sample data
final List<Map<String, String>> artikelList = [
  {
    'title': 'Pentingnya ASI Eksklusif untuk Perkembangan Bayi',
    'description': 'ASI eksklusif adalah pemberian ASI saja pada bayi sampai usia 6 bulan. Manfaatnya sangat banyak untuk tumbuh kembang dan kekebalan tubuh bayi.',
    'imageUrl': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'category': 'Gizi',
    'date': '20 Feb 2025',
    'views': '325',
  },
  {
    'title': 'Mencegah Stunting Sejak Dini pada Anak',
    'description': 'Stunting dapat dicegah dengan memperhatikan asupan gizi sejak masa kehamilan dan memberikan makanan bergizi seimbang pada anak.',
    'imageUrl': 'https://images.unsplash.com/photo-1590789243516-b9fed569f898?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'category': 'Tumbuh Kembang',
    'date': '18 Feb 2025',
    'views': '198',
  },
  {
    'title': 'Panduan Makanan Bergizi untuk Balita',
    'description': 'Makanan bergizi seimbang sangat penting untuk pertumbuhan optimal balita. Pelajari menu-menu sehat yang bisa diberikan sesuai usia anak.',
    'imageUrl': 'https://images.unsplash.com/photo-1604908550665-327363165682?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1530&q=80',
    'category': 'Gizi',
    'date': '15 Feb 2025',
    'views': '276',
  },
  {
    'title': 'Jadwal Imunisasi Lengkap untuk Anak',
    'description': 'Imunisasi adalah cara efektif untuk melindungi anak dari berbagai penyakit berbahaya. Ketahui jadwal imunisasi yang tepat untuk anak.',
    'imageUrl': 'https://images.unsplash.com/photo-1623854767648-e7bb8009f0db?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1374&q=80',
    'category': 'Imunisasi',
    'date': '10 Feb 2025',
    'views': '214',
  },
  {
    'title': 'Tips Merawat Kesehatan Anak selama Musim Hujan',
    'description': 'Musim hujan meningkatkan risiko berbagai penyakit. Pelajari cara menjaga kesehatan anak selama musim hujan dengan tips praktis ini.',
    'imageUrl': 'https://images.unsplash.com/photo-1474942578142-9a63782dfdfb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1376&q=80',
    'category': 'Kesehatan',
    'date': '5 Feb 2025',
    'views': '183',
  },
  {
    'title': 'Peran Ayah dalam Perkembangan Anak',
    'description': 'Keterlibatan ayah memiliki dampak signifikan pada perkembangan kognitif, emosional, dan sosial anak. Pelajari cara ayah bisa lebih terlibat dalam pengasuhan.',
    'imageUrl': 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
    'category': 'Tumbuh Kembang',
    'date': '1 Feb 2025',
    'views': '165',
  },
  {
    'title': 'Mengenal Vaksin Terbaru untuk Balita',
    'description': 'Perkembangan vaksin terbaru semakin meningkatkan perlindungan bagi anak-anak. Pelajari jenis vaksin terbaru yang direkomendasikan untuk balita.',
    'imageUrl': 'https://images.unsplash.com/photo-1632168844625-b22d1ee5526c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1374&q=80',
    'category': 'Imunisasi',
    'date': '28 Jan 2025',
    'views': '156',
  },
];

