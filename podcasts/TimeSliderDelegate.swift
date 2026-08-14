import UIKit

@MainActor
protocol TimeSliderDelegate: AnyObject {
    func sliderDidBeginSliding()
    func sliderDidEndSliding()
    func sliderDidProvisionallySlide(to time: TimeInterval)
    func sliderDidSlide(to time: TimeInterval)
}
