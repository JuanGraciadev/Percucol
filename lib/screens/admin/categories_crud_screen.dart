import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';

/// Pantalla CRUD para la administración de Categorías de Percusión.
class CategoriesCrudScreen extends StatefulWidget {
  const CategoriesCrudScreen({super.key});

  @override
  State<CategoriesCrudScreen> createState() => _CategoriesCrudScreenState();
}

class _CategoriesCrudScreenState extends State<CategoriesCrudScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategoryFormModal({CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    String selectedIcon = category?.iconName ?? 'drum';
    String selectedColor = category?.colorHex ?? '0xFFD4881A';

    final isEditing = category != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tirador superior
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organiza los instrumentos en agrupaciones temáticas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Nombre
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Categoría *',
                        hintText: 'Ej. Baterías Electrónicas',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Campo Descripción
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción detallada',
                        hintText: 'Breve reseña sobre los instrumentos de esta categoría',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Color
                    const Text('Color Distintivo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: [
                        '0xFFD4881A',
                        '0xFFE5A93C',
                        '0xFFA66A2C',
                        '0xFF10B981',
                        '0xFF3B82F6',
                        '0xFF8B5CF6',
                        '0xFFEF4444',
                      ].map((hexStr) {
                        final color = Color(int.parse(hexStr));
                        final isSelected = selectedColor == hexStr;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedColor = hexStr),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 20, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            UIHelpers.showSnackBar(
                              context,
                              message: 'El nombre es obligatorio',
                              isError: true,
                            );
                            return;
                          }

                          final provider = Provider.of<CategoryProvider>(context, listen: false);

                          if (isEditing) {
                            final updated = category.copyWith(
                              name: name,
                              description: descController.text.trim(),
                              iconName: selectedIcon,
                              colorHex: selectedColor,
                            );
                            final success = await provider.updateCategory(updated);
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              UIHelpers.showSnackBar(
                                context,
                                message: 'Categoría actualizada con éxito',
                                isSuccess: true,
                              );
                            }
                          } else {
                            final newCat = CategoryModel(
                              name: name,
                              description: descController.text.trim(),
                              iconName: selectedIcon,
                              colorHex: selectedColor,
                            );
                            final success = await provider.createCategory(newCat);
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              UIHelpers.showSnackBar(
                                context,
                                message: 'Categoría creada con éxito',
                                isSuccess: true,
                              );
                            }
                          }
                        },
                        child: Text(
                          isEditing ? 'Guardar Cambios' : 'Crear Categoría',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);

    final filteredList = catProvider.categories.where((c) {
      if (_filter.isEmpty) return true;
      return c.name.toLowerCase().contains(_filter) ||
          c.description.toLowerCase().contains(_filter);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('Nueva Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openCategoryFormModal(),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar categorías por nombre...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Listado de Categorías
          Expanded(
            child: catProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_outlined,
                              size: 64,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron categorías',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final category = filteredList[index];
                          Color catColor = AppColors.primaryGold;
                          try {
                            catColor = Color(int.parse(category.colorHex));
                          } catch (_) {}

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: catColor.withValues(alpha: 0.4)),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.album_rounded,
                                    color: catColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              title: Text(
                                category.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  category.description.isNotEmpty
                                      ? category.description
                                      : 'Sin descripción especificada',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    color: AppColors.secondaryGold,
                                    tooltip: 'Editar',
                                    onPressed: () => _openCategoryFormModal(category: category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                    color: AppColors.outOfStockRed,
                                    tooltip: 'Eliminar',
                                    onPressed: () async {
                                      final confirm = await UIHelpers.showConfirmationDialog(
                                        context,
                                        title: '¿Eliminar Categoría?',
                                        content:
                                            'Se eliminará "${category.name}". ¡Atención! También se eliminarán los productos asociados a ella.',
                                        confirmLabel: 'Sí, eliminar',
                                      );

                                      if (confirm && context.mounted) {
                                        final success = await catProvider.deleteCategory(category.id!);
                                        if (!context.mounted) return;
                                        if (success) {
                                          UIHelpers.showSnackBar(
                                            context,
                                            message: 'Categoría eliminada',
                                            isSuccess: true,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

