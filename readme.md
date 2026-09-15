# **PrestigeTalentBarAuto (WotLK 3.3.5a)**

PrestigeTalentBarAuto is a World of Warcraft 3.3.5a addon designed specifically for private servers featuring "Prestige" systems (resetting a character to level 1).

Instead of manually dragging spells back to your action bars and re-spending your talent points every time you prestige, this addon remembers your max-level setup and progressively re-applies your action bars and queued talents as you level back up.

## **✨ Features**

* **Smart Action Bar Restoration:** Saves and restores Spells, Macros, Items, and Companions.  
* **WotLK API Safe:** Bypasses native 3.3.5a bugs like "Action Bar Lock" swap rejections and hidden-rank spell API failures without triggering server-side throttling.  
* **Non-Destructive Overwrites:** The addon will only overwrite slots you explicitly saved. It leaves custom abilities placed in unsaved slots entirely alone.  
* **Sequential Talent Queueing:** Record your exact talent build order. The addon will automatically spend your points in that exact sequence every time you level up (from level 10 onward).  
* **Smart Respec Detection:** If your current talents fall out of sync with your saved queue, the addon will prompt you to respec, automatically executing a custom server chat command (e.g., .respec) if approved.  
* **Profile Management:** Create, duplicate, rename, and delete profiles for different classes, dual-specs, or experimental builds.

## **📥 Installation**

> 1. Download the latest release or clone the repository:  
>    Bash  
>    git clone https://github.com/Jon4Gro/PrestigeTalentBarAuto.git

> 2. Extract the folder into your World of Warcraft directory:  
>    World of Warcraft\\Interface\\AddOns\\PrestigeTalentBarAuto  
>    *(Ensure the folder is named exactly PrestigeTalentBarAuto and does not have \-main or \-master appended to it).*  
> 3. Log into the game and ensure the addon is enabled in your character screen.

## **⚙️ Usage & Configuration**

You can access the configuration panel by **Right-Clicking the Minimap Button** or by typing /ptba in chat.

### **1\. Saving Your Action Bars**

> 1. Set up your action bars exactly how you want them.  
> 2. Open the Options panel, select your desired **Profile** (or create a new one).  
> 3. Click **Save Current** under the Action Bars section.

### **2\. Recording a Talent Queue**

> 1. Open the Options panel and click **Start Rec** under Talent Management.  
> 2. Open your standard WoW Talent Tree.  
> 3. Spend your talent points in the exact order you want the addon to learn them. (The addon will print a confirmation in chat for every recorded point).  
> 4. *Mistake?* Right-click a preview point to remove it; the addon will intelligently remove the last instance of that talent from the queue.  
> 5. Click **Stop Rec** when finished.  
> 6. *For Advanced Users:* You can manually edit the build via the **Talent Queue** text box using the Tab:Index format. Remember to click **Save Queue Text** if you type changes manually\!

### **3\. Leveling Up / Prestiging**

Once your profile is saved and the **Auto-Talent** checkbox is enabled, simply play the game. As you level up and learn new spell ranks, the addon will silently upgrade your action bars and spend your unspent talent points automatically.

## **💬 Slash Commands**

If you prefer using macros or chat commands instead of the UI, you can use the following:

* /ptba — Opens the Options Panel.  
* /ptba save — Silently saves your current action bars to the active profile.  
* /ptba apply (or /ptba restore) — Manually triggers the action bar restoration from your active profile.  
* /ptba talents — Manually triggers the talent queue check (useful if you missed a level-up trigger).

## **⚠️ Known Quirks**

* **Macro Restoration:** If you delete a saved macro from your spellbook, the addon will automatically attempt to recreate it. However, if your character and global macro slots are completely full (18/18 and 36/36), the addon will be unable to recreate it and will print an error in chat.  
* **Action Bar Locks:** The addon temporarily disables your "Lock ActionBars" Interface setting for a fraction of a second during restoration to safely bypass Blizzard's native swap-protection. It immediately restores your setting when finished.