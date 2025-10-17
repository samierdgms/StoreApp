import 'package:flutter/material.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  late Future<List<Coupon>> _coupons;

  @override
  void initState() {
    super.initState();
    _coupons = CouponService.fetchAllCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampanyalar'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Coupon>>(
        future: _coupons,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final coupons = snapshot.data!;
          if (coupons.isEmpty) {
            return const Center(child: Text('Kampanya bulunamadı'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coupon.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          coupon.type == 'percent'
                              ? '%${coupon.value.toStringAsFixed(0)} İndirim'
                              : '${coupon.value.toStringAsFixed(2)} ₺ İndirim',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(coupon.description),
                    const SizedBox(height: 6),
                    Text(
                      coupon.isActive ? 'Aktif' : 'Süresi Bitmiş',
                      style: TextStyle(
                        color: coupon.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
