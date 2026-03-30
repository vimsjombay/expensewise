import 'package:flutter/material.dart';
import 'package:myapp/budget_screen.dart';
import 'package:myapp/category_management_screen.dart';
import 'package:myapp/currency_provider.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      body: ListView(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'General'),
                _buildSettingsCard(
                  context,
                  leadingIcon: Icons.account_balance_wallet,
                  title: 'Manage Budget',
                  subtitle: 'Set and edit your monthly budget',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BudgetScreen()),
                    );
                  },
                ),
                _buildSettingsCard(
                  context,
                  leadingIcon: Icons.category,
                  title: 'Manage Categories',
                  subtitle: 'Add, edit, or remove expense categories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const CategoryManagementScreen()),
                    );
                  },
                ),
                _buildSettingsCard(
                  context,
                  leadingIcon: Icons.monetization_on,
                  title: 'Currency',
                  subtitle: 'Select your default currency',
                  trailing: Text(currencyProvider.currency,
                      style: Theme.of(context).textTheme.titleLarge),
                  onTap: () {
                    _showCurrencySelectionDialog(context, currencyProvider);
                  },
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Appearance'),
                _buildSettingsCard(
                  context,
                  leadingIcon: Icons.color_lens,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark themes',
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(leadingIcon, size: 30),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _showCurrencySelectionDialog(
      BuildContext context, CurrencyProvider currencyProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildCurrencyOption(context, '₹', currencyProvider),
                _buildCurrencyOption(context, '\$', currencyProvider),
                _buildCurrencyOption(context, '€', currencyProvider),
                _buildCurrencyOption(context, '£', currencyProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOption(
      BuildContext context, String currency, CurrencyProvider currencyProvider) {
    return ListTile(
      title: Text(currency),
      onTap: () {
        currencyProvider.setCurrency(currency);
        Navigator.of(context).pop();
      },
      trailing: currencyProvider.currency == currency
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
    );
  }
}
