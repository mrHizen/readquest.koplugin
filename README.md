# ReadQuest — KOReader Reading RPG Plugin

Turn your reading sessions into a lightweight RPG adventure. ReadQuest tracks valid reading activity, rewards you with EXP, levels and ranks, turns every book into a Boss encounter, and records your reading achievements — all inside **KOReader**, with a compact monochrome interface designed for e-ink devices.

[![Support via PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/sinhsoi)
[![Latest Release](https://img.shields.io/github/v/release/mrHizen/readquest.koplugin?display_name=tag)](https://github.com/mrHizen/readquest.koplugin/releases)

---
<p align="center">
<img width="1264" height="848" alt="Gemini_Generated_Image_66qko966qko966qk" src="https://github.com/user-attachments/assets/a8e73474-c5a1-44ae-88cd-6ed590041ca3" />

</p>
---

## Screenshots

<table>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/278b3b9c-8552-40d6-8425-4ca452757428" alt="ReadQuest Popup" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/21ec5261-2816-465e-ada1-85fc00c08876" alt="ReadQuest Popup" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/6c55cff7-9d59-425f-b1c3-8f1d698a48cf" alt="KOReader Reader" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/55909bd5-564d-4c3a-8a62-7408e14f07ba" alt="ReadQuest Popup" width="240" /></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/fd924c55-dce0-491f-934e-e223bac59b28" alt="ReadQuest Dashboard" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/458c48b2-8646-4184-9ae0-195d7c68b930" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/d5b61f4e-9e0d-48c6-af99-1b3af93bf4fd" alt="ReadQuest Screen" width="240" /></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/364f6066-612f-43b9-be39-9b397c3b4167" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/23f865a6-214a-43e1-9ac1-573e6be3b368" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/ba0c8176-fddb-4b5c-8da5-c342dcfdf9d2" alt="ReadQuest Screen" width="240" /></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/7b453bf3-cde9-460e-84db-6fd933960f70" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/7e072533-5db0-4f72-8ff2-92a450acef3f" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/73e61075-9424-4b23-92ac-3b66646841eb" alt="ReadQuest Screen" width="240" /></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/fd4d7845-eef4-4033-9794-318c15b1fe06" alt="ReadQuest Screen" width="240" /></td>
    <td></td>
  </tr>
</table>
## Features

### EXP, Levels & Culturally Localized Ranks

- Earn **10 base EXP for each credited page** you read.
- ReadQuest uses page-turn timing checks to discourage skimming and accidental EXP farming. A page is credited only after the configured minimum reading time and a small forward page movement; rapid turns, large page jumps and long idle intervals are not credited.
- Build EXP to level up. The EXP requirement increases with each level.
- Unlock eight ranks at levels **1, 5, 10, 15, 25, 35, 45 and 55**.
- Rank names are localized to the selected language and cultural context. For example, English uses *Novice → Apprentice → Scholar → Scribe → Master → Sage → Archmage → Grandmaster*, while Vietnamese uses titles inspired by the traditional Confucian examination system.

### Daily Quests, Goals & Reading Streaks

- Set a daily reading goal. The default is **20 credited pages per day**; the setting can be adjusted from 5 to 300 pages.
- Complete the goal to receive bonus EXP and extend your consecutive-day streak.
- Earn a **+5% page-EXP bonus per streak day**, up to a maximum of **+50%**.
- Track today's progress, pages remaining and your current streak from the main character dashboard.

### Book Bosses & Reading Progress

- Every book becomes its own Boss, with its remaining pages represented as the Boss's remaining HP.
- The Boss screen shows the current book, remaining HP, credited pages and the minimum number of valid pages required for victory.
- Defeat a Boss by reaching at least **97%** of the book or marking the book as finished, provided that you have credited the minimum required pages. Skipping directly to the end is not enough.
- A victory grants **200 EXP plus 5 EXP for every credited page** in that book, along with a random loot drop.
- Each Boss has its own battle state, so you can leave a book and return to its encounter later.

### Loot, Inventory & Trophies

- Collect randomly generated items in four rarity tiers: **Common, Rare, Epic and Legendary**.
- Reading more of a book before defeating its Boss improves the chance of receiving higher-rarity loot.
- Browse your collection in three sections:
  - **Loot:** collected items, rarity and the book each item came from.
  - **Defeated:** books whose Bosses you have defeated, including victory dates and credited pages.
  - **In Progress:** books with active Boss encounters.
- Item names and rarity labels are localized.

### 15 Achievements

Unlock achievements for reading milestones and RPG progress, including:

- Your first credited page, and lifetime milestones at **100, 1,000 and 5,000 pages**.
- Defeating **1, 5 and 20** Book Bosses.
- Maintaining **3-, 7- and 30-day** reading-goal streaks.
- Reaching **Level 10** and **Level 25**.
- Reading 30 credited pages during the **00:00–05:00** night window or the **05:00–07:00** early-morning window.
- Finding a **Legendary** loot item.

Achievement progress and unlock dates are shown in the Achievements screen. New levels, achievements, daily quests and Boss victories can trigger in-app celebration popups.

### Monthly & Yearly Reading Recaps

Review your reading activity using separate **This Month** and **This Year** views.

Each recap includes:

- Total credited pages, total reading time and EXP earned during the selected period.
- Your most active reading hour, displayed as a one-hour time window.
- The number of Bosses defeated and achievements unlocked during that period.
- A multi-book list, ordered by credited pages, with each book's title, pages read, reading time, EXP earned, most active reading hour and Boss status.
- Pagination for the book list, so the recap remains usable on smaller e-ink screens.

Use **Capture Recap Card** to take a screenshot of the recap. Older save data that does not contain per-book period statistics is handled without inventing missing reading-time or time-of-day information.

### Session Summaries & Reading Notifications

- Show a **session summary** when you close a book after credited reading. It reports reading time, credited pages, EXP gained and your current level progress.
- A session summary can also appear when KOReader resumes after a long sleep interval, if the previous session contains credited reading.
- Optional compact **+EXP** notifications appear near the bottom-right corner after credited page turns.
- Toast duration is configurable from **1 to 5 seconds** to help reduce e-ink ghosting.
- Achievement, Daily Quest, level-up and Boss-victory popups include a screenshot button.

### KOReader Status Bar & Gestures

- Optionally append your ReadQuest level, current rank and EXP progress to the KOReader ReaderFooter/status bar where the installed interface supports the integration.
- ReadQuest also broadcasts rank/latest-achievement icon data and exposes status helper functions for compatible front ends; actual icon rendering depends on the front end.
- ReadQuest registers dispatcher actions for opening the character dashboard and the current Book Boss. You can assign these actions to KOReader gestures through **Settings → Gestures**.
- Within ReadQuest screens, two-finger swipe, two-finger pan, two-finger tap and multi-swipe gestures are routed to KOReader's screenshot handler. Gesture availability can depend on the device and KOReader input configuration.

### E-Ink Friendly Interface & Customization

- Compact, monochrome interface and custom-drawn icons designed to remain readable on e-ink displays.
- Main dashboard with character level, rank, EXP progress, daily quest, streak, lifetime reading statistics and navigation to the plugin screens.
- Adjustable language, daily goal, minimum reading time per page, status-bar display, EXP toast notifications and session summaries.
- A reset option is available in Settings. It resets character progress while keeping your configuration preferences.

### Built-in GitHub Release Updater

- Check for a newer ReadQuest release directly from **Settings → Check for Updates**.
- The updater checks the latest published GitHub Release and compares its version with the installed plugin.
- Supports version tags such as `v2.5.3` and can resolve older non-versioned tags from the plugin source metadata.
- Downloads the release ZIP, checks that the required plugin files are present, validates Lua syntax and verifies that the packaged version is actually newer before installation.
- Stages the update before replacing the installed plugin and keeps a backup for rollback if the directory replacement fails.
- Prompts you to restart KOReader after a successful update.

For reliable future updates, publish each new version as a GitHub Release with a version tag (`vX.Y.Z`) and attach a ready-to-install ZIP named like `readquest.koplugin-vX.Y.Z.zip`. See [Releasing a new version](#releasing-a-new-version) below.

---

## Installation

### Manual installation

1. Download the latest ready-to-install ZIP from [GitHub Releases](https://github.com/mrHizen/readquest.koplugin/releases).
2. Extract the archive. It should contain a folder named `readquest.koplugin`.
3. Copy that folder into your KOReader `plugins/` directory:

   ```text
   koreader/
   └── plugins/
       └── readquest.koplugin/
           ├── _meta.lua
           ├── main.lua
           ├── readquest_core.lua
           ├── readquest_i18n.lua
           ├── readquest_icons.lua
           ├── readquest_ui.lua
           └── readquest_updater.lua
   ```

4. Restart KOReader.
5. Open **Tools → ReadQuest** from the main menu. Depending on your KOReader layout, the plugin may appear in the Tools section of the reader or file browser menu.

If you are upgrading manually, replace the entire old `readquest.koplugin` folder with the new one. Your ReadQuest progress is stored separately in KOReader's settings directory, but backing up your KOReader settings before upgrading is still recommended.

### Opening ReadQuest with a gesture

ReadQuest registers these KOReader actions:

- **ReadQuest: Open Character Sheet** — opens the main dashboard.
- **ReadQuest: Current Book Boss** — opens the current book's Boss screen.

Assign either action to a gesture in **KOReader Settings → Gestures**.

---

## How to Play

1. Open a book and read normally. Stay on a page for at least the configured minimum time before turning it.
2. ReadQuest credits valid forward page turns and awards EXP. Rapid flipping, large page jumps and long idle intervals do not count.
3. Complete your daily page goal to earn bonus EXP and maintain your streak.
4. Open the **Boss** screen to track the current book's remaining HP and battle progress.
5. Reach the end of the book after reading enough valid pages to defeat its Boss and receive EXP plus loot.
6. Check **Achievements**, **Inventory & Trophies**, **Ranks** and **Monthly & Yearly Recap** to follow your progress.

### Reading and Boss rules

- Default minimum time per page: **10 seconds**.
- The minimum can be adjusted from **3 to 60 seconds** in Settings.
- The internal inactivity limit is **10 minutes**; time beyond that limit is not credited as reading time.
- A valid forward turn must move 1–2 pages; ReadQuest credits one page for that event.
- A Boss normally becomes eligible for defeat at **97% book progress**. You must also meet the minimum credited-page requirement, which is based on book length (between 3 and 15 pages).
- Marking a book as finished can trigger the Boss victory check, but the minimum credited-page requirement still applies.

---

## Settings

| Setting | Default | Available options |
|---|---:|---|
| Language | Auto | Auto, Vietnamese, English, French, Japanese, Chinese or Korean |
| Show on Status Bar | On | On / Off |
| +EXP Toast | On | On / Off |
| Session Summary | On | On / Off |
| Toast Duration | 2 seconds | 1–5 seconds |
| Minimum Seconds per Page | 10 seconds | 3–60 seconds |
| Daily Page Goal | 20 pages | 5–300 pages, in increments of 5 |

The reset option erases ReadQuest character progress, including EXP, levels, achievements, Boss records and inventory. It does not reset the settings listed above.

---

## Languages

ReadQuest includes localized interface text, rank names, achievement descriptions, Boss names, loot names and rarity labels for:

- Vietnamese
- English
- French
- Japanese
- Chinese
- Korean

Language can be set to **Auto** to follow the language configured in KOReader, or selected manually in ReadQuest Settings.

---

## Releasing a New Version

To keep the in-app updater compatible, use the following release process whenever you publish an update:

1. Update the version in both `readquest_core.lua` and `_meta.lua`. The two values must match.

   ```lua
   -- readquest_core.lua
   Core.VERSION = "2.5.3"
   ```

   ```lua
   -- _meta.lua
   version = "2.5.3",
   ```

2. Create a GitHub Release with a matching version tag, for example `v2.5.3`.
3. Use a release title such as `ReadQuest v2.5.3`.
4. Attach a ready-to-install ZIP named `readquest.koplugin-v2.5.3.zip`. The ZIP must contain the `readquest.koplugin/` folder at its root and all seven required plugin files.
5. Publish it as a normal stable release (not a draft or pre-release).

Use semantic versioning consistently:

- `v2.5.3` — patch release / bug fixes.
- `v2.6.0` — minor release / new features.
- `v3.0.0` — major release / significant changes.

Do not reuse or overwrite an already published version tag. Publish a new version whenever the code changes so devices can detect the update correctly.

---

## Data & Compatibility Notes

- ReadQuest stores progress locally in KOReader's settings directory. It does not require a ReadQuest account or cloud service.
- The updater requires network access to GitHub and a published stable Release. If the device is offline, connect to Wi-Fi and check again.
- The updater validates the package before installation, but it is still good practice to back up your KOReader settings before a major update.
- Historical monthly/yearly per-book time-slot details are available only for activity recorded by versions that store those details. Older saves remain readable, but ReadQuest does not fabricate missing historical data.
- Status-bar integration and gesture behavior may vary with KOReader version, device firmware and custom UI/front-end modifications.

---

## Support & Issues

- **Bug reports / feature requests:** [GitHub Issues](https://github.com/mrHizen/readquest.koplugin/issues)
- **Releases:** [GitHub Releases](https://github.com/mrHizen/readquest.koplugin/releases)
- **Support the project:** [PayPal](https://www.paypal.com/paypalme/sinhsoi)

ReadQuest is a community plugin for KOReader. Please include your KOReader version, device model and relevant error log when reporting a problem.
