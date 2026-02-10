// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.

@ProviderFor(RealtimeChat)
final realtimeChatProvider = RealtimeChatFamily._();

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.
final class RealtimeChatProvider
    extends $AsyncNotifierProvider<RealtimeChat, List<Message>> {
  /// Provider for real-time chat with WebSocket streaming.
  /// Automatically subscribes to channel updates and maintains message list.
  RealtimeChatProvider._({
    required RealtimeChatFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'realtimeChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$realtimeChatHash();

  @override
  String toString() {
    return r'realtimeChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RealtimeChat create() => RealtimeChat();

  @override
  bool operator ==(Object other) {
    return other is RealtimeChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$realtimeChatHash() => r'a94a9bb38e9a892f29c95dd0239a59a88a72ed90';

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.

final class RealtimeChatFamily extends $Family
    with
        $ClassFamilyOverride<
          RealtimeChat,
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>,
          int
        > {
  RealtimeChatFamily._()
    : super(
        retry: null,
        name: r'realtimeChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for real-time chat with WebSocket streaming.
  /// Automatically subscribes to channel updates and maintains message list.

  RealtimeChatProvider call(int channelId) =>
      RealtimeChatProvider._(argument: channelId, from: this);

  @override
  String toString() => r'realtimeChatProvider';
}

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.

abstract class _$RealtimeChat extends $AsyncNotifier<List<Message>> {
  late final _$args = ref.$arg as int;
  int get channelId => _$args;

  FutureOr<List<Message>> build(int channelId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Message>>, List<Message>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Message>>, List<Message>>,
              AsyncValue<List<Message>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
