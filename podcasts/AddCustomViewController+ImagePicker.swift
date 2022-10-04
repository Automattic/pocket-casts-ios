import UIKit

extension AddCustomViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func showPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .photoLibrary
            present(pickerController, animated: true, completion: nil)
        }
    }

    func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .camera
            present(pickerController, animated: true, completion: nil)
        }
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] {
            artwork = (image as! UIImage)
            artworkNeedsUpdating = true
            selectedColorIndex = 0
            colorPickerView.reloadData()
            colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .left)
            picker.dismiss(animated: true, completion: nil)
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] {
            artwork = (image as! UIImage)
            selectedColorIndex = 0
            artworkNeedsUpdating = true
            colorPickerView.reloadData()
            colorPickerView.selectItem(at: IndexPath(item: selectedColorIndex, section: 0), animated: false, scrollPosition: .left)
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
