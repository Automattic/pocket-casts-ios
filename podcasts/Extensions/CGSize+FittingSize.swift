extension CGSize {
    func fitting(aspectRatio: CGSize) -> CGSize {
        let targetAspectRatio = aspectRatio.width / aspectRatio.height

        if self.width / self.height > targetAspectRatio {
            // Original is wider, constrain height
            let newHeight = self.height
            let newWidth = newHeight * targetAspectRatio
            return CGSize(width: newWidth, height: newHeight)
        } else {
            // Original is taller, constrain width
            let newWidth = self.width
            let newHeight = newWidth / targetAspectRatio
            return CGSize(width: newWidth, height: newHeight)
        }
    }
}
