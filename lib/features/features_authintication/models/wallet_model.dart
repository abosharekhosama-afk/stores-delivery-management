class WalletModel {
  final double pendingBalance; // أرصدة تحت المعالجة (الطلبات الجديدة)
  final double availableBalance; // الأرصدة القابلة للسحب فعلياً
  final double totalEarnings; // إجمالي ما ربحه التاجر منذ اشتراكه
  final double withdrawnAmount; // إجمالي المبالغ التي سحبها التاجر

  WalletModel({
    this.pendingBalance = 0.0,
    this.availableBalance = 0.0,
    this.totalEarnings = 0.0,
    this.withdrawnAmount = 0.0,
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      pendingBalance: (map['pendingBalance'] ?? 0.0).toDouble(),
      availableBalance: (map['availableBalance'] ?? 0.0).toDouble(),
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      withdrawnAmount: (map['withdrawnAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pendingBalance': pendingBalance,
      'availableBalance': availableBalance,
      'totalEarnings': totalEarnings,
      'withdrawnAmount': withdrawnAmount,
    };
  }
}
