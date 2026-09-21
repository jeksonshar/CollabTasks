import 'package:equatable/equatable.dart';

class RtcParticipantMediaState extends Equatable {
  final String participantId;
  final bool isLocal;
  final bool isAudioMuted;
  final bool isVideoEnabled;
  final bool isSpeaking;
  final double audioLevel;

  const RtcParticipantMediaState({
    required this.participantId,
    this.isLocal = false,
    this.isAudioMuted = false,
    this.isVideoEnabled = true,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
  });

  RtcParticipantMediaState copyWith({
    String? participantId,
    bool? isLocal,
    bool? isAudioMuted,
    bool? isVideoEnabled,
    bool? isSpeaking,
    double? audioLevel,
  }) {
    return RtcParticipantMediaState(
      participantId: participantId ?? this.participantId,
      isLocal: isLocal ?? this.isLocal,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'isLocal': isLocal,
      'isAudioMuted': isAudioMuted,
      'isVideoEnabled': isVideoEnabled,
      'isSpeaking': isSpeaking,
      'audioLevel': audioLevel,
    };
  }

  factory RtcParticipantMediaState.fromMap(Map<String, dynamic> map) {
    return RtcParticipantMediaState(
      participantId: map['participantId'] as String? ?? '',
      isLocal: map['isLocal'] as bool? ?? false,
      isAudioMuted: map['isAudioMuted'] as bool? ?? false,
      isVideoEnabled: map['isVideoEnabled'] as bool? ?? true,
      isSpeaking: map['isSpeaking'] as bool? ?? false,
      audioLevel: (map['audioLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    participantId,
    isLocal,
    isAudioMuted,
    isVideoEnabled,
    isSpeaking,
    audioLevel,
  ];
}
