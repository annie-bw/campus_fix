import 'dart:io';

import 'package:flutter/material.dart';
import '../../core/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/validators.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/common.dart';
import '../../widgets/location_field.dart';
import 'report_sent_screen.dart';

/// New report and Edit report share this screen. Pass [existing] to edit.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing, this.initialCategory});

  final Incident? existing;

  /// Preselected category when starting from a Home shortcut.
  final IncidentCategory? initialCategory;

  static Future<void> open(BuildContext context, {Incident? existing, IncidentCategory? category}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: existing == null,
          builder: (_) => ReportFormScreen(existing: existing, initialCategory: category),
        ),
      );

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  // Form fields are local, short-lived UI state, so they live in the
  // widget. Saving and upload progress live in IncidentProvider.
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late IncidentCategory? _category = widget.existing?.category ?? widget.initialCategory;
  late String? _location = widget.existing?.location;
  late final _locationDetail = TextEditingController(text: widget.existing?.locationDetail);
  File? _newPhoto;
  bool _removeExistingPhoto = false;
  int _errorCount = 0;

  bool get _isEdit => widget.existing != null;
  String? get _existingPhotoUrl => _removeExistingPhoto ? null : widget.existing?.photoUrl;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _locationDetail.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhosphorIconsRegular.camera, color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.images, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Resize + compress on device so uploads stay small on campus Wi-Fi.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (picked != null) setState(() => _newPhoto = File(picked.path));
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Couldn’t open the camera or gallery. Check app permissions.', error: true);
      }
    }
  }

  void _removePhoto() => setState(() {
    _newPhoto = null;
    if (_isEdit) _removeExistingPhoto = true;
  });

  int _countErrors() => [
    _category == null ? 'x' : null,
    Validators.reportTitle(_title.text),
    Validators.reportDescription(_desc.text),
    Validators.location(_location),
    Validators.locationDetail(_locationDetail.text),
  ].whereType<String>().length;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _errorCount = valid ? 0 : _countErrors());
    if (!valid) return;

    final draft = IncidentDraft(
      title: _title.text,
      description: _desc.text,
      category: _category!,
      location: _location!,
      locationDetail: _locationDetail.text,
    );
    final provider = context.read<IncidentProvider>();
    try {
      if (_isEdit) {
        await provider.edit(widget.existing!, draft, newPhoto: _newPhoto, removePhoto: _removeExistingPhoto);
        if (!mounted) return;
        Navigator.of(context).pop();
        showAppSnack(context, 'Changes saved');
      } else {
        final created = await provider.submit(draft, photo: _newPhoto);
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => ReportSentScreen(incident: created)));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError ? e.message : AuthService.describe(e);
      showAppSnack(context, msg, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select<IncidentProvider, bool>((p) => p.saving);
    final progress = context.select<IncidentProvider, double?>((p) => p.uploadProgress);

    return PopScope(
      canPop: !saving, // don't lose an upload by pressing back
      child: Scaffold(
        appBar: ScreenHeader(title: _isEdit ? 'Edit report' : 'New report'),
        // SafeArea keeps the Send button clear of Android's system nav bar.
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (_errorCount > 0) ...[
                  NoticeBanner(
                    icon: PhosphorIconsRegular.warningCircle,
                    tone: NoticeTone.amber,
                    text: _errorCount == 1
                        ? 'Please fix the highlighted field before sending.'
                        : 'Please fix the $_errorCount highlighted fields before sending.',
                  ),
                  const SizedBox(height: 20),
                ],
                AbsorbPointer(
                  absorbing: saving,
                  child: AnimatedOpacity(
                    opacity: saving ? 0.55 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CategoryPicker(
                          initialValue: _category,
                          onChanged: (c) => setState(() => _category = c),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Title',
                          controller: _title,
                          hint: 'e.g. Leaking tap in washroom',
                          required: true,
                          textInputAction: TextInputAction.next,
                          validator: Validators.reportTitle,
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Description',
                          controller: _desc,
                          hint: 'What happened, when, and who is affected?',
                          required: true,
                          multiline: true,
                          validator: Validators.reportDescription,
                        ),
                        const SizedBox(height: 20),
                        LocationField(
                          initialValue: _location,
                          required: true,
                          validator: Validators.location,
                          onChanged: (v) => setState(() => _location = v),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Specify exactly',
                          controller: _locationDetail,
                          hint: 'e.g. fab lab, washroom, near the stairs',
                          prefixIcon: PhosphorIconsRegular.navigationArrow,
                          required: true,
                          textInputAction: TextInputAction.done,
                          validator: Validators.locationDetail,
                        ),
                        const SizedBox(height: 20),
                        const FieldLabel('Photo', optional: true),
                        const SizedBox(height: 8),
                        _PhotoPicker(
                          file: _newPhoto,
                          existingUrl: _existingPhotoUrl,
                          progress: saving ? progress : null,
                          onPick: _pickPhoto,
                          onRemove: _removePhoto,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: _isEdit ? 'Save changes' : 'Send report',
                  loading: saving,
                  loadingLabel: _isEdit ? 'Saving…' : 'Sending…',
                  onPressed: _submit,
                ),
                if (saving) ...[
                  const SizedBox(height: 10),
                  Text(
                    progress != null && progress < 1
                        ? 'Uploading photo (${(progress * 100).round()}%). Please keep the app open.'
                        : 'Saving your report…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.file,
    required this.existingUrl,
    required this.progress,
    required this.onPick,
    required this.onRemove,
  });

  final File? file;
  final String? existingUrl;
  final double? progress;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null || existingUrl != null;
    if (!hasPhoto) {
      return Material(
        color: AppColors.surfaceSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPick,
          child: const SizedBox(
            height: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.camera, color: AppColors.primary),
                SizedBox(height: 6),
                Text(
                  'Take or choose a photo',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final image = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : Image.network(existingUrl!, fit: BoxFit.cover);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (progress != null)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(onPressed: onPick, style: _smallOutlined, child: const Text('Replace')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRemove, style: _smallOutlined, child: const Text('Remove')),
          ],
        ),
      ],
    );
  }

  static final _smallOutlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.ink,
    side: const BorderSide(color: AppColors.border),
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );
}
