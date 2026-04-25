import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<String?> showAddGroupDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('新增分组'),
        content: SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            placeholder: const Text('分组名称'),
            autofocus: true,
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确认'),
          ),
        ],
      );
    },
  );
}

class BookmarkFormData {
  final String name;
  final String url;
  final String? iconUrl;
  BookmarkFormData({required this.name, required this.url, this.iconUrl});
}

Future<BookmarkFormData?> showAddBookmarkDialog(
  BuildContext context, {
  String? initialName,
  String? initialUrl,
  String? initialIconUrl,
}) async {
  final nameCtrl = TextEditingController(text: initialName);
  final urlCtrl = TextEditingController(text: initialUrl);
  final iconCtrl = TextEditingController(text: initialIconUrl);

  return showDialog<BookmarkFormData>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initialName != null ? '编辑书签' : '新增书签'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                placeholder: const Text('书签名称'),
                autofocus: true,
              ),
              const Gap(12),
              TextField(
                controller: urlCtrl,
                placeholder: const Text('网址 (https://...)'),
              ),
              const Gap(12),
              TextField(
                controller: iconCtrl,
                placeholder: const Text('图标地址 (可选)'),
              ),
            ],
          ),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          PrimaryButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.of(context).pop(BookmarkFormData(
                name: nameCtrl.text.trim(),
                url: urlCtrl.text.trim(),
                iconUrl: iconCtrl.text.trim().isEmpty
                    ? null
                    : iconCtrl.text.trim(),
              ));
            },
            child: const Text('确认'),
          ),
        ],
      );
    },
  );
}

Future<bool?> showDeleteConfirmDialog(
    BuildContext context, String message) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          DestructiveButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      );
    },
  );
}
