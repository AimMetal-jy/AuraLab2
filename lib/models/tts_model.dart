// To parse this JSON data, do
//
//     final ttsModel = ttsModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'tts_model.g.dart';

TtsModel ttsModelFromJson(String str) => TtsModel.fromJson(json.decode(str));

String ttsModelToJson(TtsModel data) => json.encode(data.toJson());

@JsonSerializable()
class TtsModel {
    @JsonKey(name: "mode")
    String mode;
    @JsonKey(name: "vcn")
    String vcn;
    @JsonKey(name: "text")
    String text;

    TtsModel({
        required this.mode,
        required this.vcn,
        required this.text,
    });

    factory TtsModel.fromJson(Map<String, dynamic> json) => _$TtsModelFromJson(json);

    Map<String, dynamic> toJson() => _$TtsModelToJson(this);
}
