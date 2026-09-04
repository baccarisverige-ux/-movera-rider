// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/presentation/common/Refer%20and%20Earn/refer_and_earn.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class EarningChartWidget extends StatelessWidget {
  const EarningChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - Replace with your actual data
    final List<ChartData> chartData = [
      ChartData('Sat', 50),
      ChartData('Sun', 80),
      ChartData('Mon', 350),
      ChartData('Tue', 200),
      ChartData('Wed', 300),
      ChartData('Thu', 20),
      ChartData('Fri', 100),
    ];

    // Find the maximum value to show label
    final maxData = chartData.reduce((a, b) => a.value > b.value ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: "Overall Earning",
              fontSize: 16,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),
            TextWidget(
              text: "Last Week",
              fontSize: 12,
              fontWeight: fwMedium,
              color: AppColor.subtitle,
            ),
          ],
        ),
        16.height,
        SizedBox(
          height: ResSize.h * 280,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              majorGridLines: MajorGridLines(width: 0),
              axisLine: AxisLine(width: 0),
              labelStyle: GoogleFonts.poppins(
                fontSize: ResSize.setSp(12),
                fontWeight: fwNormal,
                color: AppColor.subtitle,
              ),
              majorTickLines: MajorTickLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(
                width: 1,
                color: Color(0xFFE0E0E0),
                dashArray: [5, 5],
              ),
              axisLine: AxisLine(width: 0),
              labelStyle: GoogleFonts.poppins(
                fontSize: ResSize.setSp(10),
                fontWeight: fwNormal,
                color: AppColor.subtitle,
              ),
              majorTickLines: MajorTickLines(width: 0),
              minimum: 0,
              maximum: 400,
              interval: 50,
              labelFormat: '\${value}',
            ),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries<ChartData, String>(
                dataSource: chartData,
                xValueMapper: (ChartData data, _) => data.day,
                yValueMapper: (ChartData data, _) => data.value,
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(6),
                width: 0.5,
                spacing: 0.1,
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  labelAlignment: ChartDataLabelAlignment.top,
                  builder:
                      (
                        dynamic data,
                        dynamic point,
                        dynamic series,
                        int pointIndex,
                        int seriesIndex,
                      ) {
                        // Only show label for the maximum value (Monday)
                        if (data.value == maxData.value) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 8,
                              vertical: ResSize.h * 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: TextWidget(
                              text: '\$${data.value}',
                              fontSize: 10,
                              fontWeight: fwMedium,
                              color: AppColor.secondary,
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChartData {
  final String day;
  final double value;

  ChartData(this.day, this.value);
}

// Complete Earning Stats Screen with Chart
class EarningStatsScreen extends StatefulWidget {
  const EarningStatsScreen({super.key});

  @override
  State<EarningStatsScreen> createState() => _EarningStatsScreenState();
}

class _EarningStatsScreenState extends State<EarningStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppBar(
              actionsPadding: EdgeInsets.all(0),
              automaticallyImplyLeading: false,
              backgroundColor: AppColor.secondary,
              clipBehavior: Clip.none,
              foregroundColor: AppColor.secondary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColor.primary,
                  size: ResSize.h * 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: TextWidget(
                text: "Earning",
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
              centerTitle: true,
              actions: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      TopToBottomTransition(ReferAndEarn()),
                    );
                    // Navigate to Refer & Earn
                  },
                  child: Container(
                    height: ResSize.h * 36,
                    width: ResSize.w * 116,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColor.primary,
                    ),
                    child: Center(
                      child: TextWidget(
                        text: "Refer & Earn",
                        color: AppColor.secondary,
                        fontSize: 14,
                        fontWeight: fwMedium,
                      ),
                    ),
                  ),
                ),
                16.width,
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              19.height,
              // Today Earning Card
              Container(
                padding: EdgeInsets.all(ResSize.w * 16),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: Color(0xff000000).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Today Earning",
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                      color: AppColor.primary,
                    ),
                    12.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: ResSize.h * 40,
                              width: ResSize.w * 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xffF8F8F8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.luggage_outlined,
                                  color: AppColor.primary,
                                  size: ResSize.h * 20,
                                ),
                              ),
                            ),
                            8.width,
                            TextWidget(
                              text: "10 Trips",
                              fontSize: 16,
                              fontWeight: fwMedium,
                              color: AppColor.primary,
                            ),
                          ],
                        ),
                        TextWidget(
                          text: "\$100.00",
                          fontSize: 24,
                          fontWeight: fwSemiBold,
                          color: AppColor.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              24.height,
              // Overall Earning Chart Card
              Container(
                padding: EdgeInsets.all(ResSize.w * 16),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: Color(0xff000000).withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: EarningChartWidget(),
              ),
              24.height,
            ],
          ),
        ),
      ),
    );
  }
}
