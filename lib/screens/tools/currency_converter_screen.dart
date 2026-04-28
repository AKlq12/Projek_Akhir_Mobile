import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/tools_provider.dart';

/// Currency converter screen — converts between 160+ currencies.
///
/// Design follows the HTML reference adapted to the light theme:
/// - Main conversion card (From / swap / To)
/// - Exchange rate info line
/// - Popular pairs chips  
/// - Recent activity list
/// - Pro Tip informational card
class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ToolsProvider>();
    _amountController.text = _formatInputNumber(provider.amount);

    // Initial conversion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.convert();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatInputNumber(double value) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(value);
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(value);
  }

  String _formatRate(double rate) {
    if (rate >= 100) {
      return NumberFormat('#,##0', 'en_US').format(rate);
    }
    return NumberFormat('#,##0.####', 'en_US').format(rate);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency Exchange',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Gym memberships worldwide',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ToolsProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                // ── Main Conversion Card ────────────────────────────────
                _buildConversionCard(context, provider),

                const SizedBox(height: 16),

                // ── Exchange Rate Meta ──────────────────────────────────
                _buildRateInfo(context, provider),

                const SizedBox(height: 24),

                // ── Popular Pairs ───────────────────────────────────────
                _buildPopularPairs(context, provider),

                const SizedBox(height: 24),

                // ── Recent Activity ─────────────────────────────────────
                _buildRecentActivity(context, provider),

                const SizedBox(height: 24),

                // ── Pro Tip ─────────────────────────────────────────────
                _buildProTip(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CONVERSION CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConversionCard(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final fromInfo = ToolsProvider.getCurrencyInfo(provider.fromCurrency);
    final toInfo = ToolsProvider.getCurrencyInfo(provider.toCurrency);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle accent glow
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── FROM Section ──────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'From',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        _buildCurrencySelector(
                          context,
                          fromInfo,
                          isFrom: true,
                          provider: provider,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: colorScheme.onSurface,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                        hintText: '0.00',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      onSubmitted: (_) => _onAmountChanged(provider),
                      onEditingComplete: () => _onAmountChanged(provider),
                    ),
                    Text(
                      fromInfo.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // ── Swap Divider ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Divider(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.2),
                          thickness: 1,
                        ),
                        GestureDetector(
                          onTap: () => provider.swapCurrencies(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surfaceContainerHigh,
                              border: Border.all(
                                color: colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow
                                      .withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: provider.isConverting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.swap_vert_rounded,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── TO Section ────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'To',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        _buildCurrencySelector(
                          context,
                          toInfo,
                          isFrom: false,
                          provider: provider,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Converted Amount (read-only)
                    Text(
                      provider.convertedAmount > 0
                          ? _formatCurrency(provider.convertedAmount)
                          : '0.00',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      toInfo.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.03, end: 0);
  }

  void _onAmountChanged(ToolsProvider provider) {
    final text = _amountController.text.replaceAll(',', '');
    final value = double.tryParse(text) ?? 0;
    provider.setAmount(value);
    provider.convert();
  }

  Widget _buildCurrencySelector(
    BuildContext context,
    CurrencyInfo info, {
    required bool isFrom,
    required ToolsProvider provider,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showCurrencyPicker(context, isFrom, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              info.code,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(
      BuildContext context, bool isFrom, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    isFrom ? 'Select From Currency' : 'Select To Currency',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ToolsProvider.supportedCurrencies.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final currency =
                          ToolsProvider.supportedCurrencies[index];
                      final isSelected = isFrom
                          ? currency.code == provider.fromCurrency
                          : currency.code == provider.toCurrency;

                      return ListTile(
                        leading: Text(
                          currency.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          currency.code,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          currency.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: colorScheme.primary)
                            : null,
                        onTap: () {
                          if (isFrom) {
                            provider.setFromCurrency(currency.code);
                          } else {
                            provider.setToCurrency(currency.code);
                          }
                          Navigator.of(context).pop();
                          provider.convert();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXCHANGE RATE INFO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRateInfo(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    provider.rate > 0
                        ? '1 ${provider.fromCurrency} = ${_formatRate(provider.rate)} ${provider.toCurrency}'
                        : 'Fetching rate...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (provider.rate > 0)
                    Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                provider.lastUpdated.isNotEmpty
                    ? 'Last updated: ${provider.lastUpdated}'
                    : 'Updating...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Refresh button
          GestureDetector(
            onTap: provider.isConverting ? null : () => provider.convert(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: provider.isConverting
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POPULAR PAIRS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPopularPairs(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'POPULAR PAIRS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: ToolsProvider.popularPairs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final pair = ToolsProvider.popularPairs[index];
              final isActive = provider.fromCurrency == pair[0] &&
                  provider.toCurrency == pair[1];

              return GestureDetector(
                onTap: () => provider.selectPair(pair[0], pair[1]),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? colorScheme.primaryContainer
                          : colorScheme.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '${pair[0]} → ${pair[1]}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentActivity(BuildContext context, ToolsProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT ACTIVITY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (provider.recentConversions.isNotEmpty)
                GestureDetector(
                  onTap: () => provider.clearRecentConversions(),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items
        if (provider.recentConversions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'No recent conversions yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...provider.recentConversions.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final opacity = (1.0 - (index * 0.15)).clamp(0.5, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          colorScheme.outlineVariant.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: index == 0
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${record.from} → ${record.to}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${_formatCurrency(record.fromAmount)} → ${_formatCurrency(record.toAmount)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Time
                      Text(
                        record.timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRO TIP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProTip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compare gym membership costs across countries to find the best value for your digital nomad lifestyle. Global fitness has never been cheaper.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 500.ms);
  }
}
