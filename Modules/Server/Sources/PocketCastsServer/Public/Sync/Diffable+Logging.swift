import PocketCastsDataModel
import PocketCastsUtils

extension PodcastSettings: Diffable {}
extension AppSettings: Diffable {}

protocol Diffable {
}

fileprivate func equals(_ lhs: Any, _ rhs: Any) -> Bool {
  func open<A: Equatable>(_ lhs: A, _ rhs: Any) -> Bool {
    lhs == (rhs as? A)
  }

  guard let lhs = lhs as? any Equatable
  else { return false }

  return open(lhs, rhs)
}

struct Diff {
    let key: String
    let oldValue: Any
    let newValue: Any
}

extension Diffable {
    func printDiff(from: Self, withIdentifier identifier: String? = nil) {
        diffs(from: from).forEach { diff in
            if let identifier {
                FileLog.shared.addMessage("Synced Settings Overwrote on \(identifier): \(diff.key), Old: \(diff.oldValue), New: \(diff.newValue)")
            } else {
                FileLog.shared.addMessage("Synced Settings Overwrote: \(diff.key), Old: \(diff.oldValue), New: \(diff.newValue)")
            }
        }
    }

    func diffs(from: Self) -> [Diff] {
        let old = self.changedProperties()
        let new = from.changedProperties()

        let keys = Set(old.keys).union(new.keys)

        return keys.compactMap { key in
            guard let oldValue = old[key], let newValue = new[key],
                  !equals(oldValue, newValue) else {
                return nil
            }

            return Diff(key: key, oldValue: oldValue, newValue: newValue)
        }
    }

    func changedProperties() -> [String: Any] {
        var result: [String: Any] = [:]

        let mirror = Mirror(reflecting: self)

        guard let style = mirror.displayStyle, style == .struct || style == .class else {
            return [:]
        }

        for (labelMaybe, valueMaybe) in mirror.children {
            guard let label = labelMaybe else {
                continue
            }
            let value = valueMaybe

            result[label] = value
        }

        return result
    }
}
