import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../service/api_service.dart';
import '../../widgets/dialog_helper.dart';
import '../../widgets/order_status_modal.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  List<dynamic> _customers = [];
  List<dynamic> _statuses = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (_apiService.hasPermission('view orders')) {
        try {
          final ordersRes = await _apiService.get('/orders');
          _orders = ordersRes['orders'] ?? [];
        } catch (e) {
          // Ignore individual fetch failure
        }
      }

      if (_apiService.hasPermission('view customer')) {
        try {
          final customersRes = await _apiService.get('/customers');
          _customers = customersRes['customers'] ?? [];
        } catch (e) {
          // Ignore individual fetch failure
        }
      }

      if (_apiService.hasPermission('view status')) {
        try {
          final statusesRes = await _apiService.get('/statuses');
          _statuses = statusesRes['statuses'] ?? [];
        } catch (e) {
          // Ignore individual fetch failure
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOrder(int id) async {
    try {
      await _apiService.delete('/orders/$id/delete');
      _fetchData();
      if (mounted) {
        DialogHelper.showSuccessDialog(context, 'Success', 'Order deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showErrorDialog(context, 'Error', 'Failed to delete order: $e');
      }
    }
  }

  Future<void> _updateOrderStatusFast(Map<String, dynamic> order, int newStatusId) async {
    // Show a quick non-blocking loading indicator
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating status...'), duration: Duration(seconds: 1)));
    
    try {
      List<dynamic> existingStatuses = order['statuses'] ?? [];
      List<int> statusIds = existingStatuses.map<int>((s) => s['id'] as int).toList();
      
      // Add the new status to the timeline if it's not already there
      if (!statusIds.contains(newStatusId)) {
        statusIds.add(newStatusId);
      }

      final body = {
        'name': order['name'],
        'address': order['address'] ?? '',
        'customer_id': order['customer']?['id'] ?? 0,
        'status_id': statusIds,
        'active_status_id': newStatusId,
      };

      await _apiService.post('/orders/${order['id']}/update', body: body);
      _fetchData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to update status: $e');
    }
  }

  void _showMiniCustomerModal(Function onSaved) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Customer', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), validator: (v) => v!.isEmpty ? 'Required' : null),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  final body = {'name': nameCtrl.text, 'email': emailCtrl.text, 'phone': phoneCtrl.text};
                  await _apiService.post('/customers/store', body: body);
                  await _fetchData();
                  onSaved();
                } catch(e) {
                  if (mounted) DialogHelper.showErrorDialog(context, 'Error', 'Failed to create customer: $e');
                }
              } else {
                DialogHelper.showErrorDialog(context, 'Validation Error', 'Please fill in all required fields properly.');
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showOrderModal({Map<String, dynamic>? existingOrder}) {
    int currentStep = 1;
    final isEditing = existingOrder != null;
    final formKey = GlobalKey<FormState>();
    final addressCtrl = TextEditingController(text: isEditing ? existingOrder['address'] : '');
    
    dynamic selectedCustomer;
    if (isEditing && existingOrder['customer'] != null && _customers.isNotEmpty) {
      try {
        selectedCustomer = _customers.firstWhere((c) => c['id'] == existingOrder['customer']['id']);
      } catch (e) {
        selectedCustomer = null;
      }
    }

    List<dynamic> timelineStatuses = [];
    int? activeStatusId;

    if (isEditing && existingOrder['statuses'] != null) {
      for (var st in existingOrder['statuses']) {
        timelineStatuses.add(st);
        if (st['pivot'] != null && st['pivot']['active'] == 1) {
          activeStatusId = st['id'];
        }
      }
    }

    if (timelineStatuses.isEmpty) {
      timelineStatuses.add(null);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setStateModal) {
            Widget content;
            if (currentStep == 1) {
              content = Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Step 1: Select Customer & Address',
                      style: GoogleFonts.nunito(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<dynamic>(
                            decoration: const InputDecoration(labelText: 'Customer'),
                            value: selectedCustomer,
                            items: _customers.map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c['name']} (ID: ${c['id']})'),
                            )).toList(),
                            onChanged: (val) {
                              setStateModal(() {
                                selectedCustomer = val;
                              });
                            },
                            validator: (v) => v == null ? 'Please select a customer' : null,
                          ),
                        ),
                        if (_apiService.hasPermission('create customer'))
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.adminPrimary, size: 28),
                            onPressed: () {
                              _showMiniCustomerModal(() {
                                setStateModal(() {
                                  // After creating customer, set the newly created customer as selected
                                  if (_customers.isNotEmpty) {
                                    selectedCustomer = _customers.last;
                                  }
                                });
                              });
                            },
                            tooltip: 'Create New Customer',
                          )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              );
            } else {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 2: Timeline for ${selectedCustomer['name']}',
                    style: GoogleFonts.nunito(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < timelineStatuses.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Delete Button
                              if (timelineStatuses.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setStateModal(() {
                                      if (timelineStatuses[i] != null && timelineStatuses[i]['id'] == activeStatusId) {
                                        activeStatusId = null;
                                      }
                                      timelineStatuses.removeAt(i);
                                    });
                                  },
                                  tooltip: 'Remove',
                                  padding: const EdgeInsets.only(right: 8.0),
                                  constraints: const BoxConstraints(),
                                ),
                              // Left: Dropdown
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<dynamic>(
                                  isExpanded: true,
                                  value: _statuses.any((s) => timelineStatuses[i] != null && s['id'] == timelineStatuses[i]['id'])
                                      ? _statuses.firstWhere((s) => timelineStatuses[i] != null && s['id'] == timelineStatuses[i]['id'])
                                      : null,
                                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s['name']))).toList(),
                                  onChanged: (val) {
                                    setStateModal(() {
                                      timelineStatuses[i] = val;
                                      if (activeStatusId == null) activeStatusId = val['id'];
                                    });
                                  },
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                                ),
                              ),
                              // Middle: Milestone
                              SizedBox(
                                width: 40,
                                child: Column(
                                  children: [
                                    if (i > 0) Container(width: 2, height: 15, color: AppTheme.adminPrimary),
                                    const Icon(Icons.circle, size: 16, color: AppTheme.adminPrimary),
                                    if (i < timelineStatuses.length - 1) Container(width: 2, height: 15, color: AppTheme.adminPrimary),
                                  ],
                                ),
                              ),
                              // Right: Checkbox
                              Expanded(
                                flex: 1,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Checkbox(
                                      value: timelineStatuses[i] != null && timelineStatuses[i]['id'] == activeStatusId,
                                      onChanged: timelineStatuses[i] == null
                                          ? null
                                          : (bool? val) {
                                              if (val == true) {
                                                setStateModal(() {
                                                  activeStatusId = timelineStatuses[i]['id'];
                                                });
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          setStateModal(() {
                            timelineStatuses.add(null);
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Status'),
                      ),
                    ],
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Order' : 'Create Order', style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(child: content),
              actions: [
                if (currentStep == 2)
                  TextButton(
                    onPressed: () {
                      setStateModal(() => currentStep = 1);
                    },
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (currentStep == 1)
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setStateModal(() => currentStep = 2);
                      } else {
                        DialogHelper.showErrorDialog(context, 'Validation Error', 'Please fill in all required fields properly.');
                      }
                    },
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      // Filter out nulls from timeline
                      final validStatuses = timelineStatuses.where((s) => s != null).toList();
                      if (validStatuses.isEmpty) {
                        DialogHelper.showErrorDialog(context, 'Validation Error', 'Please select at least one status');
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        final trackingNumber = isEditing ? existingOrder['name'] : 'TRK-${DateTime.now().millisecondsSinceEpoch}';
                        final statusIds = validStatuses.map((s) => s['id']).toList();
                        
                        final body = {
                          'name': trackingNumber,
                          'address': addressCtrl.text,
                          'customer_id': selectedCustomer['id'],
                          'status_id': statusIds,
                          'active_status_id': activeStatusId ?? statusIds.first,
                        };

                        if (isEditing) {
                          await _apiService.post('/orders/${existingOrder['id']}/update', body: body);
                        } else {
                          await _apiService.post('/orders/store', body: body);
                        }
                        _fetchData();
                        if (mounted) DialogHelper.showSuccessDialog(context, 'Success', isEditing ? 'Order and active status updated successfully' : 'Order created successfully');
                      } catch (e) {
                        if (mounted) {
                          DialogHelper.showErrorDialog(context, 'Error', 'Failed to save order: $e');
                        }
                      }
                    },
                    child: const Text('Done'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredOrders = _orders.where((order) {
      if (_selectedStatusFilter == 'All') return true;
      String activeStatusName = 'None';
      if (order['statuses'] != null) {
        for (var st in order['statuses']) {
          if (st['pivot'] != null && st['pivot']['active'] == 1) {
            activeStatusName = st['name'];
            break;
          }
        }
      }
      return activeStatusName == _selectedStatusFilter;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              Text(
                'Order Management',
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.adminText,
                ),
              ),
              if (_apiService.hasPermission('create orders'))
                ElevatedButton.icon(
                  onPressed: () => _showOrderModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Order'),
                ),
            ],
          ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedStatusFilter == 'All',
                    selectedColor: AppTheme.adminPrimary.withOpacity(0.2),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatusFilter = 'All');
                    },
                  ),
                ),
                ..._statuses.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(status['name']),
                        selected: _selectedStatusFilter == status['name'],
                        selectedColor: AppTheme.adminPrimary.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) setState(() => _selectedStatusFilter = status['name']);
                        },
                      ),
                    )).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final customerName = order['customer'] != null ? order['customer']['name'] : 'Unknown Customer';
                        
                        String activeStatusName = 'None';
                        int? activeStatusId;
                        if (order['statuses'] != null) {
                          for (var st in order['statuses']) {
                            if (st['pivot'] != null && st['pivot']['active'] == 1) {
                              activeStatusName = st['name'];
                              activeStatusId = st['id'];
                              break;
                            }
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.pastelBlue,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.adminPrimary.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.shopping_cart_outlined, color: AppTheme.adminText, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['name'],
                                            style: GoogleFonts.mPlusRounded1c(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.adminText,
                                            ),
                                          ),
                                          Text(
                                            customerName,
                                            style: GoogleFonts.nunito(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.adminPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: order['name']));
                                            DialogHelper.showSuccessDialog(context, 'Copied', 'Tracking number copied!');
                                          },
                                          child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Delivery Address', style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(order['address'] ?? 'No address provided', style: GoogleFonts.nunito(color: AppTheme.adminText, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    if (_apiService.hasPermission('edit orders')) ...[
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Active Status', style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.softGrey,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: activeStatusId,
                                                isDense: true,
                                                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.adminPrimary, size: 18),
                                                items: _statuses.map<DropdownMenuItem<int>>((s) {
                                                  return DropdownMenuItem<int>(
                                                    value: s['id'],
                                                    child: Text(s['name'], style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.adminText)),
                                                  );
                                                }).toList(),
                                                onChanged: (newId) {
                                                  if (newId != null && newId != activeStatusId) {
                                                    _updateOrderStatusFast(order, newId);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Active Status', style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGreen.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(activeStatusName, style: GoogleFonts.nunito(color: AppTheme.accentGreen, fontWeight: FontWeight.w800)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_apiService.hasPermission('view orders'))
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.adminText),
                                      onPressed: () {
                                        showGeneralDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          barrierLabel: 'Dismiss',
                                          transitionDuration: const Duration(milliseconds: 300),
                                          pageBuilder: (context, animation, secondaryAnimation) {
                                            return Align(
                                              alignment: Alignment.centerRight,
                                              child: Material(
                                                type: MaterialType.transparency,
                                                child: Container(
                                                  width: 400,
                                                  height: double.infinity,
                                                  margin: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.offWhite,
                                                    borderRadius: BorderRadius.circular(30),
                                                    boxShadow: [
                                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
                                                    ],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(30),
                                                    child: OrderStatusModal(orderData: order),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          transitionBuilder: (context, animation, secondaryAnimation, child) {
                                            return SlideTransition(
                                              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                              child: child,
                                            );
                                          },
                                        );
                                      },
                                      tooltip: 'View Details',
                                    ),
                                  if (_apiService.hasPermission('edit orders'))
                                    IconButton(
                                      icon: Icon(Icons.edit_rounded, color: AppTheme.adminPrimary, shadows: [Shadow(color: AppTheme.adminPrimary, blurRadius: 10, offset: const Offset(0, 6))]),
                                      onPressed: () => _showOrderModal(existingOrder: order),
                                      tooltip: 'Edit Order',
                                    ),
                                  if (_apiService.hasPermission('delete orders'))
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded, color: Colors.redAccent, shadows: [Shadow(color: Colors.redAccent, blurRadius: 10, offset: const Offset(0, 6))]),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete Order'),
                                            content: Text('Are you sure you want to delete ${order['name']}?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteOrder(order['id']);
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Delete Order',
                                    ),
                                ],
                              ),
                            ],
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
