#if DEBUG
import Foundation

/// Sample HTML for previewing the rich-text pipeline offline.
enum RichTextPreviewSamples {
    static let descriptionHTML = """
    <p>A weekly show about <strong>technology</strong>, <em>design</em>, and the
    occasional rabbit hole. Find every episode and more at
    <a href="https://pocketcasts.com">pocketcasts.com</a>.</p>

    <p>Each week we dig into topics like:</p>
    <ul>
        <li>Engineering deep-dives
            <ul>
                <li>Architecture &amp; trade-offs</li>
                <li>Testing strategies</li>
            </ul>
        </li>
        <li>Long-form interviews</li>
        <li>Listener questions</li>
    </ul>

    <p>A typical episode runs in three parts:</p>
    <ol>
        <li>Intro &amp; news</li>
        <li>The main topic</li>
        <li>Picks &amp; wrap-up</li>
    </ol>

    <h3>Why listen?</h3>
    <p>Because the details matter — and sometimes the <em>asterisks * and
    underscores _</em> in a title shouldn't turn into formatting.</p>
    """
}
#endif
