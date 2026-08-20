import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddProfileView extends StatelessWidget {
  final BuildContext context;

  const AddProfileView({super.key, required this.context});

  Future<void> _handleAddProfileFormFile() async {
    globalState.container
        .read(profilesActionProvider.notifier)
        .addProfileFormFile();
  }

  Future<void> _handleAddProfileFormURL(String url) async {
    globalState.container
        .read(profilesActionProvider.notifier)
        .addProfileFormURL(url);
  }

  Future<void> _toScan() async {
    if (system.isDesktop) {
      globalState.container
          .read(profilesActionProvider.notifier)
          .addProfileFormQrCode();
      return;
    }
    final url = await BaseNavigator.push(context, const ScanPage());
    if (url != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddProfileFormURL(url);
      });
    }
  }

  Future<void> _toAdd() async {
    final appLocalizations = context.appLocalizations;
    final url = await globalState.showCommonDialog<String>(
      child: InputDialog(
        autovalidateMode: AutovalidateMode.onUnfocus,
        title: appLocalizations.importFromURL,
        labelText: appLocalizations.url,
        value: '',
        inputFormatters: TextInputLimits.limit(TextInputLimits.url),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return appLocalizations.emptyTip('').trim();
          }
          if (!value.isUrl) {
            return appLocalizations.urlTip('').trim();
          }
          return null;
        },
      ),
    );
    if (url != null) {
      _handleAddProfileFormURL(url);
    }
  }

  Future<void> _toWebDav() async {
    final result = await globalState.showCommonDialog<WebDavFormResult>(
      child: const WebDavFormDialog(),
    );
    if (result == null) return;
    globalState.container
        .read(profilesActionProvider.notifier)
        .addProfileFormWebDav(
          url: result.url,
          webDavUsername: result.webDavUsername,
          webDavPassword: result.webDavPassword,
          subscriptionPassword: result.subscriptionPassword,
          autoUpdateDuration: result.autoUpdateDuration,
        );
  }

  @override
  Widget build(context) {
    final appLocalizations = context.appLocalizations;
    return ListView(
      children: [
        ListItem(
          leading: const Icon(Icons.qr_code_sharp),
          title: Text(appLocalizations.qrcode),
          subtitle: Text(appLocalizations.qrcodeDesc),
          onTap: _toScan,
        ),
        ListItem(
          leading: const Icon(Icons.upload_file_sharp),
          title: Text(appLocalizations.file),
          subtitle: Text(appLocalizations.fileDesc),
          onTap: _handleAddProfileFormFile,
        ),
        ListItem(
          leading: const Icon(Icons.cloud_download_sharp),
          title: Text(appLocalizations.url),
          subtitle: Text(appLocalizations.urlDesc),
          onTap: _toAdd,
        ),
        ListItem(
          leading: const Icon(Icons.cloud_sharp),
          title: Text(appLocalizations.webDav),
          subtitle: Text(appLocalizations.webDavDesc),
          onTap: _toWebDav,
        ),
      ],
    );
  }
}

class URLFormDialog extends StatefulWidget {
  const URLFormDialog({super.key});

  @override
  State<URLFormDialog> createState() => _URLFormDialogState();
}

class _URLFormDialogState extends State<URLFormDialog> {
  final _urlController = TextEditingController();

  Future<void> _handleAddProfileFormURL() async {
    final url = _urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.importFromURL,
      actions: [
        TextButton(
          onPressed: _handleAddProfileFormURL,
          child: Text(appLocalizations.submit),
        ),
      ],
      child: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              keyboardType: TextInputType.url,
              minLines: 1,
              maxLines: 5,
              inputFormatters: TextInputLimits.limit(TextInputLimits.url),
              onSubmitted: (_) {
                _handleAddProfileFormURL();
              },
              onEditingComplete: _handleAddProfileFormURL,
              controller: _urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: appLocalizations.url,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebDavFormResult {
  final String url;
  final String webDavUsername;
  final String webDavPassword;
  final String subscriptionPassword;
  final Duration autoUpdateDuration;

  const WebDavFormResult({
    required this.url,
    required this.webDavUsername,
    required this.webDavPassword,
    required this.subscriptionPassword,
    required this.autoUpdateDuration,
  });
}

class WebDavFormDialog extends StatefulWidget {
  const WebDavFormDialog({super.key});

  @override
  State<WebDavFormDialog> createState() => _WebDavFormDialogState();
}

class _WebDavFormDialogState extends State<WebDavFormDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _subscriptionPasswordController;
  late final TextEditingController _intervalController;
  final _passwordObscure = ValueNotifier<bool>(true);
  final _subscriptionPasswordObscure = ValueNotifier<bool>(true);
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _subscriptionPasswordController = TextEditingController();
    _intervalController = TextEditingController(
      text: defaultUpdateDuration.inMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _subscriptionPasswordController.dispose();
    _intervalController.dispose();
    _passwordObscure.dispose();
    _subscriptionPasswordObscure.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      WebDavFormResult(
        url: _urlController.text.trim(),
        webDavUsername: _usernameController.text.trim(),
        webDavPassword: _passwordController.text,
        subscriptionPassword: _subscriptionPasswordController.text,
        autoUpdateDuration: Duration(
          minutes: int.parse(_intervalController.text),
        ),
      ),
    );
  }

  Widget _obscureField({
    required TextEditingController controller,
    required ValueNotifier<bool> obscure,
    required String label,
  }) {
    return ValueListenableBuilder(
      valueListenable: obscure,
      builder: (_, value, _) {
        return TextFormField(
          controller: controller,
          obscureText: value,
          inputFormatters: TextInputLimits.limit(TextInputLimits.password),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: label,
            suffixIcon: IconButton(
              icon: Icon(value ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                obscure.value = !value;
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.webDav,
      actions: [
        TextButton(
          onPressed: _submit,
          child: Text(appLocalizations.submit),
        ),
      ],
      child: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 16,
            children: [
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                minLines: 1,
                maxLines: 5,
                inputFormatters: TextInputLimits.limit(TextInputLimits.url),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: appLocalizations.webDavSubscriptionUrl,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations.emptyTip(
                      appLocalizations.webDavSubscriptionUrl,
                    );
                  }
                  if (!value.isUrl) {
                    return appLocalizations.urlTip('');
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                inputFormatters: TextInputLimits.limit(
                  TextInputLimits.userName,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: appLocalizations.webDavLogin,
                ),
              ),
              _obscureField(
                controller: _passwordController,
                obscure: _passwordObscure,
                label: appLocalizations.webDavPassword,
              ),
              _obscureField(
                controller: _subscriptionPasswordController,
                obscure: _subscriptionPasswordObscure,
                label: appLocalizations.subscriptionPassword,
              ),
              TextFormField(
                controller: _intervalController,
                inputFormatters: TextInputLimits.digitsOnly(
                  TextInputLimits.interval,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: appLocalizations.autoUpdateInterval,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return appLocalizations
                        .profileAutoUpdateIntervalNullValidationDesc;
                  }
                  if (int.tryParse(value) == null) {
                    return appLocalizations
                        .profileAutoUpdateIntervalInvalidValidationDesc;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
