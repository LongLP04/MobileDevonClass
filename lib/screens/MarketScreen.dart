import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/productPost.dart';
import '../services/product_api_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ProductApiService _service = ProductApiService();
  List<productPost> _products = [];
  bool _loading = true;
  bool _mutating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchProducts();
      if (!mounted) return;
      setState(() => _products = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreateSheet() async {
    final productPost? draft = await showModalBottomSheet<productPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ProductFormSheet(),
    );
    if (draft == null) return;
    await _runMutation(() async {
      final created = await _service.createProduct(draft);
      if (!mounted) return;
      _addProductToTop(created);
      _showSnack('Đã thêm "${created.name ?? 'sản phẩm mới'}"');
    });
  }

  Future<void> _openEditSheet(productPost product) async {
    if (product.id == null) {
      _showSnack('Không thể sửa sản phẩm thiếu ID');
      return;
    }
    final productPost? updated = await showModalBottomSheet<productPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductFormSheet(initial: product),
    );
    if (updated == null) return;
    await _runMutation(() async {
      final saved =
          await _service.updateProduct(product.id!, updated.copyWith(id: product.id));
      if (!mounted) return;
      _updateProductInList(saved);
      _showSnack('Đã cập nhật sản phẩm #${product.id}');
    });
  }

  Future<void> _confirmDelete(productPost product) async {
    if (product.id == null) {
      _showSnack('Không thể xoá sản phẩm thiếu ID');
      return;
    }
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá sản phẩm'),
        content: Text('Bạn có chắc muốn xoá "${product.name ?? 'Sản phẩm'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    await _runMutation(() async {
      await _service.deleteProduct(product.id!);
      if (!mounted) return;
      _removeProductFromList(product.id!);
      _showSnack('Đã xoá sản phẩm #${product.id}');
    });
  }

  Future<void> _openSearchSheet() async {
    final productPost? selected = await showModalBottomSheet<productPost>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SearchSheet(service: _service),
    );
    if (selected != null) {
      await _showProductDetail(selected);
    }
  }

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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addProductToTop(productPost product) {
    setState(() {
      _products = [
        product,
        ..._products.where((item) => item.id != product.id),
      ];
    });
  }

  void _updateProductInList(productPost product) {
    setState(() {
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
    });
  }

  void _removeProductFromList(int id) {
    setState(() {
      _products = _products.where((item) => item.id != id).toList();
    });
  }

  Future<void> _showProductDetail(productPost product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductDetailSheet(
        product: product,
        onEdit: () {
          Navigator.pop(context);
          _openEditSheet(product);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(product);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Screen'),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Icons.search),
            onPressed: _mutating ? null : _openSearchSheet,
          ),
          IconButton(
            tooltip: 'Thêm sản phẩm',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _mutating ? null : _openCreateSheet,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: _products.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: 320,
                  child: Center(
                    child: Text(_error ?? 'Chưa có sản phẩm nào'),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemBuilder: (context, index) {
                final product = _products[index];
                return Slidable(
                  key: ValueKey(product.id ?? index),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.4,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _openEditSheet(product),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Sửa',
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDelete(product),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Xoá',
                      ),
                    ],
                  ),
                  child: _ProductTile(
                    product: product,
                    onTap: () => _showProductDetail(product),
                    onLongPress: () => _openEditSheet(product),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _products.length,
            ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onLongPress,
  });

  final productPost product;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(product.price);
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Không có tên',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description ?? 'Không có mô tả',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (product.image == null || product.image!.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.image_not_supported, color: Colors.black54),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundImage: NetworkImage(product.image!),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '0₫';
    final intValue = price.round();
    final separator = RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))');
    return '${intValue.toString().replaceAllMapped(separator, (match) => '.')}₫';
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.initial});

  final productPost? initial;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _priceController = TextEditingController(
      text: widget.initial?.price?.toString() ?? '',
    );
    _imageController = TextEditingController(text: widget.initial?.image ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initial == null
                          ? 'Thêm sản phẩm'
                          : 'Chỉnh sửa sản phẩm',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (widget.initial?.id != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text('ID: ${widget.initial!.id}'),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên sản phẩm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá (VND)'),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed < 0) {
                      return 'Vui lòng nhập giá hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Ảnh (URL)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(widget.initial == null ? 'Thêm' : 'Cập nhật'),
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final product = productPost(
      id: widget.initial?.id,
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()),
      image: _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    Navigator.pop(context, product);
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.service});

  final ProductApiService service;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _nameController = TextEditingController();
  List<productPost> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm kiếm sản phẩm',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchByName(),
                decoration: const InputDecoration(
                  labelText: 'Nhập từ khoá tên sản phẩm',
                  helperText: 'Bạn có thể nhập một phần tên, ví dụ "hề"',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _searching ? null : _searchByName,
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Tìm sản phẩm'),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              if (_results.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kết quả (${_results.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._results.map(
                      (product) => Card(
                        child: ListTile(
                          leading: Text('#${product.id ?? '-'}'),
                          title: Text(product.name ?? 'Không có tên'),
                          subtitle: Text(_formatPrice(product.price)),
                          onTap: () => Navigator.pop(context, product),
                        ),
                      ),
                    ),
                  ],
                )
              else if (!_searching && _nameController.text.isNotEmpty)
                const Text('Không tìm thấy sản phẩm phù hợp'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchByName() async {
    final keyword = _nameController.text.trim();
    if (keyword.isEmpty) {
      setState(() => _error = 'Vui lòng nhập từ khoá');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await widget.service.searchProductsByName(keyword);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _error = 'Không tìm thấy sản phẩm phù hợp';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  String _formatPrice(double? price) {
    if (price == null) return '0₫';
    final intValue = price.round();
    final separator = RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))');
    return '${intValue.toString().replaceAllMapped(separator, (match) => '.')}₫';
  }
}

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final productPost product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(product.price);
    final description =
        (product.description == null || product.description!.isEmpty)
            ? 'Chưa có mô tả'
            : product.description!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name ?? 'Không có tên',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHeroImage(),
            const SizedBox(height: 16),
            if (product.id != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Mã sản phẩm: #${product.id}'),
              ),
            Text('Giá bán', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              priceText,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xoá sản phẩm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (product.image == null || product.image!.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.black45),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          product.image!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 48, color: Colors.black45),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '0₫';
    final intValue = price.round();
    final separator = RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))');
    return '${intValue.toString().replaceAllMapped(separator, (match) => '.')}₫';
  }
}
