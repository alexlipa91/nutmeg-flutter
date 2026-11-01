import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nutmeg/l10n/app_localizations.dart';
import 'package:nutmeg/state/UserState.dart';
import 'package:nutmeg/utils/UiUtils.dart';
import 'package:nutmeg/widgets/Avatar.dart';
import 'package:provider/provider.dart';

/// Wraps the main screens with a floating bottom navigation bar (Play,
/// Leaderboard, Profile). The bar is only shown on those top level screens,
/// not on match details or the create/login flows, which have their own
/// bottom actions.
class MainShell extends StatelessWidget {
  final String path;
  final Widget child;

  const MainShell({Key? key, required this.path, required this.child})
      : super(key: key);

  /// Index of the tab for [path], or null when the bar should be hidden.
  static int? tabIndexFor(String path) {
    if (path == '/') return 0;
    if (path == '/leaderboard' || path.startsWith('/leaderboard/')) return 1;
    if (path == '/user') return 2;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var index = tabIndexFor(path);
    return Scaffold(
      backgroundColor: Palette.greyLightest,
      resizeToAvoidBottomInset: false,
      // The pill floats over the page instead of cutting it off at a line;
      // the pages get the bar height as bottom padding from the Scaffold.
      extendBody: true,
      body: child,
      bottomNavigationBar: index == null ? null : _NavPill(index: index),
    );
  }
}

class _NavPill extends StatelessWidget {
  final int index;

  const _NavPill({required this.index});

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    var userState = context.watch<UserState>();
    var profileIcon = userState.isLoggedIn()
        ? Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: index == 2 ? Palette.primary : Colors.transparent,
                  width: 2),
            ),
            child: UserAvatar(12, userState.getLoggedUserDetails()),
          )
        : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
        // heightFactor: the bottom bar slot allows the full screen height, and
        // a plain Center would expand to fill it.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 440),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                      color: Palette.black.withOpacity(0.16),
                      blurRadius: 20,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Row(children: [
                _NavItem(
                    label: l10n.navPlay,
                    icon: Icons.sports_soccer,
                    selected: index == 0,
                    onTap: () => context.go('/')),
                _NavItem(
                    label: l10n.navLeaderboard,
                    icon: Icons.emoji_events,
                    selected: index == 1,
                    onTap: () => context.go('/leaderboard')),
                _NavItem(
                    label: l10n.navProfile,
                    icon: Icons.person,
                    iconOverride: profileIcon,
                    selected: index == 2,
                    onTap: () => context.go('/user')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? iconOverride;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.label,
      required this.icon,
      this.iconOverride,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    var color = selected ? Palette.primary : Palette.greyDark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                height: 30,
                child: Center(
                    child: iconOverride ?? Icon(icon, size: 26, color: color))),
            SizedBox(height: 2),
            Text(label,
                style: TextPalette.getBodyText(color).copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
