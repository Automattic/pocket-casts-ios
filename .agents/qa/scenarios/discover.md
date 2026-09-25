---
area: Discover
account: free
tags: regression
---

# Discover and search

Discover (`podcasts/DiscoverCollectionViewController.swift`, `podcasts/Categories/`) and search (`podcasts/New Search/`). Staging has its own Discover content: judge the app's behaviour, not the catalogue.

## Discover feed
tags: smoke

- The carousel, lists and category pills load. Each "Show all" opens the full list, starting with the same items
- Following from a row updates its button and adds the podcast to the Podcasts tab (unfollow it afterwards)
- Networks open their lists of podcasts
- Pull to refresh reloads without duplicating sections

## Region
tags: destructive

- Changing the region reloads the feed for that region, and the current region is shown where it can be changed
- Set the original region back

## Categories
- Each category pill opens that category. The selected pill looks selected and has the Selected trait in the hierarchy
- Going back returns to the same scroll position

## Search
tags: smoke

- Typing shows suggestions; submitting shows podcasts and episodes
- A query with no results ("zzqqxxnomatch") shows an explicit empty state, not a blank screen
- Recent searches are listed, can be tapped and can be cleared
- Episode results open the episode card; podcast results open the podcast page
- Searching for a feed URL finds that podcast

## Signed out
account: signed-out

- Discover and search work without an account, and following a podcast works locally
- Account-only actions ask you to sign in instead of failing silently
