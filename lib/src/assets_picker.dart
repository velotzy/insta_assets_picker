// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/widget/insta_asset_picker_delegate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const _kGridCount = 4;
const _kInitializeDelayDuration = Duration(milliseconds: 250);
const kDefaultInstaCropRatios = [1.0, 4 / 5];

class InstaAssetCropDelegate {
  const InstaAssetCropDelegate({
    this.preferredSize = 1080,
    this.cropRatios = kDefaultInstaCropRatios,
  });

  /// The param [preferredSize] is used to produce higher quality cropped image.
  /// Keep in mind that the higher this value is, the heavier the cropped image will be.
  ///
  /// This value while be used as such
  /// ```dart
  /// preferredSize = (preferredSize / scale).round()
  /// ```
  ///
  /// Defaults to `1080`, like instagram.
  final double preferredSize;

  /// The param [cropRatios] provided the list of crop ratios that can be set
  /// from the crop view.
  ///
  /// Defaults to `[1/1, 4/5]` like instagram.
  final List<double> cropRatios;
}

class InstaAssetPicker {
  InstaAssetPickerBuilder? builder;

  void dispose() {
    builder?.dispose();
  }

  /// Request the current [PermissionState] of required permissions.
  ///
  /// Throw an error if permissions are unauthorized.
  /// Since the exception is thrown from the MethodChannel it cannot be caught by a try/catch
  ///
  /// check `AssetPickerDelegate.permissionCheck()` from flutter_wechat_assets_picker package for more information.
  static Future<PermissionState> _permissionCheck() =>
      AssetPicker.permissionCheck();

