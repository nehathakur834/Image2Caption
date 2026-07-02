import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService() : _picker = ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1800);
  }
}
