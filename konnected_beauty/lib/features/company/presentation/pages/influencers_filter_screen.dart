import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/models/filter_model.dart';

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

class _InfluencersFilterScreenState extends State<InfluencersFilterScreen>
    with SingleTickerProviderStateMixin {
  String? selectedZone;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Zones used in influencer profile (same as personal_information_screen.dart)
  final List<String> zones = [
    // Île-de-France
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

    // Auvergne-Rhône-Alpes
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

    // Provence-Alpes-Côte d'Azur
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

    // Nouvelle-Aquitaine
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

    // Occitanie
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

    // Pays de la Loire
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

    // Grand Est
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

    // Hauts-de-France
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

    // Bourgogne-Franche-Comté
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

    // Centre-Val de Loire
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

    // Normandie
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

    // Bretagne
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

    // Corse
    'Ajaccio',
    'Bastia',
    'Porto-Vecchio',
    'Calvi',
    'Corte',
    'Sartène',
    'Propriano',
    'L\'Île-Rousse',
    'Bonifacio',
    'Penta-di-Casinca'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with current zone
    selectedZone = widget.currentZone;

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    print('🔍 === APPLYING ZONE FILTER ===');
    print('🔍 Selected Zone: $selectedZone');
    print('🔍 Using backend API filtering for zone filter');

    // Create filters using the new filter system
    List<FilterModel> filters = [
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
        uuid: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      ),
      FilterModel(
        key: 'sortOrder',
        value: 'DESC',
        description: 'Sort order',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
      ),
    ];

    // Add zone filter if selected
    if (selectedZone != null && selectedZone!.isNotEmpty) {
      print('🔍 Adding zone filter: $selectedZone');
      filters.add(FilterModel(
        key: 'zone',
        value: selectedZone!,
        description: 'Location zone',
        enabled: true,
        equals: true,
        uuid: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
      ));
    } else {
      print('🔍 No zone selected, will show all zones');
    }

    print('🔍 Total filters: ${filters.length}');
    print('🔍 === END ZONE FILTER CREATION ===');

    // Apply filters using backend API filtering
    context.read<InfluencersBloc>().add(FilterInfluencers(filters: filters));

    // Update parent widget with filter values
    widget.onFilterApplied?.call(selectedZone);

    // Close the filter screen
    Navigator.of(context).pop();
  }

  void _cancelFilter() {
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    setState(() {
      selectedZone = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minHeight: MediaQuery.of(context).size.height * 0.33,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        'Filter',
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Filter content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Zone Section
                          Text(
                            'Filter by Zone',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Zone Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.borderColor,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selectedZone,
                              decoration: const InputDecoration(
                                hintText: 'Select zone',
                                hintStyle: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 16,
                              ),
                              dropdownColor: AppTheme.secondaryColor,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All zones'),
                                ),
                                ...zones.map((zone) => DropdownMenuItem<String>(
                                      value: zone,
                                      child: Text(zone),
                                    )),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedZone = value;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _cancelFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor:
                                          AppTheme.textPrimaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppTheme.textPrimaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Confirm Filter Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _applyFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.transparentBackground,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppTheme.textPrimaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
