import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class CheckoutScreen extends StatefulWidget {
  final List<String> selectedProductIds;
  final double totalPrice;
  final List<Map<String, dynamic>> selectedProducts;

  const CheckoutScreen({
    required this.selectedProductIds,
    required this.totalPrice,
    required this.selectedProducts,
    Key? key,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedPayment = 'COD';
  bool _isLoading = true;
  bool _useDefaultAddress = true;
  String _selectedAddress = '';
  LatLng? _selectedLocation;
  List<Map<String, dynamic>> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedProducts();

    // Debug print untuk melihat data yang diterima
    print('Selected Product IDs: ${widget.selectedProductIds}');
    print('Selected Products: ${widget.selectedProducts}');
  }

  Future<void> _loadUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && mounted) {
          setState(() {
            _addressController.text = userData.data()?['address'] ?? '';
            _phoneController.text = userData.data()?['phone'] ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading user data: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadSelectedProducts() async {
    setState(() => _isLoading = true);
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _selectedItems.clear();

      for (String cartId in widget.selectedProductIds) {
        final cartDoc = await _firestore.collection('carts').doc(cartId).get();

        print('Cart Data: ${cartDoc.data()}'); // Debug print

        if (cartDoc.exists && cartDoc.data()?['userId'] == currentUser.uid) {
          final cartData = cartDoc.data()!;

          // Ambil detail produk
          final productDoc = await _firestore
              .collection('products')
              .doc(cartData['productId'])
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data()!;

            // Pastikan quantity diambil dari cart
            final int quantity = cartData['quantity'] ?? 1;

            _selectedItems.add({
              'cartId': cartId,
              'productId': cartData['productId'],
              'productName': productData['name'] ?? '',
              'productImage': productData['imageUrl'] ?? '',
              'productPrice': productData['price']?.toDouble() ?? 0.0,
              'quantity': quantity,
              'userId': currentUser.uid
            });

            print('Added item with quantity: $quantity'); // Debug print
          }
        }
      }

      print('Final _selectedItems: $_selectedItems'); // Debug print

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadSelectedProducts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat produk: $e')),
        );
      }
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Generate checkout ID dengan timestamp
      String checkoutId = 'CO${DateTime.now().millisecondsSinceEpoch}';

      // Siapkan detail items untuk checkout
      List<Map<String, dynamic>> checkoutItems = _selectedItems
          .map((item) => {
                'productId': item['productId'],
                'productName': item['productName'],
                'productImage': item['productImage'],
                'price': item['productPrice'],
                'quantity': item['quantity'],
                'subtotal': item['productPrice'] * item['quantity'],
              })
          .toList();

      // Hitung total items
      int totalItems =
          checkoutItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

      // Data untuk checkout
      Map<String, dynamic> checkoutData = {
        'checkoutId': checkoutId,
        'userId': user.uid,
        'userEmail': user.email,
        'items': checkoutItems,
        'totalItems': totalItems,
        'totalPrice': widget.totalPrice,
        'shippingAddress': {
          'fullAddress': _addressController.text,
          'isDefaultAddress': _useDefaultAddress,
          'coordinates': _selectedLocation != null
              ? {
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                }
              : null,
        },
        'contactPhone': _phoneController.text,
        'paymentMethod': _selectedPayment,
        'paymentStatus': 'pending',
        'orderStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Simpan ke collection checkouts
      await _firestore
          .collection('checkouts')
          .doc(checkoutId)
          .set(checkoutData);

      // Update stok produk (opsional, tergantung kebutuhan)
      for (var item in checkoutItems) {
        DocumentReference productRef =
            _firestore.collection('products').doc(item['productId']);

        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot productDoc = await transaction.get(productRef);
          if (productDoc.exists) {
            int currentStock =
                (productDoc.data() as Map<String, dynamic>)['stock'] ?? 0;
            int orderedQuantity = item['quantity'];
            if (currentStock >= orderedQuantity) {
              transaction.update(productRef, {
                'stock': currentStock - orderedQuantity,
              });
            }
          }
        });
      }

      // Hapus item dari keranjang
      for (String cartId in widget.selectedProductIds) {
        await _firestore.collection('carts').doc(cartId).delete();
      }

      // Tambahkan ke riwayat pesanan user
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(checkoutId)
          .set({
        'checkoutId': checkoutId,
        'totalPrice': widget.totalPrice,
        'totalItems': totalItems,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);

        // Tampilkan dialog sukses
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 30,
                ),
                SizedBox(width: 10),
                Text('Checkout Berhasil'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: $checkoutId'),
                const SizedBox(height: 8),
                const Text('Pesanan Anda sedang diproses.'),
                const SizedBox(height: 8),
                if (_selectedPayment == 'TRANSFER')
                  const Text(
                    'Silakan lakukan pembayaran sesuai dengan instruksi yang akan dikirim ke email Anda.',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context)
                      .pop(true); // Kembali ke halaman sebelumnya
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFFC9184A)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        if (!_useDefaultAddress) {
          _addressController.text =
              '${position.latitude}, ${position.longitude}';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _openMap() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);

      if (!_useDefaultAddress) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            result.latitude,
            result.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            String address = '';

            // Bangun alamat dengan memeriksa setiap komponen
            if (place.street != null && place.street!.isNotEmpty) {
              address += place.street!;
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              address += address.isNotEmpty
                  ? ', ${place.subLocality}'
                  : place.subLocality!;
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              address +=
                  address.isNotEmpty ? ', ${place.locality}' : place.locality!;
            }
            if (place.subAdministrativeArea != null &&
                place.subAdministrativeArea!.isNotEmpty) {
              address += address.isNotEmpty
                  ? ', ${place.subAdministrativeArea}'
                  : place.subAdministrativeArea!;
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              address += address.isNotEmpty
                  ? ', ${place.administrativeArea}'
                  : place.administrativeArea!;
            }
            if (place.postalCode != null && place.postalCode!.isNotEmpty) {
              address += address.isNotEmpty
                  ? ' ${place.postalCode}'
                  : place.postalCode!;
            }

            // Jika tidak ada alamat yang valid, gunakan koordinat
            if (address.isEmpty) {
              address = '${result.latitude}, ${result.longitude}';
            }

            setState(() {
              _addressController.text = address;
            });
          } else {
            // Fallback ke koordinat jika tidak ada placemark
            setState(() {
              _addressController.text =
                  '${result.latitude}, ${result.longitude}';
            });
          }
        } catch (e) {
          print('Error getting address: $e');
          // Fallback ke koordinat jika terjadi error
          setState(() {
            _addressController.text = '${result.latitude}, ${result.longitude}';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Gagal mendapatkan detail alamat. Menggunakan koordinat sebagai gantinya.'),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFC9184A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Color(0xFFC9184A),
            ))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header dengan Total dan Jumlah Item
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9184A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.selectedProducts.length} Produk',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Total: Rp ${_formatPrice(widget.totalPrice)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Daftar Produk yang Dicheckout
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produk yang Dibeli',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = _selectedItems[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: index != _selectedItems.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['productImage'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                            Icons.image_not_supported),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['productName'] ?? 'Produk',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp${_formatPrice(item['productPrice'] ?? 0)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFC9184A),
                                          ),
                                        ),
                                        Text(
                                          'Jumlah: ${item['quantity']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Alamat Section
                          _buildSectionTitle('Alamat Pengiriman'),
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(top: 8, bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<bool>(
                                          title: const Text(
                                            'Alamat Utama',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          value: true,
                                          groupValue: _useDefaultAddress,
                                          onChanged: (value) {
                                            setState(() {
                                              _useDefaultAddress = value!;
                                              if (value) _loadUserData();
                                            });
                                          },
                                          activeColor: const Color(0xFFC9184A),
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<bool>(
                                          title: const Text(
                                            'Alamat Lain',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          value: false,
                                          groupValue: _useDefaultAddress,
                                          onChanged: (value) {
                                            setState(() {
                                              _useDefaultAddress = value!;
                                              if (!value)
                                                _addressController.clear();
                                            });
                                          },
                                          activeColor: const Color(0xFFC9184A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!_useDefaultAddress) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionButton(
                                            icon: Icons.my_location,
                                            label: 'Lokasi Saat Ini',
                                            onPressed: _getCurrentLocation,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildActionButton(
                                            icon: Icons.map,
                                            label: 'Pilih di Maps',
                                            onPressed: _openMap,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration:
                                        _buildInputDecoration('Alamat Lengkap'),
                                    maxLines: 3,
                                    enabled: !_useDefaultAddress,
                                    validator: (value) => value?.isEmpty == true
                                        ? 'Alamat tidak boleh kosong'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Kontak Section
                          _buildSectionTitle('Informasi Kontak'),
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(top: 8, bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                controller: _phoneController,
                                decoration:
                                    _buildInputDecoration('Nomor Telepon'),
                                keyboardType: TextInputType.phone,
                                validator: (value) => value?.isEmpty == true
                                    ? 'Nomor telepon tidak boleh kosong'
                                    : null,
                              ),
                            ),
                          ),

                          // Pembayaran Section
                          _buildSectionTitle('Metode Pembayaran'),
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(top: 8, bottom: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: DropdownButtonFormField<String>(
                                value: _selectedPayment,
                                decoration: _buildInputDecoration(
                                    'Pilih metode pembayaran'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'COD',
                                    child: Text('Cash on Delivery (COD)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'TRANSFER',
                                    child: Text('Transfer Bank'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedPayment = value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA4133C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Proses Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  // Helper methods untuk styling yang konsisten
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC9184A),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC9184A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC9184A)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// Tambahkan class MapScreen
class MapScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapScreen({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  String _address = '';

  @override
  void initState() {
    super.initState();
    _selectedLocation =
        widget.initialLocation ?? const LatLng(-6.200000, 106.816666);
    if (_selectedLocation != null) {
      _getAddressFromLatLng(_selectedLocation!);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';

        // Bangun alamat dengan memeriksa setiap komponen
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isNotEmpty
              ? ', ${place.subLocality}'
              : place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ', ${place.locality}' : place.locality!;
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          address += address.isNotEmpty
              ? ', ${place.subAdministrativeArea}'
              : place.subAdministrativeArea!;
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address += address.isNotEmpty
              ? ', ${place.administrativeArea}'
              : place.administrativeArea!;
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ' ${place.postalCode}' : place.postalCode!;
        }

        // Jika tidak ada alamat yang valid, gunakan koordinat
        if (address.isEmpty) {
          address = '${location.latitude}, ${location.longitude}';
        }

        setState(() {
          _address = address;
        });
      } else {
        // Fallback ke koordinat jika tidak ada placemark
        setState(() {
          _address = '${location.latitude}, ${location.longitude}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      // Fallback ke koordinat jika terjadi error
      setState(() {
        _address = '${location.latitude}, ${location.longitude}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal mendapatkan detail alamat. Menggunakan koordinat sebagai gantinya.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xFFFF4D6D),
        elevation: 0,
        actions: [
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context, _selectedLocation),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Konfirmasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLocation!,
              initialZoom: 15.0,
              onTap: (_, point) async {
                setState(() => _selectedLocation = point);
                await _getAddressFromLatLng(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _selectedLocation != null
                    ? [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: _selectedLocation!,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4D6D),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 10,
                                color: const Color(0xFFFF4D6D),
                              ),
                            ],
                          ),
                        ),
                      ]
                    : [],
              ),
            ],
          ),
          // Info Panel di bagian bawah
          if (_address.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFFFF4D6D),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Lokasi Terpilih',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ketuk lokasi pada peta untuk mengubah titik lokasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Tombol My Location
          Positioned(
            right: 16,
            bottom: _address.isNotEmpty ? 200 : 16,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  Position position = await Geolocator.getCurrentPosition();
                  LatLng currentLocation = LatLng(
                    position.latitude,
                    position.longitude,
                  );
                  setState(() => _selectedLocation = currentLocation);
                  await _getAddressFromLatLng(currentLocation);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal mendapatkan lokasi saat ini'),
                      ),
                    );
                  }
                }
              },
              backgroundColor: const Color(0xFFFF4D6D),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
