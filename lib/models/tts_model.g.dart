// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tts_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TtsModel _$TtsModelFromJson(Map<String, dynamic> json) => TtsModel(
  mode: json['mode'] as String,
  vcn: json['vcn'] as String,
  text: json['text'] as String,
);

Map<String, dynamic> _$TtsModelToJson(TtsModel instance) => <String, dynamic>{
  'mode': instance.mode,
  'vcn': instance.vcn,
  'text': instance.text,
};
