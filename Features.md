# Features

## Playlist Tempo Ranking
Lists the Apple Music playlists in your library and, for a selected playlist, ranks every song
by tempo with the fastest BPM at the top. Tempo comes from the on-device **Music Understanding**
framework (WWDC26 session 253, "Meet the Music Understanding framework"), requesting only the
`.rhythm` analysis type and reading `RhythmResult.beatsPerMinute`.

Measurements are cached to disk, so a playlist is only analyzed once. Pull to refresh re-runs the
load. Songs are analyzed three at a time, and the list re-ranks live as results arrive.

### Where the audio comes from
Music Understanding refuses to decode FairPlay-protected audio — it throws
`MusicUnderstandingError.hasProtectedContent` — and every Apple Music stream and download is
protected. There is also no BPM field anywhere in MusicKit or the Apple Music API. So each song's
audio is resolved in this order:

1. **Full track** — an unprotected file in your local media library (imported or purchased music),
   found via `MPMediaItem.assetURL`. Most accurate.
2. **Preview** — the song's ~30 second catalog preview excerpt from `Track.previewAssets`, which is
   unprotected. Downloaded to a temporary file and analyzed. This is what covers subscription songs,
   and rows measured this way are labelled "preview".
3. Neither available — the row reads "No audio to analyze".

A preview excerpt is normally at the song's steady tempo, but a song that changes tempo outside the
excerpt can be reported slightly differently than the full track would be.

### Requirements
- iOS 27 (Music Understanding availability), so the deployment target is pinned to 27.0.
- `NSAppleMusicUsageDescription`, set via `INFOPLIST_KEY_NSAppleMusicUsageDescription`.
- The MusicKit service enabled for the App ID, plus an active Apple Music subscription to read
  library playlists.
