import PocketCastsUtils

public enum IndexHint {
    /// Returns `column` as `+column` in SQL, so SQLite doesn't use the column's index for this query.
    ///
    /// The database has no ANALYZE statistics, so SQLite treats every index as equally selective. When a
    /// query filters on a selective column (such as `uuid` or `podcastUuid`) and on a column where almost
    /// every row has the same value (such as `wasDeleted = 0`), SQLite can pick the second column's index
    /// and read most of the episode table. The unary `+` returns the value unchanged, so the query matches
    /// the same rows, but SQLite can't use an index for that term and picks the selective one.
    ///
    /// Only use it on INTEGER columns compared with numbers, or in GROUP BY and PARTITION BY: `+column`
    /// has no type affinity, so comparing it with a value of another type can match different rows.
    public static func skipIndex(_ column: String) -> String {
        FeatureFlag.episodeQueryIndexHints.enabled ? "+\(column)" : column
    }
}
