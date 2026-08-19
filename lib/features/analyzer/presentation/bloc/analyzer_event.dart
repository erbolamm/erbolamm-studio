import 'package:equatable/equatable.dart';

abstract class AnalyzerEvent extends Equatable {
  const AnalyzerEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeRepoEvent extends AnalyzerEvent {
  final String url;

  const AnalyzeRepoEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class ResetAnalyzerEvent extends AnalyzerEvent {}
