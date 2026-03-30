import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/expense.dart';
import 'package:myapp/services/hive_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box<Expense> _expenseBox;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _expenseBox = HiveService().getExpenseBox();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Summary'),
              Tab(text: 'By Category'),
              Tab(text: 'Trends'),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _expenseBox.listenable(),
              builder: (context, Box<Expense> box, _) {
                final expenses = box.values.toList();
                // When data changes, reset the touched index to avoid highlighting the wrong slice.
                if (mounted) {
                  // FIX: Avoid calling setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _touchedIndex = -1;
                      });
                    }
                  });
                }
                return TabBarView(
                  children: [
                    _buildSummary(expenses),
                    _buildCategoryView(expenses),
                    _buildTrendsChart(expenses),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<Expense> expenses) {
    final monthlyExpenses = <String, double>{};
    for (var expense in expenses) {
      final month = DateFormat.yMMM().format(expense.date);
      monthlyExpenses.update(month, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final barGroups = monthlyExpenses.entries.map((entry) {
      final month = entry.key;
      final total = entry.value;
      final monthIndex = monthlyExpenses.keys.toList().indexOf(month);
      return BarChartGroupData(
        x: monthIndex,
        barRods: [
          BarChartRodData(
            toY: total,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final currentMonth = DateFormat.yMMM().format(DateTime.now());
    final currentMonthTotal = monthlyExpenses[currentMonth] ?? 0.0;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Expenses for $currentMonth',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                Text('₹${currentMonthTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyExpenses.keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(monthlyExpenses.keys.toList()[index],
                                style: Theme.of(context).textTheme.bodySmall),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final month =
                          monthlyExpenses.keys.toList()[group.x.toInt()];
                      return BarTooltipItem(
                        '$month\n',
                        Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '₹${rod.toY.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryView(List<Expense> expenses) {
    final categoryExpenses = <String, double>{};
    for (var expense in expenses) {
      categoryExpenses.update(
          expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final totalExpenses =
        categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    final categoryEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieChartSections = categoryEntries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 110.0 : 100.0;
      final percentage =
          totalExpenses == 0 ? 0 : (entry.value / totalExpenses) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                }),
                sections: pieChartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Expense Breakdown',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryEntries.length,
            itemBuilder: (context, index) {
              final entry = categoryEntries[index];
              final percentage =
                  totalExpenses == 0 ? 0 : (entry.value / totalExpenses);
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(entry.key),
                    child: Text('${(percentage * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('₹${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildTrendsChart(List<Expense> expenses) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final last30DaysExpenses = expenses
        .where((e) =>
            e.date.isAfter(thirtyDaysAgo) &&
            e.date.isBefore(now.add(const Duration(days: 1))))
        .toList();

    if (last30DaysExpenses.isEmpty) {
      return Center(
        child: Text(
          'No trend data for the last 30 days.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withAlpha(153),
              ),
        ),
      );
    }

    final dailyExpenses = <int, double>{};
    for (var expense in last30DaysExpenses) {
      final dayKey =
          DateTime(expense.date.year, expense.date.month, expense.date.day)
              .millisecondsSinceEpoch;
      dailyExpenses.update(dayKey, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }

    final spots = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      final dayKey =
          DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final amount = dailyExpenses[dayKey] ?? 0.0;
      return FlSpot(index.toDouble(), amount);
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withAlpha(77),
                  ),
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final intValue = value.toInt();
                      if (intValue % 5 == 0) {
                        final date =
                            now.subtract(Duration(days: 29 - intValue));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat.Md().format(date),
                              style: Theme.of(context).textTheme.bodySmall),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                    interval: 1,
                  ),
                ),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      final date = now.subtract(Duration(days: 29 - index));
                      return LineTooltipItem(
                        '${DateFormat.MMMd().format(date)}\n',
                        Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '₹${touchedSpot.y.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Simple color mapping for categories
    switch (category) {
      case 'Food':
        return Colors.red.shade400;
      case 'Transport':
        return Colors.blue.shade400;
      case 'Shopping':
        return Colors.green.shade400;
      case 'Bills':
        return Colors.orange.shade400;
      case 'Entertainment':
        return Colors.purple.shade400;
      case 'Other':
        return Colors.grey.shade400;
      default:
        return Colors.black;
    }
  }
}
