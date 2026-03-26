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
    extends $AsyncNotifierProvider<RealtimeChat, RealtimeChatState> {
  /// Provider for real-time chat with WebSocket streaming.
  /// Automatically subscribes to channel updates and maintains message list.
  RealtimeChatProvider._({
    required RealtimeChatFamily super.from,
    required (int, {bool prewarmOnly}) super.argument,
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
        '$argument';
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

String _$realtimeChatHash() => r'81583ee21fc44b2fe8a7150c7905cd9cf6cc1fca';

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.

final class RealtimeChatFamily extends $Family
    with
        $ClassFamilyOverride<
          RealtimeChat,
          AsyncValue<RealtimeChatState>,
          RealtimeChatState,
          FutureOr<RealtimeChatState>,
          (int, {bool prewarmOnly})
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

  RealtimeChatProvider call(int channelId, {bool prewarmOnly = false}) =>
      RealtimeChatProvider._(
        argument: (channelId, prewarmOnly: prewarmOnly),
        from: this,
      );

  @override
  String toString() => r'realtimeChatProvider';
}

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.

abstract class _$RealtimeChat extends $AsyncNotifier<RealtimeChatState> {
  late final _$args = ref.$arg as (int, {bool prewarmOnly});
  int get channelId => _$args.$1;
  bool get prewarmOnly => _$args.prewarmOnly;

  FutureOr<RealtimeChatState> build(int channelId, {bool prewarmOnly = false});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<RealtimeChatState>, RealtimeChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RealtimeChatState>, RealtimeChatState>,
              AsyncValue<RealtimeChatState>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, prewarmOnly: _$args.prewarmOnly),
    );
  }
}
