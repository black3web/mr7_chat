import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/mr7_logo.dart';
import '../chat/chats_tab.dart';
import '../chat/groups_tab.dart';
import '../ai/ai_services_tab.dart';
import 'home_drawer.dart';
import 'stories_row.dart';
import 'broadcast_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppProvider>().refreshUser());
  }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    if (p.currentUser == null) return const SizedBox();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: HomeDrawer(scaffoldKey: _scaffoldKey),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          _buildTopBar(context, l),
          const BroadcastBanner(),
          const StoriesRow(),
          _buildTabBar(l),
          Expanded(child: TabBarView(controller: _tabCtrl, children: const [ChatsTab(), GroupsTab(), AiServicesTab()])),
        ])),
      ),
    );
  }
  Widget _buildTopBar(BuildContext context, AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      _iconBtn(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
      const Spacer(),
      const MR7Logo(fontSize: 26),
      const Spacer(),
      _iconBtn(Icons.search_rounded, () => Navigator.pushNamed(context, AppRoutes.search)),
    ]),
  );
  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.glassBase, border: Border.all(color: AppColors.glassBorder)),
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    ),
  );
  Widget _buildTabBar(AppLocalizations l) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    height: 44,
    decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
    child: TabBar(
      controller: _tabCtrl,
      indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      padding: const EdgeInsets.all(3),
      tabs: [Tab(text: l['chats']), Tab(text: l['groups']), Tab(text: l['aiServices'])],
    ),
  );
}