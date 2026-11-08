import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/ui_helpers.dart';
import '../../models/product_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

/// Pantalla CRUD para la administración del inventario y productos de Percucol.
class ProductsCrudScreen extends StatefulWidget {
  const ProductsCrudScreen({super.key});

  @override
  State<ProductsCrudScreen> createState() => _ProductsCrudScreenState();
}

class _ProductsCrudScreenState extends State<ProductsCrudScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductFormModal({ProductModel? product}) {
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    if (catProvider.categories.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        message: 'Debes crear al menos una categoría antes de registrar productos.',
        isError: true,
      );
      return;
    }

    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '5');
    String selectedImagePath = product?.imageUrl ?? '';

    int selectedCatId = product?.categoryId ?? catProvider.categories.first.id!;

    Future<void> pickImageFromSource(ImageSource source, StateSetter setModalState) async {
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (pickedFile != null) {
          setModalState(() {
            selectedImagePath = pickedFile.path;
          });
        }
      } catch (e) {
        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            message: 'No se pudo seleccionar la imagen: $e',
            isError: true,
          );
        }
      }
    }

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
                      isEditing ? 'Editar Producto' : 'Nuevo Instrumento / Producto',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configura los datos del catálogo comercial.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Instrumento *',
                        hintText: 'Ej. Tambora Costeña 16"',
                        prefixIcon: Icon(Icons.music_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selector de Categoría
                    DropdownButtonFormField<int>(
                      initialValue: selectedCatId,
                      dropdownColor: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: catProvider.categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCatId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Fila Precio y Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio (COP) *',
                              hintText: '350000',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock Físico *',
                              hintText: '0 para agotado',
                              prefixIcon: Icon(Icons.inventory_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Descripción
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Especificaciones',
                        hintText: 'Maderas, aros, parches y sonoridad...',
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Imagen Local del Producto
                    const Text(
                      'Imagen del Instrumento *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    if (selectedImagePath.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: ProductImageView(
                                  imagePath: selectedImagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                                        label: const Text('Galería', style: TextStyle(fontSize: 12)),
                                        onPressed: () => pickImageFromSource(ImageSource.gallery, setModalState),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton.icon(
                                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                        label: const Text('Cámara', style: TextStyle(fontSize: 12)),
                                        onPressed: () => pickImageFromSource(ImageSource.camera, setModalState),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.outOfStockRed),
                                    tooltip: 'Quitar foto',
                                    onPressed: () => setModalState(() => selectedImagePath = ''),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 44,
                              color: AppColors.secondaryGold,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Añadir imagen desde tu dispositivo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Selecciona una foto local de la galería o toma una nueva foto con la cámara',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                                  label: const Text('Abrir Galería'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () => pickImageFromSource(ImageSource.gallery, setModalState),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                  label: const Text('Cámara'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () => pickImageFromSource(ImageSource.camera, setModalState),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

                          if (name.isEmpty || price <= 0) {
                            UIHelpers.showSnackBar(
                              context,
                              message: 'Ingresa un nombre y precio válidos',
                              isError: true,
                            );
                            return;
                          }

                          final prodProvider = Provider.of<ProductProvider>(context, listen: false);

                          if (isEditing) {
                            final updated = product.copyWith(
                              name: name,
                              description: descCtrl.text.trim(),
                              price: price,
                              stock: stock,
                              categoryId: selectedCatId,
                              imageUrl: selectedImagePath.trim(),
                            );
                            final success = await prodProvider.updateProduct(updated);
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              UIHelpers.showSnackBar(
                                context,
                                message: 'Producto actualizado con éxito',
                                isSuccess: true,
                              );
                            }
                          } else {
                            final newProduct = ProductModel(
                              name: name,
                              description: descCtrl.text.trim(),
                              price: price,
                              stock: stock,
                              categoryId: selectedCatId,
                              imageUrl: selectedImagePath.trim(),
                              rating: 4.9,
                            );
                            final success = await prodProvider.createProduct(newProduct);
                            if (!context.mounted) return;
                            if (success) {
                              Navigator.pop(ctx);
                              UIHelpers.showSnackBar(
                                context,
                                message: 'Producto creado en el inventario',
                                isSuccess: true,
                              );
                            }
                          }
                        },
                        child: Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Producto',
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
    final prodProvider = Provider.of<ProductProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    final filteredProducts = prodProvider.getFilteredProducts(
      categoryId: _selectedCategoryFilter,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Productos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Producto', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openProductFormModal(),
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => prodProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Buscar por instrumento o descripción...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          prodProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Chips de Filtro por Categoría
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedCategoryFilter == null,
                    onSelected: (_) => setState(() => _selectedCategoryFilter = null),
                  ),
                ),
                ...catProvider.categories.map((c) {
                  final isSelected = _selectedCategoryFilter == c.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(c.name),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategoryFilter = c.id),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de Productos
          Expanded(
            child: prodProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron productos',
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
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final categoryName = catProvider.getCategoryName(product.categoryId);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen o Ícono
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      color: isDark ? AppColors.darkCardElevated : AppColors.lightInput,
                                      child: ProductImageView(
                                        imagePath: product.imageUrl,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        iconSize: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Datos del Producto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondaryGold,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          UIHelpers.formatCurrency(product.price),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryGold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        StockBadge(stock: product.stock, compact: true),
                                      ],
                                    ),
                                  ),

                                  // Acciones (Editar y Eliminar)
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        color: AppColors.secondaryGold,
                                        tooltip: 'Editar',
                                        onPressed: () => _openProductFormModal(product: product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                        color: AppColors.outOfStockRed,
                                        tooltip: 'Eliminar',
                                        onPressed: () async {
                                          final confirm = await UIHelpers.showConfirmationDialog(
                                            context,
                                            title: '¿Eliminar Producto?',
                                            content: '¿Estás seguro de eliminar "${product.name}" del catálogo?',
                                            confirmLabel: 'Sí, eliminar',
                                          );

                                          if (confirm && context.mounted) {
                                            final success = await prodProvider.deleteProduct(product.id!);
                                            if (!context.mounted) return;
                                            if (success) {
                                              UIHelpers.showSnackBar(
                                                context,
                                                message: 'Producto eliminado',
                                                isSuccess: true,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
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

