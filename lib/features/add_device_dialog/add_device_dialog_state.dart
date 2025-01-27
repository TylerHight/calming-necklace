import 'package:equatable/equatable.dart';

abstract class AddDeviceDialogState extends Equatable {
  const AddDeviceDialogState();

  @override
  List<Object> get props => [];
}

class AddDeviceDialogInitial extends AddDeviceDialogState {}

class AddDeviceDialogLoading extends AddDeviceDialogState {}

class AddDeviceDialogSuccess extends AddDeviceDialogState {}

class AddDeviceDialogError extends AddDeviceDialogState {
  final String message;

  const AddDeviceDialogError(this.message);

  @override
  List<Object> get props => [message];
}