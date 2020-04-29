import 'dart:typed_data';

import 'package:libsignalprotocoldart/src/IdentityKey.dart';
import 'package:libsignalprotocoldart/src/InvalidKeyException.dart';
import 'package:libsignalprotocoldart/src/InvalidMessageException.dart';
import 'package:libsignalprotocoldart/src/LegacyMessageException.dart';
import 'package:libsignalprotocoldart/src/ecc/Curve.dart';
import 'package:libsignalprotocoldart/src/ecc/ECPublicKey.dart';
import 'package:libsignalprotocoldart/src/protocol/CiphertextMessage.dart';
import 'package:libsignalprotocoldart/src/protocol/SignalMessage.dart';
import 'package:libsignalprotocoldart/src/util/ByteUtil.dart';
import 'package:libsignalprotocoldart/src/state/WhisperTextProtocol.pb.dart'
    as SignalProtos;

import 'package:optional/optional.dart';

class PreKeySignalMessage extends CiphertextMessage {
  int _version;
  int registrationId;
  Optional<int> preKeyId;
  int signedPreKeyId;
  ECPublicKey baseKey;
  IdentityKey identityKey;
  SignalMessage message;
  Uint8List serialized;

  PreKeySignalMessage(Uint8List serialized)
  // throws InvalidMessageException, InvalidVersionException
  {
    try {
      this._version = ByteUtil.highBitsToInt(serialized[0]);

      var preKeyWhisperMessage =
          SignalProtos.PreKeySignalMessage.fromBuffer(serialized.sublist(1));

      if (!preKeyWhisperMessage.hasSignedPreKeyId() ||
          !preKeyWhisperMessage.hasBaseKey() ||
          !preKeyWhisperMessage.hasIdentityKey() ||
          !preKeyWhisperMessage.hasMessage()) {
        throw InvalidMessageException("Incomplete message.");
      }

      this.serialized = serialized;
      this.registrationId = preKeyWhisperMessage.registrationId;
      this.preKeyId = preKeyWhisperMessage.hasPreKeyId()
          ? Optional.of(preKeyWhisperMessage.preKeyId)
          : Optional.empty();
      this.signedPreKeyId = preKeyWhisperMessage.hasSignedPreKeyId()
          ? preKeyWhisperMessage.signedPreKeyId
          : -1;
      this.baseKey = Curve.decodePoint(preKeyWhisperMessage.baseKey, 0);
      this.identityKey = new IdentityKey(
          Curve.decodePoint(preKeyWhisperMessage.identityKey, 0));
      this.message = SignalMessage.fromSerialized(preKeyWhisperMessage.message);
    } on InvalidKeyException catch (e) {
      throw InvalidMessageException(e.detailMessage);
    } on LegacyMessageException catch (e) {
      throw InvalidMessageException(e.detailMessage);
    }
  }

  PreKeySignalMessage.from(
      int messageVersion,
      int registrationId,
      Optional<int> preKeyId,
      int signedPreKeyId,
      ECPublicKey baseKey,
      IdentityKey identityKey,
      SignalMessage message) {
    this._version = messageVersion;
    this.registrationId = registrationId;
    this.preKeyId = preKeyId;
    this.signedPreKeyId = signedPreKeyId;
    this.baseKey = baseKey;
    this.identityKey = identityKey;
    this.message = message;

    // SignalProtos.PreKeySignalMessage.Builder builder =
    //     SignalProtos.PreKeySignalMessage.newBuilder()
    //                                     .setSignedPreKeyId(signedPreKeyId)
    //                                     .setBaseKey(ByteString.copyFrom(baseKey.serialize()))
    //                                     .setIdentityKey(ByteString.copyFrom(identityKey.serialize()))
    //                                     .setMessage(ByteString.copyFrom(message.serialize()))
    //                                     .setRegistrationId(registrationId);

    // if (preKeyId.isPresent()) {
    //   builder.setPreKeyId(preKeyId.get());
    // }

    // byte[] versionBytes = {ByteUtil.intsToByteHighAndLow(this.version, CURRENT_VERSION)};
    // byte[] messageBytes = builder.build().toByteArray();

    // this.serialized = ByteUtil.combine(versionBytes, messageBytes);
  }

  int getMessageVersion() {
    return _version;
  }

  IdentityKey getIdentityKey() {
    return identityKey;
  }

  int getRegistrationId() {
    return registrationId;
  }

  Optional<int> getPreKeyId() {
    return preKeyId;
  }

  int getSignedPreKeyId() {
    return signedPreKeyId;
  }

  ECPublicKey getBaseKey() {
    return baseKey;
  }

  SignalMessage getWhisperMessage() {
    return message;
  }

  @override
  int getType() {
    return CiphertextMessage.PREKEY_TYPE;
  }

  @override
  Uint8List serialize() {
    return serialized;
  }
}