# **PrestigeTalentBarAuto (WotLK 3.3.5a)**

PrestigeTalentBarAuto is a World of Warcraft 3.3.5a addon designed for private servers featuring "Prestige" mechanics (resetting a character to level 1).

Instead of manually re-dragging abilities and re-spending talent points after every reset, this addon records your desired setup and progressively applies action bars, macros, items, and queued talents as you level back up.

## **✨ Features**

* **Intelligent Bar Restoration:** Saves and restores Spells, Macros, Items, and Companions across action bars 1 through 10\.  
* **Rank-Aware Spell Caching:** Pre-indexes your spellbook to pull the highest rank available without tripping 3.3.5a client throttles or hidden-rank API failures.  
* **Non-Destructive Overwriting:** Only overwrites slots saved in the active profile. Unsaved slots remain completely untouched.  
* **Sequential Talent Queue:** Records the exact order in which you assign talent points and reapplies them sequentially starting at level 10\.  
* **Over-Click Safeguard:** Shadow tracking prevents recording more points into a talent than its maximum rank allows.  
* **Smart Level-Up Execution:** Leveling up applies talents immediately, waits 2 seconds for newly learned abilities to register in the spellbook, and then updates the action bars. If you ding in combat, the entire sequence safely defers until you drop combat.  
* **Respec Detection:** Detects if your active build drifts from the saved profile queue and offers a one-click prompt to execute a custom server reset command (e.g., .respec).  
* **Profile Management:** Create, duplicate, rename, and delete profiles directly in the configuration menu.

## **📥 Installation**

> 1. Clone or download the repository:  
>    Bash  
>    git clone https://github.com/Jon4Gro/PrestigeTalentBarAuto.git

> 2. Move the directory into your AddOns folder:  
>    World of Warcraft\\Interface\\AddOns\\PrestigeTalentBarAuto  
>    *(Ensure the folder name is strictly PrestigeTalentBarAuto).*  
> 3. Restart or reload your client.

## **⚙️ Usage & Workflow**

Open the options menu by **Right-Clicking the Minimap Button** or running /ptba.

### **1\. Action Bars**

> 1. Arrange your spells, macros, items, and mounts on action bars 1–10.  
> 2. Select or create your desired **Profile**.  
> 3. Click **Save Current**.

### **2\. Talent Queue Recording**

> 1. In the Talent Management section, click **Start Rec**.  
> 2. Open the default WoW Talent window and spend points in your preferred leveling order. The chat frame logs each recorded talent and spell ID.  
> 3. To undo, right-click preview points in the talent frame; the addon will remove them from the queue in reverse order.  
> 4. Click **Stop Rec** when finished.  
> 5. *Advanced Editing:* Edit the talent queue directly in the multi-line text box using Tab:Index format (e.g., 1:3, 1:3, 2:1), then click **Apply Text Edits**.

### **3\. Leveling Flow**

* When your character levels up outside of combat, your talent queue progresses instantly, followed 2 seconds later by an action bar refresh to place any newly unlocked ranks or abilities.  
* If you ding while in combat, the entire sequence pauses and runs cleanly the moment combat ends.

## **💬 Slash Commands**

* /ptba — Opens the Interface Options panel.  
* /ptba save — Saves the current bar layout to the active profile.  
* /ptba apply (or /ptba restore) — Manually forces an action bar restoration from the active profile.  
* /ptba talents — Manually evaluates and applies unspent talent points against the profile queue.

## **⚠️ Notes & Edge Cases**

* **Macro Limit:** Deleted macros are automatically regenerated in character-specific macro space (falling back to general). If your macro book is completely full (18/18 character and 36/36 account), automatic macro restoration will fail with a chat warning.  
* **Action Bar Locking:** The addon briefly toggles the lockActionBars CVar during manual and automated bar applications to bypass 3.3.5a engine swap rejections, immediately returning the setting to its prior state.