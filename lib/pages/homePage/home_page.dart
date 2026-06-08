import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onTripPage/map_page.dart';
import '../navDrawer/nav_drawer.dart';

class RungoHomePage extends StatefulWidget {
  const RungoHomePage({super.key});

  @override
  State<RungoHomePage> createState() => _RungoHomePageState();
}

class _RungoHomePageState extends State<RungoHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0D0D),
      drawer: NavDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(scaffoldKey: _scaffoldKey),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _PromoBanner(),
                      const SizedBox(height: 20),
                      _ServicesGrid(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _WhereToBar(
        onTap: () {
          openDestinationOnLoad = true;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Maps()),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _TopBar({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // bouton menu burger rouge (comme screenshot)
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF8B1A1A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
          const Spacer(),
          // Logo RUN + GO
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                  text: 'RUN',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
              TextSpan(
                  text: 'GO',
                  style: TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5)),
            ]),
          ),
          const Spacer(),
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1C1C1C),
              border: Border.all(color: const Color(0xFF8B1A1A), width: 2),
            ),
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF9E9E9E), size: 22),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  BANNIÈRE PROMO  (fond jaune/or comme screenshot)
// ══════════════════════════════════════════════
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFCC00), Color(0xFFFFAA00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // cercles décoratifs
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // grande icône voiture à droite
          const Positioned(
            right: 10,
            top: 10,
            bottom: 10,
            child: Icon(
              Icons.directions_car_rounded,
              size: 130,
              color: Colors.white,
            ),
          ),

          // texte gauche
          Positioned(
            left: 20,
            top: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // label RUNGO
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('RUNGO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5)),
                ),
                const SizedBox(height: 6),
                // grand titre TAXI
                const Text(
                  'TAXI',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
          ),

          // bandeau bas : promo + SERVICE
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black.withOpacity(0.22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PREMIER TRAJET',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      Text('500 F OFFERTS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('SERVICE',
                        style: TextStyle(
                            color: Color(0xFFFFCC00),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

const List<_ServiceData> _serviceItems = [
  _ServiceData(
    label: 'Livraison',
    sublabel: 'Colis & courses',
    icon: Icons.inventory_2_rounded,
    iconColor: Color(0xFF4FC3F7),
    bgColor: Color(0xFF0D1F2D),
  ),
  _ServiceData(
    label: 'Voiture',
    sublabel: 'dès 4 min',
    icon: Icons.directions_car_rounded,
    iconColor: Colors.white,
    bgColor: Color(0xFF12122A),
  ),
  _ServiceData(
    label: 'Moto-Rapide',
    sublabel: 'dès 2 min',
    icon: Icons.motorcycle_rounded,
    iconColor: Color(0xFFFFCC00),
    bgColor: Color(0xFF1E1A00),
  ),
  _ServiceData(
    label: 'Tricycle',
    sublabel: 'Économique',
    icon: Icons.electric_rickshaw_rounded,
    iconColor: Color(0xFF2ECC71),
    bgColor: Color(0xFF001A0D),
  ),
];

class _ServicesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _serviceItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) => _ServiceCard(item: _serviceItems[i]),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.item});
  final _ServiceData item;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Maps()),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: item.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: item.iconColor.withOpacity(0.18), width: 1),
          ),
          child: Stack(
            children: [
              // cercle décoratif bas-droit
              Positioned(
                right: -24,
                bottom: -24,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // icône dans un carré arrondi
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                      Icon(item.icon, color: item.iconColor, size: 28),
                    ),

                    // label + sublabel
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: item.iconColor,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(item.sublabel,
                                style: TextStyle(
                                    color: item.iconColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhereToBar extends StatelessWidget {
  final VoidCallback onTap;
  const _WhereToBar({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Maps()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2A2A2A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // vignette voiture
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1A1A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: Color(0xFF8B1A1A), size: 20),
              ),
              const SizedBox(width: 14),

              const Expanded(
                child: Text('Où allez-vous ?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),


              // flèche rouge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

