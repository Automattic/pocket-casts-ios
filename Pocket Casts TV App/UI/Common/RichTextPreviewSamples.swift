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

    /// A long description for exercising scrolling, the soft edge fade, and bottom clipping
    /// in `ScrollableTextView` / `PodcastMoreInfoView`.
    static let longDescriptionHTML = """
    <p>A weekly show about <strong>technology</strong>, <em>design</em>, and the
    occasional rabbit hole. Find every episode and more at
    <a href="https://pocketcasts.com">pocketcasts.com</a>.</p>

    <p>We started this podcast in a tiny home studio with a single microphone and a
    stubborn belief that the <strong>craft</strong> behind everyday software is worth
    talking about at length. Years later we're still here, still asking the same
    questions, and still occasionally getting the answers completely wrong on the air.</p>

    <p>Each week we dig into topics like:</p>
    <ul>
        <li>Engineering deep-dives
            <ul>
                <li>Architecture &amp; trade-offs</li>
                <li>Testing strategies</li>
                <li>Performance and profiling</li>
                <li>Debugging war stories</li>
            </ul>
        </li>
        <li>Long-form interviews with builders, designers, and the occasional skeptic</li>
        <li>Listener questions, answered honestly</li>
        <li>Tooling, workflow, and the small habits that compound over a career</li>
    </ul>

    <p>A typical episode runs in three parts:</p>
    <ol>
        <li>Intro &amp; news from the week</li>
        <li>The main topic, explored in depth</li>
        <li>Picks &amp; wrap-up, where we recommend things we love</li>
    </ol>

    <h3>Why listen?</h3>
    <p>Because the details matter — and sometimes the <em>asterisks * and
    underscores _</em> in a title shouldn't turn into formatting. We care about the
    seams: the place where a clean abstraction meets a messy reality, where a design
    system bends under a real product requirement, where the spec and the shipping
    code quietly disagree.</p>

    <p>We're also unapologetic about going long. If a subject deserves ninety minutes,
    it gets ninety minutes. If a guest wants to follow a tangent to its natural end,
    we follow it. The goal was never to be efficient — it was to be <em>thorough</em>,
    and to leave you with something you can actually use on Monday morning.</p>

    <h3>Who is this for?</h3>
    <p>Engineers, designers, product folks, and anyone curious about how the things
    they use every day actually get made. You don't need a computer science degree to
    follow along — just a willingness to sit with a hard problem for a while.</p>

    <p>Thanks for listening. Tell a friend, leave a review, and send us your questions
    — the best episodes always start with one.</p>
    """
}
#endif
