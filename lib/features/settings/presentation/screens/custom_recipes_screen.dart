import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/automation/automation_recipe_engine.dart';
import '../../../../core/automation/models/automation_recipe.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../widgets/create_recipe_sheet.dart';

class CustomRecipesScreen extends ConsumerStatefulWidget {
  const CustomRecipesScreen({super.key});

  @override
  ConsumerState<CustomRecipesScreen> createState() =>
      _CustomRecipesScreenState();
}

class _CustomRecipesScreenState extends ConsumerState<CustomRecipesScreen> {
  List<AutomationRecipe> _recipes = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'builtin', 'custom'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AutomationRecipeEngine.loadRecipes();
    if (mounted) {
      setState(() {
        _recipes = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRecipe(AutomationRecipe r, bool val) async {
    await AutomationRecipeEngine.toggleRecipe(r.id, val);
    EtoleHaptics.selection();
    await _load();
  }

  Future<void> _testFire(AutomationRecipe r) async {
    EtoleHaptics.medium();
    final db = ref.read(databaseProvider);
    await AutomationRecipeEngine.testFireRecipe(r, db);
    EtoleHaptics.success();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF14171B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00E5FF)),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Test-fired "${r.title}". Action executed!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      await _load();
    }
  }

  Future<void> _delete(AutomationRecipe r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Text(
          'Delete Automation Pipeline?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete "${r.title}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AutomationRecipeEngine.deleteRecipe(r.id);
      EtoleHaptics.warning();
      await _load();
    }
  }

  void _openCreateSheet({AutomationRecipe? recipe}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateRecipeSheet(recipeToEdit: recipe, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _recipes.where((r) => r.isEnabled).length;
    final totalFired = _recipes.fold<int>(0, (acc, r) => acc + r.triggerCount);

    final filtered = _recipes.where((r) {
      if (_selectedFilter == 'builtin') return r.isBuiltIn;
      if (_selectedFilter == 'custom') return !r.isBuiltIn;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOM RECIPES',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.0,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Event-Driven Automation Pipelines (IF-THIS-THEN-THAT)',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openCreateSheet(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF00E5FF),
                        size: 20,
                      ),
                    ),
                    tooltip: 'New Recipe',
                  ),
                ],
              ),
            ),

            // Summary Stats Pill Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14171B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('PIPELINES', '${_recipes.length}'),
                    _buildStatDivider(),
                    _buildStatCol(
                      'ACTIVE',
                      '$activeCount',
                      color: const Color(0xFF00E5FF),
                    ),
                    _buildStatDivider(),
                    _buildStatCol(
                      'TOTAL FIRED',
                      '$totalFired',
                      color: const Color(0xFFF5A623),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip('All Pipelines', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Mogul Presets', 'builtin'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Custom Pipelines', 'custom'),
                ],
              ),
            ),

            // Recipe List
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        size: 48,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No automation recipes found in this view',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openCreateSheet(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create First Recipe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: const Color(0xFF080B0F),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final recipe = filtered[idx];
                    return _buildRecipeCard(recipe);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(),
        backgroundColor: const Color(0xFF00E5FF),
        foregroundColor: const Color(0xFF080B0F),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'NEW RECIPE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 24, color: Colors.white12);
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = value);
        EtoleHaptics.selection();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
              : const Color(0xFF14171B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(AutomationRecipe recipe) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recipe.isEnabled
              ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
              : Colors.white12,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Badges & Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 4),
            child: Row(
              children: [
                // Builtin vs Custom tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: recipe.isBuiltIn
                        ? const Color(0xFFF5A623).withValues(alpha: 0.15)
                        : const Color(0xFF007A3D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: recipe.isBuiltIn
                          ? const Color(0xFFF5A623).withValues(alpha: 0.5)
                          : const Color(0xFF007A3D).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    recipe.isBuiltIn ? 'MOGUL PRESET' : 'CUSTOM PIPELINE',
                    style: TextStyle(
                      color: recipe.isBuiltIn
                          ? const Color(0xFFF5A623)
                          : const Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: recipe.isEnabled,
                  onChanged: (v) => _toggleRecipe(recipe, v),
                  activeColor: const Color(0xFF00E5FF),
                  activeTrackColor: const Color(0xFF00E5FF)
                      .withValues(alpha: 0.3),
                  inactiveThumbColor: Colors.white30,
                  inactiveTrackColor: Colors.white10,
                ),
              ],
            ),
          ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: TextStyle(
                    color: recipe.isEnabled ? Colors.white : Colors.white54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.description,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Logic Flow Blocks: WHEN -> IF -> THEN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF080B0F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildFlowRow(
                    label: 'WHEN',
                    text: recipe.trigger.displayName,
                    labelColor: const Color(0xFF00E5FF),
                    icon: Icons.flash_on_rounded,
                  ),
                  if (recipe.conditionType != 'always') ...[
                    const Divider(color: Colors.white10, height: 12),
                    _buildFlowRow(
                      label: 'AND IF',
                      text: recipe.conditionType == 'min_amount'
                          ? 'Value ≥ KES ${recipe.conditionValue}'
                          : 'Status contains "${recipe.conditionValue}"',
                      labelColor: const Color(0xFFF5A623),
                      icon: Icons.filter_alt_rounded,
                    ),
                  ],
                  const Divider(color: Colors.white10, height: 12),
                  _buildFlowRow(
                    label: 'THEN',
                    text: recipe.action.displayName,
                    labelColor: const Color(0xFF00E5FF),
                    icon: Icons.play_arrow_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Footer Telemetry & Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Icon(
                  Icons.electric_bolt_rounded,
                  size: 13,
                  color: recipe.triggerCount > 0
                      ? const Color(0xFF00E5FF)
                      : Colors.white24,
                ),
                const SizedBox(width: 4),
                Text(
                  recipe.triggerCount > 0
                      ? 'Fired ${recipe.triggerCount}x'
                      : 'Never fired',
                  style: TextStyle(
                    color: recipe.triggerCount > 0
                        ? const Color(0xFFCBD5E1)
                        : Colors.white30,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (recipe.lastTriggeredAt != null) ...[
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                  Text(
                    dateFormat.format(recipe.lastTriggeredAt!),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
                const Spacer(),
                // Test Fire Button
                TextButton.icon(
                  onPressed: () => _testFire(recipe),
                  icon: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 15,
                    color: Color(0xFF00E5FF),
                  ),
                  label: const Text(
                    'Test Fire',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                // Edit Button
                IconButton(
                  onPressed: () => _openCreateSheet(recipe: recipe),
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: Colors.white60,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit',
                ),
                // Delete Button
                if (!recipe.isBuiltIn)
                  IconButton(
                    onPressed: () => _delete(recipe),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Color(0xFFD32F2F),
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRow({
    required String label,
    required String text,
    required Color labelColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w900,
              fontSize: 8.5,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: labelColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
