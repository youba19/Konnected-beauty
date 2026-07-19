import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/models/filter_model.dart';
import '../../../../core/translations/app_translations.dart';

abstract final class _InfluencersFilterUi {
  static const double radius = 16;
  static const double buttonRadius = 14;
}

class InfluencersFilterScreen extends StatefulWidget {
  final String? currentZone;
  final Function(String? zone)? onFilterApplied;

  const InfluencersFilterScreen({
    super.key,
    this.currentZone,
    this.onFilterApplied,
  });

  @override
  State<InfluencersFilterScreen> createState() =>
      _InfluencersFilterScreenState();
}

class _InfluencersFilterScreenState extends State<InfluencersFilterScreen> {
  String? selectedZone;

  final List<String> zones = const [
    'Paris',
    'Boulogne-Billancourt',
    'Saint-Denis',
    'Argenteuil',
    'Montreuil',
    'Nanterre',
    'Vitry-sur-Seine',
    'Créteil',
    'Aulnay-sous-Bois',
    'Versailles',
    'Lyon',
    'Grenoble',
    'Saint-Étienne',
    'Annecy',
    'Chambéry',
    'Clermont-Ferrand',
    'Saint-Priest',
    'Vaulx-en-Velin',
    'Villeurbanne',
    'Le Puy-en-Velay',
    'Marseille',
    'Nice',
    'Toulon',
    'Aix-en-Provence',
    'Avignon',
    'Cannes',
    'Antibes',
    'La Seyne-sur-Mer',
    'Hyères',
    'Fréjus',
    'Bordeaux',
    'Limoges',
    'Poitiers',
    'La Rochelle',
    'Angoulême',
    'Pau',
    'Bayonne',
    'Biarritz',
    'Périgueux',
    'Arcachon',
    'Toulouse',
    'Montpellier',
    'Nîmes',
    'Perpignan',
    'Béziers',
    'Narbonne',
    'Albi',
    'Carcassonne',
    'Tarbes',
    'Castres',
    'Nantes',
    'Angers',
    'Le Mans',
    'Saint-Nazaire',
    'Cholet',
    'Saint-Herblain',
    'Saint-Sébastien-sur-Loire',
    'Rezé',
    'Saint-Avertin',
    'La Roche-sur-Yon',
    'Strasbourg',
    'Reims',
    'Metz',
    'Nancy',
    'Mulhouse',
    'Colmar',
    'Troyes',
    'Charleville-Mézières',
    'Châlons-en-Champagne',
    'Épinal',
    'Lille',
    'Amiens',
    'Roubaix',
    'Tourcoing',
    'Dunkerque',
    'Valenciennes',
    'Villeneuve-d\'Ascq',
    'Saint-Quentin',
    'Beauvais',
    'Arras',
    'Dijon',
    'Besançon',
    'Chalon-sur-Saône',
    'Nevers',
    'Auxerre',
    'Mâcon',
    'Sens',
    'Le Creusot',
    'Montceau-les-Mines',
    'Beaune',
    'Tours',
    'Orléans',
    'Blois',
    'Bourges',
    'Chartres',
    'Châteauroux',
    'Joué-lès-Tours',
    'Vierzon',
    'Fleury-les-Aubrais',
    'Saint-Jean-de-Braye',
    'Rouen',
    'Le Havre',
    'Caen',
    'Cherbourg-en-Cotentin',
    'Évreux',
    'Dieppe',
    'Saint-Étienne-du-Rouvray',
    'Sotteville-lès-Rouen',
    'Le Grand-Quevilly',
    'Petit-Quevilly',
    'Rennes',
    'Brest',
    'Quimper',
    'Vannes',
    'Saint-Malo',
    'Saint-Brieuc',
    'Lorient',
    'Lanester',
    'Fougères',
    'Concarneau',
    'Ajaccio',
    'Bastia',
    'Porto-Vecchio',
    'Calvi',
    'Corte',
    'Sartène',
    'Propriano',
    'L\'Île-Rousse',
    'Bonifacio',
    'Penta-di-Casinca',
  ];

  @override
  void initState() {
    super.initState();
    selectedZone = widget.currentZone;
  }

  void _applyFilter() {
    final filters = <FilterModel>[
      FilterModel(
        key: 'page',
        value: '1',
        description: 'Page number',
        enabled: true,
        equals: true,
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      FilterModel(
        key: 'limit',
        value: '50',
        description: 'Items per page',
        enabled: true,
        equals: true,
        uuid: '${DateTime.now().millisecondsSinceEpoch + 1}',
      ),
      FilterModel(
        key: 'sortOrder',
        value: 'DESC',
        description: 'Sort order',
        enabled: true,
        equals: true,
        uuid: '${DateTime.now().millisecondsSinceEpoch + 2}',
      ),
    ];

    if (selectedZone != null && selectedZone!.isNotEmpty) {
      filters.add(FilterModel(
        key: 'zone',
        value: selectedZone!,
        description: 'Location zone',
        enabled: true,
        equals: true,
        uuid: '${DateTime.now().millisecondsSinceEpoch + 3}',
      ));
    }

    context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));
    widget.onFilterApplied?.call(selectedZone);
    Navigator.of(context).pop();
  }

  void _clearAndApply() {
    setState(() => selectedZone = null);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final ui = SalonUiTheme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: ui.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 170,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ui.sheetHeaderGradient,
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTranslations.getString(context, 'filter'),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: ui.sheetOverlayButton,
                            borderRadius: BorderRadius.circular(
                              _InfluencersFilterUi.buttonRadius,
                            ),
                            border: Border.all(
                              color: ui.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.x,
                            color: ui.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.getString(context, 'select_zone'),
                    style: TextStyle(
                      color: ui.isDark ? ui.textSecondary : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppTranslations.getString(context, 'filter_by_zone'),
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: ui.card,
                      borderRadius:
                          BorderRadius.circular(_InfluencersFilterUi.radius),
                      border: Border.all(
                        color: ui.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedZone,
                        isExpanded: true,
                        hint: Text(
                          AppTranslations.getString(context, 'select_zone'),
                          style: TextStyle(
                            color: ui.isDark ? ui.textMuted : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        icon: Icon(
                          LucideIcons.chevronDown,
                          color: ui.textPrimary,
                          size: 18,
                        ),
                        dropdownColor: ui.card,
                        style: TextStyle(
                          color: ui.textPrimary,
                          fontSize: 16,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              AppTranslations.getString(context, 'all_zones'),
                              style: TextStyle(
                                color: ui.textSecondary,
                              ),
                            ),
                          ),
                          ...zones.map(
                            (zone) => DropdownMenuItem<String>(
                              value: zone,
                              child: Text(zone),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedZone = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearAndApply,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ui.textPrimary,
                            side: BorderSide(
                              color: ui.outlinedButtonBorder,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _InfluencersFilterUi.buttonRadius,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'clear'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ui.primaryButtonBg,
                            foregroundColor: ui.primaryButtonFg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _InfluencersFilterUi.buttonRadius,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'apply_filter'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
