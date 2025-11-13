class ReturnProgress {
  final int id;
  final int returnId;
  final String? status;
  final String? note;
  final DateTime createdAt;

  ReturnProgress({
    required this.id,
    required this.returnId,
    required this.createdAt,
    this.status,
    this.note,
  });

  factory ReturnProgress.fromJson(Map<String, dynamic> j) {
    DateTime _d(v) => DateTime.tryParse('$v') ?? DateTime.now();
    return ReturnProgress(
      id: j['id'] as int,
      returnId: j['return_id'] as int,
      status: j['status'] as String?,
      note: j['note'] as String?,
      createdAt: _d(j['created_at']),
    );
  }
}