  /// Open a [ScaffoldMessenger] describing the reason why the picker cannot be opened.
  static void _openErrorPermission(
    BuildContext context,
    AssetPickerTextDelegate textDelegate,
    Function(BuildContext, String)? customHandler,
  ) {
    final defaultDescription =
        '${textDelegate.unableToAccessAll}\n${textDelegate.goToSystemSettings}';

    if (customHandler != null) {
      customHandler(context, defaultDescription);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(defaultDescription)),
      );
    }
  }

  /// Build a [ThemeData] with the given [themeColor] for the picker.
  ///
  /// check `AssetPickerDelegate.themeData()` from flutter_wechat_assets_picker package for more information.
  static ThemeData themeData(Color? themeColor, {bool light = false}) =>
      AssetPicker.themeData(themeColor, light: light);

  /// When using `restorableAssetsPicker` function, the picker's state is preserved even after pop
  ///
  /// ⚠️ [InstaAssetPicker] and [provider] must be disposed manually
  ///
  /// Set [useRootNavigator] to determine
  /// whether the picker route should use the root [Navigator].
  ///
  /// By extending the [AssetPickerPageRoute], users can customize the route
  /// and use it with the [pageRouteBuilder].
  ///
  /// Set [onPermissionDenied] to manually handle the denied permission error.
  /// The default behavior is to open a [ScaffoldMessenger].
  ///
  /// Crop options
  /// - Set [cropDelegate] to customize the display and export of crops.
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [provider] of type [DefaultAssetPickerProvider] to specifies picker options.
  /// This argument is required.
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount], like instagram.
  ///
  /// - Set [pickerTheme] to specifies the theme to apply to the picker.
  /// It is by default initialized with the `primaryColor` of the context theme.
  ///
  /// - Set [textDelegate] to specifies the language to apply to the picker.
  /// Default is the locale language from the context.
  ///
  /// - Set [title] to specifies the text title in the picker [AppBar].
  ///
  /// - Set [closeOnComplete] to specifies if the picker should be closed
  /// after assets selection confirmation.
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [loadingIndicatorBuilder] to specifies the loader indicator
  /// to display in the picker.
  Future<List<AssetEntity>?> restorableAssetsPicker(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)?
        onPermissionDenied,

    /// Crop options
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    required DefaultAssetPickerProvider provider,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
        required Function(dynamic)
        onCameraComplete,
    Widget Function(BuildContext, bool)? loadingIndicatorBuilder,
    Widget? Function(BuildContext, AssetPathEntity?, int)? specialItemBuilder,
    SpecialItemPosition? specialItemPosition,
  }) async {
    assert(provider.requestType == RequestType.image,
        'Only images can be shown in the picker for now');

    final locale = Localizations.maybeLocaleOf(context);
    final text = textDelegate ?? assetPickerTextDelegateFromLocale(locale);

    PermissionState? ps;
    if (builder == null) {
      try {
        ps = await _permissionCheck();
      } catch (e) {
        _openErrorPermission(context, text, onPermissionDenied);
      }
    }

    builder ??= InstaAssetPickerBuilder(
      initialPermission: ps ?? PermissionState.denied,
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme: pickerTheme ?? themeData(Theme.of(context).primaryColor),
      locale: locale,
      keepScrollOffset: true,
      textDelegate: text,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      closeOnComplete: closeOnComplete,
      onCameraComplete: onCameraComplete,
      cropDelegate: cropDelegate,
      onCompleted: onCompleted,
      specialItemBuilder: specialItemBuilder,
      specialItemPosition: specialItemPosition,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder!,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }

  /// Pick assets with the given arguments.
  ///
  /// Set [useRootNavigator] to determine
  /// whether the picker route should use the root [Navigator].
  ///
  /// By extending the [AssetPickerPageRoute], users can customize the route
  /// and use it with the [pageRouteBuilder].
  ///
  /// Set [onPermissionDenied] to manually handle the denied permission error.
  /// The default behavior is to open a [ScaffoldMessenger].
  ///
  /// Crop options
  /// - Set [cropDelegate] to customize the display and export of crops.
  ///
  /// Those arguments are used by [InstaAssetPickerBuilder]
  ///
  /// - Set [gridCount] to specifies the number of assets in the cross axis.
  /// Defaults to [_kGridCount], like instagram.
  ///
  /// - Set [pickerTheme] to specifies the theme to apply to the picker.
  /// It is by default initialized with the `primaryColor` of the context theme.
  ///
  /// - Set [textDelegate] to specifies the language to apply to the picker.
  /// Default is the locale language from the context.
  ///
  /// - Set [title] to specifies the text title in the picker [AppBar].
  ///
  /// - Set [closeOnComplete] to specifies if the picker should be closed
  /// after assets selection confirmation.
  ///
  /// - The [onCompleted] callback is called when the assets selection is confirmed.
  /// It will as argument a [Stream] with exportation details [InstaAssetsExportDetails].
  ///
  /// - Set [loadingIndicatorBuilder] to specifies the loader indicator
  /// to display in the picker.
  ///
  /// Those arguments are used by [DefaultAssetPickerProvider]
  ///
  /// - Set [selectedAssets] to specifies which assets to preselect when the
  /// picker is opened.
  ///
  /// - Set [maxAssets] to specifies the maximum of assets that can be selected
  /// Defaults to [defaultMaxAssetsCount].
  ///
  /// - Set [pageSize] to specifies the quantity of assets to display in a single page.
  /// Defaults to [defaultAssetsPerPage].
  ///
  /// - Set [pathThumbnailSize] to specifies the album thumbnail size in the albums list
  /// Defaults to [defaultPathThumbnailSize].
  ///
  /// - Set [sortPathDelegate] to specifies the order of the assets
  /// Defaults to [SortPathDelegate.common].
  ///
  /// - Set [sortPathsByModifiedDate] to specifies
  /// whether the modified_date can be used in the sort delegate.
  /// Defaults to `false`.
  ///
  /// - Set [filterOptions] to specifies the rules to include/exclude assets from the list
  ///
  /// - Set [initializeDelayDuration] to specifies the delay before loading the assets
  /// Defaults to [_kInitializeDelayDuration].
  static Future<List<AssetEntity>?> pickAssets(
    BuildContext context, {
    Key? key,
    bool useRootNavigator = true,
    AssetPickerPageRouteBuilder<List<AssetEntity>>? pageRouteBuilder,
    Function(BuildContext context, String delegateDescription)?
        onPermissionDenied,

    /// Crop options
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),

    /// InstaAssetPickerBuilder options
    int gridCount = _kGridCount,
    ThemeData? pickerTheme,
    AssetPickerTextDelegate? textDelegate,
    String? title,
    bool closeOnComplete = false,
    required Function(Stream<InstaAssetsExportDetails> exportDetails)
        onCompleted,
        required Function(dynamic)
        onCameraComplete,
    Widget Function(BuildContext, bool)? loadingIndicatorBuilder,

    /// DefaultAssetPickerProvider options
    List<AssetEntity>? selectedAssets,
    int maxAssets = defaultMaxAssetsCount,
    int pageSize = defaultAssetsPerPage,
    ThumbnailSize pathThumbnailSize = defaultPathThumbnailSize,
    SortPathDelegate<AssetPathEntity>? sortPathDelegate =
        SortPathDelegate.common,
    bool sortPathsByModifiedDate = false,
    FilterOptionGroup? filterOptions,
    Duration initializeDelayDuration = _kInitializeDelayDuration,
    Widget? Function(BuildContext, AssetPathEntity?, int)? specialItemBuilder,
    SpecialItemPosition? specialItemPosition,
  }) async {
    final locale = Localizations.maybeLocaleOf(context);
    final text = textDelegate ?? assetPickerTextDelegateFromLocale(locale);

    // must be called before initializing any picker provider to avoid `PlatformException(PERMISSION_REQUESTING)` type exception
    PermissionState? ps;
    try {
      ps = await _permissionCheck();
    } catch (e) {
      _openErrorPermission(context, text, onPermissionDenied);
      return [];
    }

    final DefaultAssetPickerProvider provider = DefaultAssetPickerProvider(
      selectedAssets: selectedAssets,
      maxAssets: maxAssets,
      pageSize: pageSize,
      pathThumbnailSize: pathThumbnailSize,
      requestType: RequestType.image,
      sortPathDelegate: sortPathDelegate,
      sortPathsByModifiedDate: sortPathsByModifiedDate,
      filterOptions: filterOptions,
      initializeDelayDuration: initializeDelayDuration,
    );

    final InstaAssetPickerBuilder builder = InstaAssetPickerBuilder(
      initialPermission: ps ?? PermissionState.denied,
      provider: provider,
      title: title,
      gridCount: gridCount,
      pickerTheme: pickerTheme ?? themeData(Theme.of(context).primaryColor),
      locale: locale,
      keepScrollOffset: false,
      textDelegate: text,
      loadingIndicatorBuilder: loadingIndicatorBuilder,
      closeOnComplete: closeOnComplete,
      cropDelegate: cropDelegate,
      onCompleted: onCompleted,
      onCameraComplete: onCameraComplete,
      specialItemBuilder: specialItemBuilder,
      specialItemPosition: specialItemPosition,
    );

    return AssetPicker.pickAssetsWithDelegate(
      context,
      delegate: builder,
      useRootNavigator: useRootNavigator,
      pageRouteBuilder: pageRouteBuilder,
    );
  }
}
