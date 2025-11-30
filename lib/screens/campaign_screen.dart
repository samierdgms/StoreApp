import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';
import '../providers/market_provider.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  Future<List<Coupon>>? _coupons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCoupons();
  }

  void _loadCoupons() {
    final marketId = Provider.of<MarketProvider>(context, listen: false).marketId;
    if (marketId != null) {
      _coupons = CouponService.fetchAllCoupons(marketId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Fırsatlar & Kuponlar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _coupons == null
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : FutureBuilder<List<Coupon>>(
        future: _coupons,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          final coupons = snapshot.data!;

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_activity_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text('Aktif kampanya bulunamadı.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final isPercent = coupon.type == 'percent';

              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Sol Taraf: İndirim Değeri
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: coupon.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isPercent ? '%${coupon.value.toStringAsFixed(0)}' : '₺${coupon.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: coupon.isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            'İNDİRİM',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: coupon.isActive ? Colors.green.shade700 : Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dekoratif Çizgi
                    Container(
                      width: 1,
                      height: 80,
                      color: Colors.grey.shade200,
                    ),

                    // Sağ Taraf: Detaylar
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    coupon.code,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                                if (!coupon.isActive)
                                  const Text('Süresi Doldu', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              coupon.description,
                              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              'Min. Sepet Tutarı: ₺${coupon.minAmount.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
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