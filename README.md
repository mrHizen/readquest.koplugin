# ReadQuest — KOReader Plugin

Turn every reading session, daily goal, streak, and finished book into a lightweight RPG progression experience built specifically for e-ink readers and **KOReader**.

[![Support via PayPal](https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://www.paypal.com/paypalme/sinhsoi)

---

## Features

* **EXP, Levels & Ranks**
  * Earn EXP as you read pages, with built-in anti-skimming safeguards such as a minimum seconds-per-page threshold and checks against idle timeouts or page jumps.
  * Level up your character and unlock ranks across milestones, from **Novice** (Lv. 1) up to **Apprentice**, **Scholar**, **Scribe**, **Master**, **Sage**, **Archmage**, and **Grandmaster**.
* **Daily Quests & Streaks**
  * Configure your daily reading target (e.g., 20 pages per day) to complete daily quests.
  * Maintain consecutive reading streaks to earn bonus EXP.
* **Book Bosses & Inventory**
  * Every book in your library acts as a boss with HP tied to unread pages (such as *Paper Wyrm* or *Shadow Leviathan*).
  * Finishing a book after slashing the minimum required pages defeats the boss, awarding bonus EXP plus random loot items tracked in your inventory/trophies.
* **Achievements**
  * Unlock achievements across reading milestones (first credited page, 100 pages, 1,000 pages, 5,000 pages) and book boss victories.
* **E-Ink Friendly Controls & Customization**
  * Optional status bar text showing level and progress, plus compact bottom-right `+EXP` toast badges on page turns.
  * Adjustable popup duration to minimize e-ink ghosting.
  * Built-in **Screenshot** button directly inside achievement and daily quest popups so you can capture milestones cleanly without accidentally dismissing the dialog.
  * Language selection (English / Vietnamese) and character reset option in **Settings**.

---

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/07ee472d-7460-4913-94c5-76704c1d9e13" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/0a5dfc4f-f15f-4926-b346-005d417e66fd" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/df4f6a95-1594-4aeb-8787-4994f7eb153a" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/77cb99d2-722c-4b57-a443-e9178f9cecdd" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/7823b844-dd3c-42f6-b8e7-1ace8c82edad" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/3b67850e-5863-405e-8027-712002e8cf7e" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/1a993425-834f-4ccf-b9d4-c8eb9d4bcbb3" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/ace67b32-7824-46c5-a546-aa8aa2ed53be" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/c309c25d-f56c-4817-9ba6-7d9e4d9e6837" alt="ReadQuest" width="240" />
  <img src="https://github.com/user-attachments/assets/fc5430df-1e01-4c8c-9e61-e8c33a29ead7" alt="ReadQuest" width="240" />
</p>

---

## Installation

1. Download or clone the `readquest.koplugin` folder.
2. Place `readquest.koplugin` inside your KOReader `plugins/` directory:
   ```text
   koreader/
   └── plugins/
       └── readquest.koplugin/
