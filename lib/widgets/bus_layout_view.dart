import 'package:flutter/material.dart';
import '../models/seat_model.dart';
import '../utils/app_theme.dart';
import 'bus_seat_widget.dart';

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _item(p.seatAvailableBorder, '3+ buses', p),
              _item(p.seatLowStock, '1–2 buses', p),
              _item(p.seatSelected, 'Selected', p),
              _item(p.seatSoldOut, '0 buses', p),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Number on each seat = buses with that seat available',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _item(Color color, String label, AppPalette p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: p.textSecondary),
        ),
      ],
    );
  }
}

class BusLayoutView extends StatelessWidget {
  final String layout;
  final List<SeatModel> seats;
  final ValueChanged<SeatModel> onSeatTap;

  static const double _gap = 8;
  static const double _aisle = 20;
  static const double _rowLabelW = 24;

  const BusLayoutView({
    super.key,
    required this.layout,
    required this.seats,
    required this.onSeatTap,
  });

  SeatModel? _findSeat(String id) {
    try {
      return seats.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: p.busShell,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.keyboard_arrow_up, size: 18, color: p.textSecondary),
          const SizedBox(height: 2),
          Text(
            'Front of bus',
            style: TextStyle(
              fontSize: 11,
              color: p.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          switch (layout) {
            '2+1' => _buildTwoPlusOne(),
            '2+2' => _buildTwoPlusTwo(),
            'Sleeper' => _buildSleeper(context),
            'Semi-Sleeper' => _buildSemiSleeper(),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }

  Widget _seatWidget(SeatModel s, {double height = BusSeatWidget.seatHeight}) {
    return BusSeatWidget(
      seat: s,
      isSelected: s.isSelected,
      height: height,
      isSleeper: height > BusSeatWidget.seatHeight,
      onTap: () => onSeatTap(s),
    );
  }

  Widget _aisleGap({double height = BusSeatWidget.seatHeight}) {
    return SizedBox(width: _aisle, height: height);
  }

  Widget _rowLabel(int row) {
    return Builder(
      builder: (context) => SizedBox(
        width: _rowLabelW,
        child: Text(
          '$row',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _seatOrGap(String id, {double height = BusSeatWidget.seatHeight}) {
    final s = _findSeat(id);
    if (s == null) {
      return SizedBox(width: BusSeatWidget.seatWidth, height: height);
    }
    return _seatWidget(s, height: height);
  }

  Widget _buildTwoPlusOne() {
    return Column(
      children: List.generate(10, (i) {
        final row = i + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rowLabel(row),
              _seatOrGap('${row}A'),
              _aisleGap(),
              _seatOrGap('${row}B'),
              const SizedBox(width: _gap),
              _seatOrGap('${row}C'),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTwoPlusTwo() {
    return Column(
      children: List.generate(10, (i) {
        final row = i + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rowLabel(row),
              _seatOrGap('${row}A'),
              const SizedBox(width: _gap),
              _seatOrGap('${row}B'),
              _aisleGap(),
              _seatOrGap('${row}C'),
              const SizedBox(width: _gap),
              _seatOrGap('${row}D'),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSleeper(BuildContext context) {
    final p = context.palette;
    const h = BusSeatWidget.sleeperHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _deckLabel(context, 'Lower deck'),
        const SizedBox(height: 12),
        ...List.generate(7, (i) {
          final row = i + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rowLabel(row),
                _seatOrGap('L${row}A', height: h),
                const SizedBox(width: _gap),
                _seatOrGap('L${row}B', height: h),
                _aisleGap(height: h),
                _seatOrGap('L${row}C', height: h),
              ],
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: p.border),
        ),
        _deckLabel(context, 'Upper deck'),
        const SizedBox(height: 12),
        ...List.generate(7, (i) {
          final row = i + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rowLabel(row),
                _seatOrGap('U${row}A', height: h),
                const SizedBox(width: _gap),
                _seatOrGap('U${row}B', height: h),
                _aisleGap(height: h),
                _seatOrGap('U${row}C', height: h),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSemiSleeper() {
    const h = 48.0;
    return Column(
      children: List.generate(10, (i) {
        final row = i + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _rowLabel(row),
              _seatOrGap('${row}A', height: h),
              const SizedBox(width: _gap),
              _seatOrGap('${row}B', height: h),
              _aisleGap(height: h),
              _seatOrGap('${row}C', height: h),
              const SizedBox(width: _gap),
              _seatOrGap('${row}D', height: h),
            ],
          ),
        );
      }),
    );
  }

  Widget _deckLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.palette.textSecondary,
      ),
    );
  }
}
