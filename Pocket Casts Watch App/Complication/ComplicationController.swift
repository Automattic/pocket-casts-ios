
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    private static let tintColor = UIColor(red: 0.956, green: 0.262, blue: 0.211, alpha: 1.0)

    override init() {
        super.init()
    }

    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.backward])
    }

    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let template = complicationTemplate(for: complication)

        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }

    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = complicationTemplate(for: complication)
        handler(template)
    }

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [CLKComplicationDescriptor(identifier: "complication", displayName: "Pocket Casts", supportedFamilies: [.circularSmall,
                                                                                                                                  .extraLarge,
                                                                                                                                  .graphicBezel,
                                                                                                                                  .graphicCircular,
                                                                                                                                  .graphicCorner,
                                                                                                                                  .graphicRectangular,
                                                                                                                                  .modularLarge,
                                                                                                                                  .modularSmall,
                                                                                                                                  .utilitarianLarge,
                                                                                                                                  .utilitarianSmall,
                                                                                                                                  .utilitarianSmallFlat])]
        handler(descriptors)
    }

    private func complicationTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Modular")!, twoPieceImageBackground: UIImage(named: "comp-modular-bg"), twoPieceImageForeground: UIImage(named: "comp-modular-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            return CLKComplicationTemplateModularSmallSimpleImage(imageProvider: imageProvider)
        case .modularLarge:
            let headerImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!, twoPieceImageBackground: UIImage(named: "comp-circular-bg"), twoPieceImageForeground: UIImage(named: "comp-circular-fg"))
            headerImageProvider.tintColor = ComplicationController.tintColor

            let headerTextProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)
            let body1TextProvider = CLKSimpleTextProvider(text: L10n.watchTapToOpen)

            return CLKComplicationTemplateModularLargeStandardBody(headerImageProvider: headerImageProvider, headerTextProvider: headerTextProvider, body1TextProvider: body1TextProvider)
        case .utilitarianSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!, twoPieceImageBackground: UIImage(named: "comp-utility-bg"), twoPieceImageForeground: UIImage(named: "comp-utility-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            return CLKComplicationTemplateUtilitarianSmallSquare(imageProvider: imageProvider)
        case .utilitarianSmallFlat:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!, twoPieceImageBackground: UIImage(named: "comp-utility-bg"), twoPieceImageForeground: UIImage(named: "comp-utility-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            let textProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)

            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider, imageProvider: imageProvider)
        case .utilitarianLarge:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!, twoPieceImageBackground: UIImage(named: "comp-utility-bg"), twoPieceImageForeground: UIImage(named: "comp-utility-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            let textProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)

            return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider, imageProvider: imageProvider)
        case .circularSmall:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!, twoPieceImageBackground: UIImage(named: "comp-circular-bg"), twoPieceImageForeground: UIImage(named: "comp-circular-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            return CLKComplicationTemplateCircularSmallSimpleImage(imageProvider: imageProvider)
        case .extraLarge:
            let imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Extra Large")!, twoPieceImageBackground: UIImage(named: "comp-extralarge-bg"), twoPieceImageForeground: UIImage(named: "comp-extralarge-fg"))
            imageProvider.tintColor = ComplicationController.tintColor

            return CLKComplicationTemplateExtraLargeSimpleImage(imageProvider: imageProvider)
        case .graphicCorner:
            let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Corner")!)

            return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imageProvider)
        case .graphicBezel:
            let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Circular")!)
            let circularTemplate = CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)

            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circularTemplate)
        case .graphicCircular:
            let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Circular")!)

            return CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
        case .graphicRectangular:
            let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Large Rectangular")!)
            let textProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)

            return CLKComplicationTemplateGraphicRectangularLargeImage(textProvider: textProvider, imageProvider: imageProvider)

        case .graphicExtraLarge:
            let line1ImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Large Rectangular")!)
            let line2TextProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)

            return CLKComplicationTemplateGraphicExtraLargeCircularStackImage(line1ImageProvider: line1ImageProvider, line2TextProvider: line2TextProvider)

        default:
            let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(named: "Complication/Graphic Large Rectangular")!)
            let textProvider = CLKSimpleTextProvider(text: L10n.pocketCasts, shortText: L10n.pocketCastsShort)

            return CLKComplicationTemplateGraphicRectangularLargeImage(textProvider: textProvider, imageProvider: imageProvider)
        }
    }
}
