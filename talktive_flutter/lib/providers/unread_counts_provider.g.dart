// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_counts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TotalUnreadCounts)
final totalUnreadCountsProvider = TotalUnreadCountsProvider._();

final class TotalUnreadCountsProvider
    extends $NotifierProvider<TotalUnreadCounts, UnreadCounts> {
  TotalUnreadCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalUnreadCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalUnreadCountsHash();

  @$internal
  @override
  TotalUnreadCounts create() => TotalUnreadCounts();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnreadCounts value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnreadCounts>(value),
    );
  }
}

String _$totalUnreadCountsHash() => r'7447a23309377bf52703b6a4b23315ef65306f32';

abstract class _$TotalUnreadCounts extends $Notifier<UnreadCounts> {
  UnreadCounts build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UnreadCounts, UnreadCounts>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UnreadCounts, UnreadCounts>,
              UnreadCounts,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
