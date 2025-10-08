import 'package:equatable/equatable.dart';

abstract class SalonReportState extends Equatable {
  const SalonReportState();
  @override
  List<Object?> get props => [];
}

class SalonReportInitial extends SalonReportState {}

class SalonReportLoading extends SalonReportState {}

class SalonReportSuccess extends SalonReportState {
  final String message;
  const SalonReportSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SalonReportError extends SalonReportState {
  final String message;
  const SalonReportError(this.message);
  @override
  List<Object?> get props => [message];
}
