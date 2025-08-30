import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../widgets/forms/custom_text_field.dart';
import '../../../../widgets/forms/custom_dropdown.dart';

class InfluencersFilterScreen extends StatefulWidget {
  final int? currentMinRating;
  final int? currentMaxRating;
  final String? currentZone;
  final Function(int? minRating, int? maxRating, String? zone)? onFilterApplied;

  const InfluencersFilterScreen({
    super.key,
    this.currentMinRating,
    this.currentMaxRating,
    this.currentZone,
    this.onFilterApplied,
  });

  @override
  State<InfluencersFilterScreen> createState() =>
      _InfluencersFilterScreenState();
}

class _InfluencersFilterScreenState extends State<InfluencersFilterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController minRatingController = TextEditingController();
  final TextEditingController maxRatingController = TextEditingController();
  String? selectedZone;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // French departments (départements) for zone selection
  final List<String> frenchDepartments = [
    'Ain (01)',
    'Aisne (02)',
    'Allier (03)',
    'Alpes-de-Haute-Provence (04)',
    'Hautes-Alpes (05)',
    'Alpes-Maritimes (06)',
    'Ardèche (07)',
    'Ardennes (08)',
    'Ariège (09)',
    'Aube (10)',
    'Aude (11)',
    'Aveyron (12)',
    'Bouches-du-Rhône (13)',
    'Calvados (14)',
    'Cantal (15)',
    'Charente (16)',
    'Charente-Maritime (17)',
    'Cher (18)',
    'Corrèze (19)',
    'Corse (2A)',
    'Côte-d\'Or (21)',
    'Côtes-d\'Armor (22)',
    'Creuse (23)',
    'Dordogne (24)',
    'Doubs (25)',
    'Drôme (26)',
    'Eure (27)',
    'Eure-et-Loir (28)',
    'Finistère (29)',
    'Gard (30)',
    'Haute-Garonne (31)',
    'Gers (32)',
    'Gironde (33)',
    'Hérault (34)',
    'Ille-et-Vilaine (35)',
    'Indre (36)',
    'Indre-et-Loire (37)',
    'Isère (38)',
    'Jura (39)',
    'Landes (40)',
    'Loir-et-Cher (41)',
    'Loire (42)',
    'Haute-Loire (43)',
    'Loire-Atlantique (44)',
    'Loiret (45)',
    'Lot (46)',
    'Lot-et-Garonne (47)',
    'Lozère (48)',
    'Maine-et-Loire (49)',
    'Manche (50)',
    'Marne (51)',
    'Haute-Marne (52)',
    'Mayenne (53)',
    'Meurthe-et-Moselle (54)',
    'Meuse (55)',
    'Morbihan (56)',
    'Moselle (57)',
    'Nièvre (58)',
    'Nord (59)',
    'Oise (60)',
    'Orne (61)',
    'Pas-de-Calais (62)',
    'Puy-de-Dôme (63)',
    'Pyrénées-Atlantiques (64)',
    'Hautes-Pyrénées (65)',
    'Pyrénées-Orientales (66)',
    'Bas-Rhin (67)',
    'Haut-Rhin (68)',
    'Rhône (69)',
    'Haute-Saône (70)',
    'Saône-et-Loire (71)',
    'Sarthe (72)',
    'Savoie (73)',
    'Haute-Savoie (74)',
    'Paris (75)',
    'Seine-Maritime (76)',
    'Seine-et-Marne (77)',
    'Yvelines (78)',
    'Deux-Sèvres (79)',
    'Somme (80)',
    'Tarn (81)',
    'Tarn-et-Garonne (82)',
    'Var (83)',
    'Vaucluse (84)',
    'Vendée (85)',
    'Vienne (86)',
    'Haute-Vienne (87)',
    'Vosges (88)',
    'Yonne (89)',
    'Territoire de Belfort (90)',
    'Essonne (91)',
    'Hauts-de-Seine (92)',
    'Seine-Saint-Denis (93)',
    'Val-de-Marne (94)',
    'Val-d\'Oise (95)',
    'Guadeloupe (971)',
    'Martinique (972)',
    'Guyane (973)',
    'La Réunion (974)',
    'Mayotte (976)'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    minRatingController.text = widget.currentMinRating?.toString() ?? '1';
    maxRatingController.text = widget.currentMaxRating?.toString() ?? '5';
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
    minRatingController.dispose();
    maxRatingController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final minRating = int.tryParse(minRatingController.text);
    final maxRating = int.tryParse(maxRatingController.text);

    if (minRating == null || maxRating == null) {
      // Show error for invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid ratings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (minRating < 1 || maxRating > 5) {
      // Show error for invalid range
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating must be between 1 and 5'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (minRating > maxRating) {
      // Show error for invalid range
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Min rating cannot be greater than max rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Apply filter
    context.read<InfluencersBloc>().add(LoadInfluencers(
          zone: selectedZone,
          sortOrder: 'DESC',
        ));

    // Update parent widget with filter values
    widget.onFilterApplied?.call(minRating, maxRating, selectedZone);

    // Close the filter screen
    Navigator.of(context).pop();
  }

  void _cancelFilter() {
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    setState(() {
      minRatingController.text = '1';
      maxRatingController.text = '5';
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
                          // Rating Section
                          Text(
                            'Rating & Zone',
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Min/Max Rating Inputs
                          Row(
                            children: [
                              // Min Rating
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Min',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: minRatingController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[1-5]')),
                                        ],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '1',
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Max Rating
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Max',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: maxRatingController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[1-5]')),
                                        ],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '5',
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Zone Section
                          Text(
                            'Zone',
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
                                suffixIcon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppTheme.textSecondaryColor,
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
                                ...frenchDepartments
                                    .map((zone) => DropdownMenuItem<String>(
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

                              // Reset Filter Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _resetFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 12),
                                    ),
                                    child: const Text(
                                      'Reset filter',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
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
