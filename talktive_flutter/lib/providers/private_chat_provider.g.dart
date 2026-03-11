// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for listing all private chats for the current user.

@ProviderFor(PrivateChatList)
final privateChatListProvider = PrivateChatListProvider._();

/// Provider for listing all private chats for the current user.
final class PrivateChatListProvider
    extends
        $AsyncNotifierProvider<PrivateChatList, List<PrivateChatWithProfile>> {
  /// Provider for listing all private chats for the current user.
  PrivateChatListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privateChatListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privateChatListHash();

  @$internal
  @override
  PrivateChatList create() => PrivateChatList();
}

String _$privateChatListHash() => r'19d45edae653bde3ddf05a4be64698f4cd2e955e';

/// Provider for listing all private chats for the current user.

abstract class _$PrivateChatList
    extends $AsyncNotifier<List<PrivateChatWithProfile>> {
  FutureOr<List<PrivateChatWithProfile>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<PrivateChatWithProfile>>,
              List<PrivateChatWithProfile>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PrivateChatWithProfile>>,
                List<PrivateChatWithProfile>
              >,
              AsyncValue<List<PrivateChatWithProfile>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for getting details about a specific private chat.

@ProviderFor(privateChatDetails)
final privateChatDetailsProvider = PrivateChatDetailsFamily._();

/// Provider for getting details about a specific private chat.

final class PrivateChatDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrivateChatWithProfile>,
          PrivateChatWithProfile,
          FutureOr<PrivateChatWithProfile>
        >
    with
        $FutureModifier<PrivateChatWithProfile>,
        $FutureProvider<PrivateChatWithProfile> {
  /// Provider for getting details about a specific private chat.
  PrivateChatDetailsProvider._({
    required PrivateChatDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'privateChatDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$privateChatDetailsHash();

  @override
  String toString() {
    return r'privateChatDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PrivateChatWithProfile> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrivateChatWithProfile> create(Ref ref) {
    final argument = this.argument as int;
    return privateChatDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PrivateChatDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$privateChatDetailsHash() =>
    r'1c1408b79f6f63cebfa24fa58a022d6f9aa195fb';

/// Provider for getting details about a specific private chat.

final class PrivateChatDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PrivateChatWithProfile>, int> {
  PrivateChatDetailsFamily._()
    : super(
        retry: null,
        name: r'privateChatDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting details about a specific private chat.

  PrivateChatDetailsProvider call(int privateChatId) =>
      PrivateChatDetailsProvider._(argument: privateChatId, from: this);

  @override
  String toString() => r'privateChatDetailsProvider';
}
