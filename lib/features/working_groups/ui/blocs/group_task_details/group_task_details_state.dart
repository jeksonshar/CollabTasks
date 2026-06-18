import 'package:equatable/equatable.dart';

enum GroupTaskDetailsStatus { idle, saving, success, error }

class GroupTaskDetailsState extends Equatable {
  const GroupTaskDetailsState({this.status = GroupTaskDetailsStatus.idle, this.errorMessage});

  final GroupTaskDetailsStatus status;
  final String? errorMessage;

  GroupTaskDetailsState copyWith({GroupTaskDetailsStatus? status, String? errorMessage}) {
    return GroupTaskDetailsState(status: status ?? this.status, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
