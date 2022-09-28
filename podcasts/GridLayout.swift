// MIT License
//
// Copyright (c) 2016 stable|kernel
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

protocol GridLayoutDelegate: AnyObject {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize
}

extension GridLayoutDelegate {
    func scaleForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> UInt {
        1
    }

    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: 0, height: 0)
    }
}

class GridLayout: UICollectionViewLayout, GridLayoutDelegate {
    func sizeForItem(inCollectionView collectionView: UICollectionView, withLayout layout: UICollectionViewLayout, atIndexPath indexPath: IndexPath) -> CGSize {
        CGSize(width: itemFixedDimension, height: itemFixedDimension)
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    // User-configurable
    var scrollDirection: UICollectionView.ScrollDirection = .vertical

    // Spacing between items
    var itemSpacing: CGFloat = 0

    // number of rows when horizontal scrolling, columns when vertical scrolling
    var numberOfRowsOrColumns: UInt {
        get {
            UInt(intNumberOfRowsOrColumns)
        }
        set {
            intNumberOfRowsOrColumns = newValue == 0 ? 1 : Int(newValue)
        }
    }

    var itemWidth: CGFloat = 0
    var itemHeight: CGFloat = 0

    weak var delegate: GridLayoutDelegate?

    private var intNumberOfRowsOrColumns = 1
    private var contentWidth: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var itemFixedDimension: CGFloat = 0

    /// This represents a 2 dimensional array for each section, indicating whether each block in the grid is occupied
    /// It is grown dynamically as needed to fit every item into a grid
    private var sectionedItemGrid: [[[Bool]]] = []

    /// The cache built up during the `prepare` function
    private var itemAttributesCache: [UICollectionViewLayoutAttributes] = []

    /// The header cache built up during the `prepare` function
    private var headerAttributesCache: [UICollectionViewLayoutAttributes] = []

    /// A convenient tuple for working with items
    private typealias ItemFrame = (section: Int, flexibleIndex: Int, fixedIndex: Int, scale: Int)

    // MARK: - UICollectionView Layout

    override func prepare() {
        // On rotation, UICollectionView sometimes calls prepare without calling invalidateLayout
        guard itemAttributesCache.isEmpty, headerAttributesCache.isEmpty, let collectionView = collectionView else { return }

        let fixedDimension: CGFloat
        if scrollDirection == .vertical {
            fixedDimension = collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right)
            contentWidth = fixedDimension
        } else {
            fixedDimension = collectionView.frame.height - (collectionView.contentInset.top + collectionView.contentInset.bottom)
            contentHeight = fixedDimension
        }

        itemFixedDimension = (fixedDimension - (CGFloat(numberOfRowsOrColumns) * itemSpacing) + itemSpacing) / CGFloat(numberOfRowsOrColumns)

        var additionalSectionSpacing: CGFloat = 0
        for section in 0 ..< collectionView.numberOfSections {
            let itemCount = collectionView.numberOfItems(inSection: section)

            // Calculate item attributes
            let sectionOffset = additionalSectionSpacing
            sectionedItemGrid.append([])

            var flexibleIndex = 0, fixedIndex = 0
            for item in 0 ..< itemCount {
                if fixedIndex >= intNumberOfRowsOrColumns {
                    // Reached end of row in .vertical or column in .horizontal
                    fixedIndex = 0
                    flexibleIndex += 1
                }

                let itemIndexPath = IndexPath(item: item, section: section)
                let itemScale = indexableScale(forItemAt: itemIndexPath)
                let intendedFrame = ItemFrame(section, flexibleIndex, fixedIndex, itemScale)

                // Find a place for the item in the grid
                let (itemFrame, didFitInOriginalFrame) = nextAvailableFrame(startingAt: intendedFrame)

                reserveItemGrid(frame: itemFrame)
                let itemAttributes = layoutAttributes(for: itemIndexPath, at: itemFrame, with: sectionOffset)

                itemAttributesCache.append(itemAttributes)

                // Update flexible dimension
                if scrollDirection == .vertical {
                    if itemAttributes.frame.maxY > contentHeight {
                        contentHeight = itemAttributes.frame.maxY
                    }
                    if itemAttributes.frame.maxY > additionalSectionSpacing {
                        additionalSectionSpacing = itemAttributes.frame.maxY
                    }
                } else {
                    // .horizontal
                    if itemAttributes.frame.maxX > contentWidth {
                        contentWidth = itemAttributes.frame.maxX
                    }
                    if itemAttributes.frame.maxX > additionalSectionSpacing {
                        additionalSectionSpacing = itemAttributes.frame.maxX
                    }
                }

                if didFitInOriginalFrame {
                    fixedIndex += 1 + itemFrame.scale
                }
            }
        }

        // add padding for
        if scrollDirection == .vertical {
            contentHeight += itemSpacing * 2
        } else {
            contentWidth += itemSpacing * 2
        }
        sectionedItemGrid = [] // Only used during prepare, free up some memory
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let headerAttributes = headerAttributesCache.filter {
            $0.frame.intersects(rect)
        }
        let itemAttributes = itemAttributesCache.filter {
            $0.frame.intersects(rect)
        }

        return headerAttributes + itemAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributesCache.first {
            $0.indexPath == indexPath
        }
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == UICollectionView.elementKindSectionHeader else { return nil }

        return headerAttributesCache.first {
            $0.indexPath == indexPath
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if scrollDirection == .vertical, let oldWidth = collectionView?.bounds.width {
            return oldWidth != newBounds.width
        } else if scrollDirection == .horizontal, let oldHeight = collectionView?.bounds.height {
            return oldHeight != newBounds.height
        }

        return false
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        itemAttributesCache = []
        headerAttributesCache = []
        contentWidth = 0
        contentHeight = 0
    }

    // MARK: - Private

    private func indexableScale(forItemAt indexPath: IndexPath) -> Int {
        var itemScale = (delegate ?? self).scaleForItem(inCollectionView: collectionView!, withLayout: self, atIndexPath: indexPath)
        if itemScale > numberOfRowsOrColumns {
            itemScale = numberOfRowsOrColumns
        }
        return Int(itemScale - 1) // Using with indices, want 0-based
    }

    private func nextAvailableFrame(startingAt originalFrame: ItemFrame) -> (frame: ItemFrame, fitInOriginalFrame: Bool) {
        var flexibleIndex = originalFrame.flexibleIndex, fixedIndex = originalFrame.fixedIndex
        var newFrame = ItemFrame(originalFrame.section, flexibleIndex, fixedIndex, originalFrame.scale)
        while !isSpaceAvailable(for: newFrame) {
            fixedIndex += 1

            // Reached end of fixedIndex, restart on next flexibleIndex
            if fixedIndex + originalFrame.scale >= intNumberOfRowsOrColumns {
                fixedIndex = 0
                flexibleIndex += 1
            }

            newFrame = ItemFrame(originalFrame.section, flexibleIndex, fixedIndex, originalFrame.scale)
        }

        // Fits iff we never had to walk the grid to find a position
        return (newFrame, flexibleIndex == originalFrame.flexibleIndex && fixedIndex == originalFrame.fixedIndex)
    }

    /// Checks the grid from the origin to the origin + scale for occupied blocks
    private func isSpaceAvailable(for frame: ItemFrame) -> Bool {
        for flexibleIndex in frame.flexibleIndex ... frame.flexibleIndex + frame.scale {
            // Ensure we won't go off the end of the array
            while sectionedItemGrid[frame.section].count <= flexibleIndex {
                sectionedItemGrid[frame.section].append(Array(repeating: false, count: intNumberOfRowsOrColumns))
            }

            for fixedIndex in frame.fixedIndex ... frame.fixedIndex + frame.scale {
                if fixedIndex >= intNumberOfRowsOrColumns || sectionedItemGrid[frame.section][flexibleIndex][fixedIndex] {
                    return false
                }
            }
        }

        return true
    }

    private func reserveItemGrid(frame: ItemFrame) {
        for flexibleIndex in frame.flexibleIndex ... frame.flexibleIndex + frame.scale {
            for fixedIndex in frame.fixedIndex ... frame.fixedIndex + frame.scale {
                sectionedItemGrid[frame.section][flexibleIndex][fixedIndex] = true
            }
        }
    }

    private func layoutAttributes(for indexPath: IndexPath, at itemFrame: ItemFrame, with sectionOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        let size = (delegate ?? self).sizeForItem(inCollectionView: collectionView!, withLayout: self, atIndexPath: indexPath)

        itemHeight = size.height == 0.0 ? itemFixedDimension : size.height
        itemWidth = size.width == 0.0 ? itemFixedDimension : size.width

        let fixedIndexOffset = CGFloat(itemFrame.fixedIndex) * (itemSpacing + itemHeight)
        let longitudinalOffset = CGFloat(itemFrame.flexibleIndex) * (itemSpacing + itemWidth) + sectionOffset
        let itemScaledTransverseDimension = itemHeight + (CGFloat(itemFrame.scale) * (itemSpacing + itemHeight))
        let itemScaledLongitudinalDimension = itemWidth + (CGFloat(itemFrame.scale) * (itemSpacing + itemWidth))

        if scrollDirection == .vertical {
            layoutAttributes.frame = CGRect(x: fixedIndexOffset, y: longitudinalOffset, width: itemScaledTransverseDimension, height: itemScaledLongitudinalDimension)
        } else {
            layoutAttributes.frame = CGRect(x: longitudinalOffset, y: fixedIndexOffset, width: itemScaledLongitudinalDimension, height: itemScaledTransverseDimension)
        }

        return layoutAttributes
    }
}
