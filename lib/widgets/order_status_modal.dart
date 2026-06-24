import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../theme/app_theme.dart';

class OrderStatusModal extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const OrderStatusModal({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    // Extract statuses and sort them by the 'order' column
    List<dynamic> statuses = orderData['statuses'] ?? [];
    statuses.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));

    // Find if there is an active status index
    int activeIndex = statuses.indexWhere((s) => s['pivot']?['active'] == 1 || s['pivot']?['active'] == true);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tracking: ${orderData['name'] ?? orderData['id']}',
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.keyBlack,
            ),
          ),
          if (orderData['customer'] != null && orderData['customer']['name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Customer: ${orderData['customer']['name']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (statuses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No tracking updates yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final displayName = status['display_name'] ?? status['name'] ?? 'Unknown';
                  
                  // Logic to determine if a milestone is past, current, or future
                  bool isPast = activeIndex == -1 ? true : index < activeIndex;
                  bool isCurrent = index == activeIndex;
                  bool isFuture = activeIndex != -1 && index > activeIndex;

                  Color nodeColor = isPast ? AppTheme.cyan : (isCurrent ? AppTheme.magenta : Colors.grey.shade300);
                  Color lineColor = isFuture ? Colors.grey.shade300 : AppTheme.cyan;

                  return TimelineTile(
                    alignment: TimelineAlign.manual,
                    lineXY: 0.2,
                    isFirst: index == 0,
                    isLast: index == statuses.length - 1,
                    indicatorStyle: IndicatorStyle(
                      width: isCurrent ? 25 : 20,
                      color: nodeColor,
                      iconStyle: isCurrent
                          ? IconStyle(iconData: Icons.check_circle, color: Colors.white, fontSize: 16)
                          : (isPast ? IconStyle(iconData: Icons.check, color: Colors.white, fontSize: 14) : null),
                    ),
                    beforeLineStyle: LineStyle(color: lineColor, thickness: 3),
                    afterLineStyle: LineStyle(color: index < activeIndex ? AppTheme.cyan : Colors.grey.shade300, thickness: 3),
                    endChild: Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.nunito(
                                fontSize: isCurrent ? 18 : 16,
                                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                color: isFuture ? Colors.grey.shade500 : AppTheme.keyBlack,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Current Status',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.magenta,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }
}
