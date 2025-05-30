import Foundation
@testable import PocketCastsDataModel

extension Podcast {
    static var fixture: String = """
{
    "episode_frequency": "Unknown",
    "estimated_next_episode_at": "2025-03-03T08:05:00Z",
    "has_seasons": true,
    "season_count": 2,
    "episode_count": 17,
    "has_more_episodes": false,
    "podcast": {
        "url": "https://www.audacy.com/podcast/the-severance-podcast-with-ben-stiller-adam-scott-947fe",
        "title": "The Severance Podcast with Ben Stiller & Adam Scott",
        "author": "Audacy, Red Hour, Great Scott",
        "description": "Hi, we're Ben Stiller and Adam Scott. We have severed ourselves from the world for 5 years, making the workplace thriller Severance. While we have no memory of what happened during that time, we thought we should make a companion podcast for all the Innies who will have no recollection of watching, in an attempt to reintegrate them with their memory of the show.\\nThis is the Severance Podcast with Ben Stiller and Adam Scott, an episode-by-episode, behind-the-scenes breakdown with the creators, cast, crew, and fans of the Emmy- and Peabody Award-winning TV show.\\nIn advance of Season 2 premiering January 17 on Apple TV+, director/executive producer Stiller and star/executive producer Scott will rewatch every episode of Season 1 and share in-depth, never-before-heard analysis, alongside guests including creator Dan Erickson, producer Jackie Cohn, stars Zach Cherry (\\"Dylan\\"), John Turturro (\\"Irving\\") and Britt Lower (\\"Helly\\"), and celebrity superfans Jon Stewart, Kristen Bell and Dax Shepard. The podcast will continue weekly following new episodes of Season 2. From Audacy Podcasts, Audacy's Pineapple Street Studios, Red Hour, and Great Scott. \\nIf you’ve got a question about Severance, call our hotline at 212-830-3816. We just might play your voicemail and answer your question on the podcast.",
        "description_html": "Hi, we&#39;re Ben Stiller and Adam Scott. We have severed ourselves from the world for 5 years, making the workplace thriller Severance. While we have no memory of what happened during that time, we thought we should make a companion podcast for all the Innies who will have no recollection of watching, in an attempt to reintegrate them with their memory of the show.<br />This is the Severance Podcast with Ben Stiller and Adam Scott, an episode-by-episode, behind-the-scenes breakdown with the creators, cast, crew, and fans of the Emmy- and Peabody Award-winning TV show.<br />In advance of Season 2 premiering January 17 on Apple TV&#43;, director/executive producer Stiller and star/executive producer Scott will rewatch every episode of Season 1 and share in-depth, never-before-heard analysis, alongside guests including creator Dan Erickson, producer Jackie Cohn, stars Zach Cherry (&#34;Dylan&#34;), John Turturro (&#34;Irving&#34;) and Britt Lower (&#34;Helly&#34;), and celebrity superfans Jon Stewart, Kristen Bell and Dax Shepard. The podcast will continue weekly following new episodes of Season 2. From Audacy Podcasts, Audacy&#39;s Pineapple Street Studios, Red Hour, and Great Scott. <br />If you’ve got a question about Severance, call our hotline at 212-830-3816. We just might play your voicemail and answer your question on the podcast.",
        "category": "TV & Film",
        "audio": true,
        "show_type": "episodic",
        "uuid": "b5363810-adfb-013d-1a6e-0acc26574db2",
        "fundings": [],
        "guid": "",
        "is_private": false,
        "transcript_eligible": null,
        "episodes": [
            {
                "uuid": "4e9067f3-e508-4726-bb8b-1016cc11af7e",
                "title": "S2E7: Chikhai Bardo (with Dichen Lachman and Jessica Lee Gagné)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD1709768888.mp3?updated=1740690420",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4734,
                "published": "2025-02-28T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 7
            },
            {
                "uuid": "aaa769c0-85ac-4b6a-9fd9-751e42fce95d",
                "title": "S2E6: Attila (with Christopher Walken and Sarah Bock)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD9484009549.mp3?updated=1740095575",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4446,
                "published": "2025-02-21T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 6
            },
            {
                "uuid": "c0004d57-7e54-40d5-9bc8-6a5ee883a1b5",
                "title": "S2E5: Trojan's Horse (with Michael Chernus)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD5023300849.mp3?updated=1739487271",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4259,
                "published": "2025-02-14T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 5
            },
            {
                "uuid": "87aab154-6788-4eb0-94f0-75da409362be",
                "title": "S2E4: Woe's Hollow (with Theodore Shapiro)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD1126904604.mp3?updated=1738870693",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3990,
                "published": "2025-02-07T08:00:00Z",
                "type": "full",
                "season": 2,
                "number": 4
            },
            {
                "uuid": "91679a15-b372-4e46-9476-333daee90673",
                "title": "S2E3: Who Is Alive? (with Gwendoline Christie)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD2299026244.mp3?updated=1738265757",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3818,
                "published": "2025-01-31T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 3
            },
            {
                "uuid": "89134f2e-620a-4926-aad5-1daa2bbe2dfb",
                "title": "S2E2: Goodbye Mrs. Selvig (with Dan Erickson)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD7833381293.mp3?updated=1737668556",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3831,
                "published": "2025-01-24T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 2
            },
            {
                "uuid": "6104f022-f97b-4d22-87c7-4f7ff047fe08",
                "title": "S2E1: Hello, Ms. Cobel (with Tramell Tillman)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD2016472174.mp3?updated=1737076825",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4472,
                "published": "2025-01-17T08:05:00Z",
                "type": "full",
                "season": 2,
                "number": 1
            },
            {
                "uuid": "9f8f263a-86bd-4022-bb2e-e7ee05357870",
                "title": "S1E9: The We We Are (with Jon Stewart)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD3302645916.mp3?updated=1736876012",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4143,
                "published": "2025-01-16T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 9
            },
            {
                "uuid": "666d88d9-2e92-403c-ba13-3bf8b4449578",
                "title": "S1E8: What's for Dinner? (with John Turturro)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD4490583771.mp3?updated=1736548359",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3576,
                "published": "2025-01-15T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 8
            },
            {
                "uuid": "c1c902fa-6c79-4134-8c3a-c7bfb4db7f0f",
                "title": "S1E7: Defiant Jazz (with Kristen Bell and Dax Shepard)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD9135445606.mp3?updated=1736548275",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4781,
                "published": "2025-01-14T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 7
            },
            {
                "uuid": "03bc6630-d91f-4c95-b419-0f7aa01e0d3a",
                "title": "S1E6: Hide and Seek (with Geoff Richman)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD8856121772.mp3?updated=1736547740",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3780,
                "published": "2025-01-13T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 6
            },
            {
                "uuid": "27cde7fd-8a6d-41b8-8998-d02f83bf0bb1",
                "title": "S1E5: The Grim Barbarity Of Optics and Design (with Jen Tullock)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD8406125828.mp3?updated=1736349573",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4481,
                "published": "2025-01-10T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 5
            },
            {
                "uuid": "75b34e37-c159-4bdc-b757-c0c1c04ef666",
                "title": "S1E4: The You You Are",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD8738930148.mp3?updated=1736349561",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3465,
                "published": "2025-01-09T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 4
            },
            {
                "uuid": "0e174652-3cfb-4783-ba56-521034e5c68b",
                "title": "S1E3: In Perpetuity (with Britt Lower)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD6675194448.mp3?updated=1736205022",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4452,
                "published": "2025-01-08T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 3
            },
            {
                "uuid": "23a12621-2b24-471d-bc6e-9940fa3b25fa",
                "title": "S1E2: Half Loop (with Zach Cherry)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD7448384056.mp3?updated=1736199777",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 3114,
                "published": "2025-01-07T08:01:00Z",
                "type": "full",
                "season": 1,
                "number": 2
            },
            {
                "uuid": "ccc92f0d-d447-4330-9e76-cc61c5360f94",
                "title": "S1E1: Good News About Hell (with Dan Erickson and Jackie Cohn)",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD1932890329.mp3?updated=1736199288",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 4211,
                "published": "2025-01-07T08:00:00Z",
                "type": "full",
                "season": 1,
                "number": 1
            },
            {
                "uuid": "a5b18500-b766-4b9c-bd08-10b74efce38f",
                "title": "Introducing The Severance Podcast with Ben Stiller & Adam Scott",
                "url": "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/42D75/mgln.ai/e/13/tracking.swap.fm/track/v9Uiw3bGr54f6BVZKSyc/traffic.megaphone.fm/CAD7486412916.mp3?updated=1735858565",
                "file_type": "audio/mpeg",
                "file_size": 0,
                "duration": 134,
                "published": "2025-01-02T17:03:00Z",
                "type": "full"
            }
        ]
    }
}
"""
}
