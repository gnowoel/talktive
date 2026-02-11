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
    extends $AsyncNotifierProvider<PrivateChatList, List<PrivateChat>> {
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

String _$privateChatListHash() => r'743dbfb028269faca3c3c591d408bad4df94a368';

/// Provider for listing all private chats for the current user.

abstract class _$PrivateChatList extends $AsyncNotifier<List<PrivateChat>> {
  FutureOr<List<PrivateChat>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PrivateChat>>, List<PrivateChat>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PrivateChat>>, List<PrivateChat>>,
              AsyncValue<List<PrivateChat>>,
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
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
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
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
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
    r'0fd9e6a6f5fa5adbc517b431180e0818933d4aad';

/// Provider for getting details about a specific private chat.

final class PrivateChatDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, int> {
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
