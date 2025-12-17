import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/productPost.dart';
import '../models/categoryPost.dart';
import '../services/product_api_service.dart';
import '../services/category_api_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ProductApiService _productService = ProductApiService();
  final CategoryApiService _categoryService = CategoryApiService();

  List<ProductPost> _allProducts = []; // Danh sách gốc
  List<ProductPost> _displayProducts = []; // Danh sách hiển thị sau khi lọc
  List<CategoryPost> _categories = [];

  int? _selectedCategoryId; // null = "Tất cả"
  bool _loading = true;
  bool _mutating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Tải song song Sản phẩm và Danh mục
  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _productService.fetchProducts(),
        _categoryService.fetchCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        _allProducts = results[0] as List<ProductPost>;
        _categories = results[1] as List<CategoryPost>;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedCategoryId == null) {
        _displayProducts = _allProducts;
      } else {
        _displayProducts = _allProducts
            .where((p) => p.categoryId == _selectedCategoryId)
            .toList();
      }
    });
  }

  // ================= CRUD CATEGORY =================

  Future<void> _openCreateCategory() async {
    final String? name = await _showCategoryDialog();
    if (name == null || name.isEmpty) return;

    await _runMutation(() async {
      final created = await _categoryService.createCategory(CategoryPost(id: 0, name: name));
      setState(() => _categories.add(created));
      _showSnack('Đã thêm danh mục: $name');
    });
  }

  Future<void> _confirmDeleteCategory(CategoryPost category) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text('Sản phẩm thuộc "${category.name}" sẽ bị hủy liên kết danh mục.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;

    await _runMutation(() async {
      await _categoryService.deleteCategory(category.id!);
      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
        if (_selectedCategoryId == category.id) _selectedCategoryId = null;
        _applyFilter();
      });
    });
  }

  // ================= CRUD PRODUCT =================

  Future<void> _openCreateProduct() async {
    final ProductPost? draft = await showModalBottomSheet<ProductPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(categories: _categories),
    );
    if (draft == null) return;

    await _runMutation(() async {
      final created = await _productService.createProduct(draft);
      _allProducts.insert(0, created);
      _applyFilter();
    });
  }

  Future<void> _openEditProduct(ProductPost product) async {
    final ProductPost? updated = await showModalBottomSheet<ProductPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(initial: product, categories: _categories),
    );
    if (updated == null) return;

    await _runMutation(() async {
      final saved = await _productService.updateProduct(product.id!, updated);
      final index = _allProducts.indexWhere((p) => p.id == saved.id);
      if (index != -1) _allProducts[index] = saved;
      _applyFilter();
    });
  }

  Future<void> _confirmDeleteProduct(ProductPost product) async {
    await _runMutation(() async {
      await _productService.deleteProduct(product.id!);
      _allProducts.removeWhere((p) => p.id == product.id);
      _applyFilter();
    });
  }

  // ================= UTILS =================

  Future<void> _runMutation(Future<void> Function() action) async {
    setState(() => _mutating = true);
    try {
      await action();
    } catch (e) {
      _showSnack('Lỗi: $e');
    } finally {
      if (!mounted) return;
      setState(() => _mutating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _showCategoryDialog() async {
    String? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm danh mục'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Tên danh mục'), autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Lưu')),
          ],
        );
      },
    ).then((value) => result = value);
    return result;
  }

  // ================= BUILD UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thủy Sinh Market'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _mutating ? null : _openCreateProduct),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length + 2,
        itemBuilder: (context, index) {
          if (index == _categories.length + 1) {
            return IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: _openCreateCategory);
          }
          final bool isAll = index == 0;
          final category = isAll ? null : _categories[index - 1];
          final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == category?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: isAll ? null : () => _confirmDeleteCategory(category!),
              child: ChoiceChip(
                label: Text(isAll ? 'Tất cả' : category!.name!),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedCategoryId = isAll ? null : category!.id;
                  _applyFilter();
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_displayProducts.isEmpty) return const Center(child: Text('Không có sản phẩm nào'));

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: _displayProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = _displayProducts[index];
          final cateName = _categories.firstWhere((c) => c.id == product.categoryId, 
              orElse: () => const CategoryPost(id: 0, name: 'Khác')).name;

          return Slidable(
            key: ValueKey(product.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(onPressed: (_) => _openEditProduct(product), backgroundColor: Colors.blue, icon: Icons.edit),
                SlidableAction(onPressed: (_) => _confirmDeleteProduct(product), backgroundColor: Colors.red, icon: Icons.delete),
              ],
            ),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: _buildLeadingImage(product.images),
                title: Text(product.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$cateName • ${product.price?.round()}₫', style: const TextStyle(color: Colors.blue)),
                onTap: () => _showProductDetail(product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingImage(List<String>? images) {
    if (images == null || images.isEmpty) return const Icon(Icons.image, size: 40);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(images[0], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
    );
  }

  void _showProductDetail(ProductPost p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (p.images != null && p.images!.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: p.images!.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.images![i], fit: BoxFit.cover)),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            Text('Giá: ${p.price?.round()}₫', style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(p.description ?? 'Không có mô tả'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ================= FORM SHEET =================

class _ProductFormSheet extends StatefulWidget {
  final ProductPost? initial;
  final List<CategoryPost> categories;
  const _ProductFormSheet({this.initial, required this.categories});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _priceCtrl, _descCtrl, _imgCtrl;
  int? _selectedCateId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name);
    _priceCtrl = TextEditingController(text: widget.initial?.price?.toString());
    _descCtrl = TextEditingController(text: widget.initial?.description);
    _imgCtrl = TextEditingController(text: widget.initial?.images?.join(', '));
    _selectedCateId = widget.initial?.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.initial == null ? 'Thêm mới' : 'Cập nhật', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
              TextFormField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Giá'), keyboardType: TextInputType.number),
              DropdownButtonFormField<int>(
                value: _selectedCateId,
                items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name!))).toList(),
                onChanged: (val) => setState(() => _selectedCateId = val),
                decoration: const InputDecoration(labelText: 'Danh mục'),
              ),
              TextFormField(controller: _imgCtrl, decoration: const InputDecoration(labelText: 'Links ảnh (cách nhau dấu phẩy)'), maxLines: 2),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _submit, child: const Text('Xác nhận')),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final images = _imgCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    Navigator.pop(context, ProductPost(
      id: widget.initial?.id,
      name: _nameCtrl.text,
      price: double.tryParse(_priceCtrl.text),
      description: _descCtrl.text,
      images: images,
      categoryId: _selectedCateId,
    ));
  }
}