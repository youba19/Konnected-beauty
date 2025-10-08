import 'package:equatable/equatable.dart';

abstract class SalonReportEvent extends Equatable {
  const SalonReportEvent();
  @override
  List<Object?> get props => [];
}

class SubmitSalonReport extends SalonReportEvent {
  final String message;
  const SubmitSalonReport(this.message);

  @override
  List<Object?> get props => [message];
}
