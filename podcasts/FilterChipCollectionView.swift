import PocketCastsDataModel
import PocketCastsUtils
protocol FilterChipActionDelegate: AnyObject {
    func presentingViewController() -> UIViewController
    func starredChipSelected()
}

class FilterChipCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var filter: EpisodeFilter? {
        didSet {
            reloadData()
        }
    }

    weak var chipActionDelegate: FilterChipActionDelegate?
    var cellBackgroundIsPrimaryUI01 = false
    private static let chipCellIdentifier = "EpisodeFilterChipCell"

    private enum ChipType: Int { case podcast, episode, downloadStatus, mediaType, releaseDate, starred, duration }
    private static let chipData: [ChipType] = [.podcast, .episode, .releaseDate, .duration, .downloadStatus, .mediaType, .starred]
    override func awakeFromNib() {
        super.awakeFromNib()
        registerCollectionViewCell()
        delegate = self
        dataSource = self
    }

    func registerCollectionViewCell() {
        register(UINib(nibName: "EpisodeFilterChipCell", bundle: nil), forCellWithReuseIdentifier: FilterChipCollectionView.chipCellIdentifier)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterChipCollectionView.chipCellIdentifier, for: indexPath) as! EpisodeFilterChipCell
        let chip = FilterChipCollectionView.chipData[indexPath.row]
        cell.backgroundIsPrimaryUI01 = cellBackgroundIsPrimaryUI01
        cell.filterColor = filter?.playlistColor() ?? ThemeColor.filter01()
        cell.titleLabel.text = titleForChip(chip: chip)
        cell.isChipEnabled = isChipSelected(chip: chip)
        cell.invalidateIntrinsicContentSize()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        FilterChipCollectionView.chipData.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let chip = FilterChipCollectionView.chipData[indexPath.row]

        let width = titleForChip(chip: chip).size(withAttributes: nil)
        return CGSize(width: width.width + 50, height: 30)
    }

    var lastSelectedIndexPath: IndexPath?
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let filter = filter else { return }
        let chip = FilterChipCollectionView.chipData[indexPath.row]
        if !isChipSelected(chip: chip) {
            deselectItem(at: indexPath, animated: false)
        }
        lastSelectedIndexPath = indexPath
        switch chip {
        case .podcast:
            let filterSettingsVC = PodcastFilterOverlayController(nibName: "PodcastChooserViewController", bundle: nil)
            filterSettingsVC.analyticsSource = .filters
            filterSettingsVC.filterToEdit = filter
            let navVC = SJUIUtils.navController(for: filterSettingsVC)
            chipActionDelegate?.presentingViewController().present(navVC, animated: true, completion: nil)

        case .downloadStatus:
            let filterSettingsVC = DownloadFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = filter
            chipActionDelegate?.presentingViewController().present(SJUIUtils.navController(for: filterSettingsVC), animated: true, completion: nil)
        case .releaseDate:
            let filterSettingsVC = ReleaseDateFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = filter
            chipActionDelegate?.presentingViewController().present(SJUIUtils.navController(for: filterSettingsVC), animated: true, completion: nil)
        case .mediaType:
            let filterSettingsVC = MediaFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = filter
            chipActionDelegate?.presentingViewController().present(SJUIUtils.navController(for: filterSettingsVC), animated: true, completion: nil)
        case .starred:
            if FeatureFlag.playlistsRebranding.enabled {
                let filterSettingsVC = StarredFilterOverlayController()
                filterSettingsVC.filterToEdit = filter
                chipActionDelegate?.presentingViewController().navigationController?.pushViewController(filterSettingsVC, animated: true)
            } else {
                filter.filterStarred = !filter.filterStarred
                chipActionDelegate?.starredChipSelected()
                saveFilterAndNotify()
                reloadData()
            }
        case .duration:
            let durationController = FilterDurationViewController(filter: filter)
            chipActionDelegate?.presentingViewController().present(SJUIUtils.navController(for: durationController), animated: true, completion: nil)
        case .episode:
            let filterSettingsVC = EpisodeFilterOverlayController(nibName: "FilterSettingsOverlayController", bundle: nil)
            filterSettingsVC.filterToEdit = filter
            chipActionDelegate?.presentingViewController().present(SJUIUtils.navController(for: filterSettingsVC), animated: true, completion: nil)
        }
    }

    private func titleForChip(chip: ChipType) -> String {
        guard let filter = filter else { return "" }
        var returnedString = ""
        switch chip {
        case .podcast:
            returnedString = filter.filterAllPodcasts ? L10n.filterChipsAllPodcasts : L10n.podcastCount(filter.podcastUuids.components(separatedBy: ",").count, capitalized: true)
        case .episode:
            var selectedOptions = 0
            if filter.filterUnplayed {
                returnedString = L10n.statusUnplayed
                selectedOptions += 1
            }
            if filter.filterPartiallyPlayed {
                if returnedString.count > 0 {
                    returnedString.append(", ")
                }
                returnedString.append(L10n.inProgress)
                selectedOptions += 1
            }
            if filter.filterFinished {
                if returnedString.count > 0 {
                    returnedString.append(", ")
                }
                returnedString.append(L10n.statusPlayed)
                selectedOptions += 1
            }
            if selectedOptions == 0 || selectedOptions == 3 {
                returnedString = L10n.filterEpisodeStatus
            }
        case .mediaType:
            if filter.filterAudioVideoType == AudioVideoFilter.audioOnly.rawValue {
                returnedString = AudioVideoFilter.audioOnly.description
            } else if filter.filterAudioVideoType == AudioVideoFilter.videoOnly.rawValue {
                returnedString = AudioVideoFilter.videoOnly.description
            } else {
                returnedString = L10n.filterMediaType
            }
        case .duration:
            if filter.filterDuration {
                let shortTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(filter.shorterThan * 60))
                let longTime = TimeFormatter.shared.multipleUnitFormattedShortTime(time: TimeInterval(filter.longerThan * 60))
                returnedString = "\(longTime) - \(shortTime)"
            } else {
                returnedString = L10n.filterChipsDuration
            }
        case .downloadStatus:
            if filter.filterDownloaded, !filter.filterNotDownloaded {
                returnedString = L10n.statusDownloaded
            } else if !filter.filterDownloaded, filter.filterNotDownloaded {
                returnedString = L10n.statusNotDownloaded
            } else {
                returnedString = L10n.filterDownloadStatus
            }
        case .releaseDate:
            returnedString = filterLengthToTime(filterHours: filter.filterHours)
        case .starred:
            returnedString = L10n.statusStarred
        }
        return returnedString
    }

    private func isChipSelected(chip: ChipType) -> Bool {
        guard let filter = filter else { return false }
        var result = false
        switch chip {
        case .podcast:
            result = !filter.filterAllPodcasts
        case .episode:
            result = !(filter.filterUnplayed && filter.filterPartiallyPlayed && filter.filterFinished)
        case .downloadStatus:
            result = !(filter.filterDownloaded && filter.filterNotDownloaded)
        case .mediaType:
            result = filter.filterAudioVideoType != AudioVideoFilter.all.rawValue
        case .releaseDate:
            result = filter.filterHours > 0 ? true : false
        case .starred:
            result = filter.filterStarred
        case .duration:
            result = filter.filterDuration
        }
        return result
    }

    func filterLengthToTime(filterHours: Int32) -> String {
        if filterHours <= ReleaseDateFilterOption.anytime.rawValue {
            return L10n.filterReleaseDate
        } else if let filter = ReleaseDateFilterOption(rawValue: filterHours) {
            return filter.description
        } else {
            // fallback in case another client sets some unexpected amount of hours
            return L10n.hoursPluralFormat(filterHours)
        }
    }

    func saveFilterAndNotify() {
        guard let filter = filter else { return }
        filter.syncStatus = SyncStatus.notSynced.rawValue
        DataManager.sharedManager.save(playlist: filter)
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.playlistChanged, object: filter)

        if !filter.isNew {
            Analytics.track(.filterUpdated, properties: ["group": "starred", "source": "filters"])
        }
    }

    func scrollToLastSelected() {
        guard let lastSelectedIndexPath = lastSelectedIndexPath else { return }
        scrollToItem(at: lastSelectedIndexPath, at: .left, animated: false)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}
