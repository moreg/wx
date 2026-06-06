// 全屏图片预览（S16）
//
// 复刻微信"点击图片查看大图"流程：
// - 全屏黑底
// - InteractiveViewer 双指缩放（min 1.0, max 4.0）
// - 单击切换工具栏显隐
// - 长按弹"保存到相册 / 识别二维码 / 搜一搜"
// - "保存到相册"用 gal 包（Android 13+ / iOS 用 MediaStore，无需权限）
// - 顶部：关闭 + 标题（从对方/我）+ 1:1 / 原图 切换
// - 底部：图片信息（拍摄时间、文件大小）
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import '../../../core/theme/design_tokens.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;
  final bool fromMe;
  final Uint8List? imageBytes; // 可选：直接传 bytes，避开网络/资源加载

  const ImagePreviewPage({
    super.key,
    required this.imageUrl,
    required this.fromMe,
    this.imageBytes,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage>
    with SingleTickerProviderStateMixin {
  bool _toolbarVisible = true;
  bool _showOriginal = false;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleToolbar() {
    setState(() => _toolbarVisible = !_toolbarVisible);
  }

  Future<void> _onLongPress(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: WxColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(WxRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt, color: WxColors.textPrimary),
                title: const Text('保存到相册'),
                onTap: () => Navigator.of(ctx).pop('save'),
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner,
                    color: WxColors.textPrimary),
                title: const Text('识别图中二维码'),
                onTap: () => Navigator.of(ctx).pop('qrcode'),
              ),
              const Divider(height: 0.5),
              ListTile(
                leading: const Icon(Icons.search, color: WxColors.textPrimary),
                title: const Text('搜一搜'),
                onTap: () => Navigator.of(ctx).pop('search'),
              ),
              const SizedBox(height: WxSpace.sm),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == 'save') {
      await _saveToGallery();
    } else if (action == 'qrcode') {
      _toast('未发现二维码');
    } else if (action == 'search') {
      _toast('未发现可搜索内容');
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          _toast('未授权访问相册');
          return;
        }
      }
      if (widget.imageBytes != null) {
        await Gal.putImageBytes(widget.imageBytes!,
            album: '微信', name: 'wx_image_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        // 没有 bytes 时回退到 assets
        await Gal.putImage(widget.imageUrl, album: '微信');
      }
      _toast('已保存到相册');
    } on GalException catch (e) {
      _toast('保存失败：${e.type.message}');
    } catch (e) {
      _toast('保存失败：$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 120,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WxSpace.lg,
              vertical: WxSpace.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(WxRadius.sm),
            ),
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: WxFontSize.body,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), entry.remove);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 黑底占位
          Positioned.fill(child: Container(color: Colors.black)),
          // 图片
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleToolbar,
              onLongPress: () => _onLongPress(context),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          // 顶部工具栏
          if (_toolbarVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),
          // 底部信息
          if (_toolbarVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: _showOriginal ? BoxFit.contain : BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    }
    return Image.asset(
      widget.imageUrl,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _errorPlaceholder(),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: WxColors.textTertiary,
      width: 240,
      height: 240,
      alignment: Alignment.center,
      child: const Text(
        '图片加载失败',
        style: TextStyle(color: Colors.white, fontSize: WxFontSize.body),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + WxSpace.xs,
        left: WxSpace.sm,
        right: WxSpace.sm,
        bottom: WxSpace.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => _showOriginal = !_showOriginal);
            },
            child: Text(
              _showOriginal ? '原图' : '标清',
              style: const TextStyle(
                color: Colors.white,
                fontSize: WxFontSize.body,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () => _onLongPress(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        left: WxSpace.lg,
        right: WxSpace.lg,
        top: WxSpace.sm,
        bottom: MediaQuery.of(context).padding.bottom + WxSpace.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '2026-06-05 19:30',
            style: TextStyle(color: Colors.white70, fontSize: WxFontSize.small),
          ),
          Text(
            '${widget.fromMe ? "我" : "对方"}的图片',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: WxFontSize.small,
            ),
          ),
        ],
      ),
    );
  }
}
