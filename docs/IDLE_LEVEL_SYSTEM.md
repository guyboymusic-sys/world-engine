# Auto-Narrative Level System
## Detailed Progressive Engagement Model

---

## 📊 **IDLE TIME LEVEL PROGRESSION**

```
No User Command
        ↓
┌─────────────────────────────────────────────────────────┐
│ Level 0: IDLE LOOP (0-60 seconds)                       │
│                                                         │
│ Action: Character stands & waits                        │
│ • Breathing, blinking, subtle movements                │
│ • 60-second loopable video                             │
│ • Camera: First-person POV                             │
│ • Engagement: Low (waiting for user input)             │
│                                                         │
│ Purpose: Default state, minimal CPU/API usage          │
│ Examples:                                              │
│  - Standing in convenience store                       │
│  - Waiting at location                                 │
│  - Contemplating (looking around)                      │
└────────────────┬────────────────────────────────────────┘
                 │
          [60+ seconds idle]
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Level 1: SUBTLE ENGAGEMENT (60-120 seconds)            │
│ 🟡 "The character gets bored"                          │
│                                                         │
│ Action: Character does light, organic activity         │
│ • Duration: 20-30 seconds                              │
│ • Examples:                                            │
│   - Examine nearby item on shelf                       │
│   - Look at inventory                                  │
│   - Stretch and yawn                                   │
│   - Walk around current location                       │
│   - Check watch/phone                                  │
│   - Talk to nearby NPC casually                        │
│                                                         │
│ State Changes: MINIMAL                                 │
│  ✓ Can pick up items (optional)                        │
│  ✗ No combat, no crafting                              │
│  ✗ No major location changes                           │
│                                                         │
│ Engagement Level: Medium                               │
│ Viewer Impact: "Oh interesting, what's character doing?" │
│                                                         │
│ LLM Creativity: CONSERVATIVE                           │
│  • 80% mundane actions                                 │
│  • 20% exploration                                     │
└────────────────┬────────────────────────────────────────┘
                 │
          [120+ seconds idle]
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Level 2: MODERATE ENGAGEMENT (120-240 seconds)         │
│ 🟠 "Character takes initiative"                        │
│                                                         │
│ Action: Character does more interesting activity       │
│ • Duration: 30-45 seconds                              │
│ • Examples:                                            │
│   - Craft a simple item (if materials available)       │
│   - Have a conversation with NPC                       │
│   - Perform a skill (fishing, cooking, etc)            │
│   - Visit a new location nearby                        │
│   - Help an NPC with a task                            │
│   - Engage with environment (sit, rest, train)         │
│                                                         │
│ State Changes: MODERATE                                │
│  ✓ Inventory can change                                │
│  ✓ NPCs can give quests                                │
│  ✓ Experience can be gained                            │
│  ✗ No major plot progression                           │
│  ✗ No permanent character changes                      │
│                                                         │
│ Engagement Level: High                                 │
│ Viewer Impact: "Wow, character is doing something!" 👀 │
│                                                         │
│ LLM Creativity: MODERATE                               │
│  • 60% interesting actions                             │
│  • 30% exploration                                     │
│  • 10% unexpected (safe surprises)                     │
└────────────────┬────────────────────────────────────────┘
                 │
          [240+ seconds idle]
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Level 3: HIGH ENGAGEMENT (240-420 seconds)             │
│ 🔴 "Character enters adventure mode"                   │
│                                                         │
│ Action: Character seeks adventure/progression          │
│ • Duration: 45-60 seconds                              │
│ • Examples:                                            │
│   - Embark on a mini-quest                             │
│   - Combat encounter with enemy                        │
│   - Complex crafting sequence                          │
│   - Explore dungeon/cave                               │
│   - Major NPC interaction                              │
│   - Discover treasure/secret                           │
│   - Travel to new, distant location                    │
│                                                         │
│ State Changes: SIGNIFICANT                             │
│  ✓ Inventory changes                                   │
│  ✓ Experience & leveling possible                      │
│  ✓ New items acquired                                  │
│  ✓ World state can change                              │
│  ✗ Character death not allowed                         │
│  ✗ No permanent story changes                          │
│                                                         │
│ Engagement Level: VERY HIGH                            │
│ Viewer Impact: "OMG what's happening?!" 🤯             │
│                                                         │
│ LLM Creativity: AGGRESSIVE                             │
│  • 40% exciting actions                                │
│  • 40% exploration                                     │
│  • 20% unexpected events                               │
└────────────────┬────────────────────────────────────────┘
                 │
          [420+ seconds idle]
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Level 4: MAXIMUM ENGAGEMENT (420+ seconds)             │
│ 🔥 "Plot twist incoming"                               │
│                                                         │
│ Action: Character experiences DRAMATIC events          │
│ • Duration: 60-90 seconds                              │
│ • Examples:                                            │
│   - Boss battle encounter                              │
│   - Major story revelation                             │
│   - Teleportation to new world                         │
│   - Alliance with powerful NPC                         │
│   - Ritual/magic ceremony                              │
│   - Time-skip sequence                                 │
│   - Character transformation                           │
│   - Ancient power awakened                             │
│                                                         │
│ State Changes: MAJOR                                   │
│  ✓ Significant inventory changes                       │
│  ✓ Character stats/abilities can change                │
│  ✓ New skills unlocked                                 │
│  ✓ Permanent world changes possible                    │
│  ✓ Story progression can happen                        │
│  ✓ Character appearance can change                     │
│                                                         │
│ Engagement Level: EXTREME                              │
│ Viewer Impact: "THIS IS INSANE! DONATE NOW!" 💥       │
│                                                         │
│ LLM Creativity: MAXIMUM                                │
│  • 30% story-driven events                             │
│  • 30% exciting/dangerous encounters                   │
│  • 30% exploration of new areas                        │
│  • 10% completely unexpected (risky choices)           │
│                                                         │
│ Special: Can introduce new mechanics/systems           │
└─────────────────────────────────────────────────────────┘
```

---

## ⏱️ **TIMELINE PROGRESSION EXAMPLE**

```
T+0s    USER: "$10 /walk forest"

T+25s   [Action video: Character walks to forest]

T+50s   IDLE LOOP (Level 0) ✅
        Character standing, looking around forest
        "Hmmm, nice trees here..."

T+110s  ⚠️ IDLE = 60s → LEVEL 1 TRIGGER
        LLM chooses: "examine mushrooms on ground"
        [Generate 25s video of character examining mushrooms]

T+135s  BACK TO IDLE LOOP

T+195s  ⚠️ IDLE = 60s → LEVEL 1 TRIGGER AGAIN
        LLM chooses: "pick some berries from bush"
        [Generate 25s video of harvesting]

T+220s  BACK TO IDLE LOOP

T+280s  ⚠️ IDLE = 60s → LEVEL 1 TRIGGER (3rd time)
        LLM chooses: "find strange stone in ground"
        [Generate 25s video of discovery]

T+305s  BACK TO IDLE LOOP

T+365s  ⚠️ IDLE = 60s (4 minutes total with no major action)
        → ESCALATE TO LEVEL 2!

T+365s-T+400s   LEVEL 2 ACTION 🟠
        "Character decides to venture deeper into forest"
        [Generate 35s video of exploration]
        State change: Character moves to deeper forest location

T+400s  NEW IDLE LOOP in deeper forest

T+465s  ⚠️ IDLE = 65s → LEVEL 2 TRIGGER
        "Encounter wild animal on path"
        [Generate 40s video of tense encounter]

T+505s  NEW IDLE LOOP

T+570s  ⚠️ IDLE = 65s → LEVEL 2 TRIGGER
        "Find hidden cave entrance"
        [Generate 45s video of discovery]

T+615s  NEW IDLE LOOP at cave entrance

T+680s  ⚠️ IDLE = 65s (8+ minutes with no user input)
        → ESCALATE TO LEVEL 3!

T+680s-T+740s   LEVEL 3 ACTION 🔴
        "Character enters dark cave, encounters skeleton warrior!"
        [Generate 60s video of epic combat sequence]
        State change: 
          • Inventory: -5 HP potions, +ancient sword
          • Experience: +250 XP
          • New location unlocked: "Dark Cavern"

T+740s  NEW IDLE LOOP in cave

T+810s  ⚠️ IDLE = 70s → LEVEL 3 TRIGGER
        "Discover treasure room with chest"
        [Generate 50s video of treasure discovery]

T+860s  NEW IDLE LOOP

T+935s  ⚠️ IDLE = 75s → LEVEL 3 TRIGGER
        "Solve ancient puzzle, door opens to new realm"
        [Generate 60s video]

T+995s  NEW IDLE LOOP

T+1070s ⚠️ IDLE = 75s (15+ minutes!!!)
        → ESCALATE TO LEVEL 4!

T+1070s-T+1150s   LEVEL 4 ACTION 🔥
        "BOSS ENCOUNTER: Shadow Dragon emerges from darkness!"
        "Intense epic combat sequence with magic spells!"
        [Generate 80s video of DRAMATIC battle]
        State change:
          • Inventory: -20 HP, +Legendary Shield, +Dragon Scale x5
          • Experience: +1000 XP (level up!)
          • New skill: "Dragon Slayer" unlocked
          • Character appearance: Glowing aura effect added
          • World: Dragon defeated, new path opens

T+1150s NEW IDLE LOOP (but character now has post-battle status!)

👥 RESULT: 15+ minutes of non-stop engaging content!
   Viewers are HOOKED - constantly wondering what happens next!
```

---

## 🎯 **LEVEL SYSTEM MECHANICS**

### **State Change Restrictions by Level**

```
Level 0 (IDLE):
  ├─ Can view inventory
  ├─ Cannot pick up items
  ├─ Cannot change location
  ├─ Cannot interact with NPCs
  └─ No experience gain

Level 1 (SUBTLE):
  ├─ CAN view/examine items
  ├─ CAN pick up light items (no value)
  ├─ CAN talk to NPCs (greeting only)
  ├─ CANNOT change location significantly
  ├─ CANNOT craft/combine items
  ├─ CANNOT engage in combat
  ├─ Minimal experience gain (+5-10 XP)
  └─ HP/Status unchanged

Level 2 (MODERATE):
  ├─ CAN do light crafting
  ├─ CAN travel to nearby locations
  ├─ CAN have brief conversations
  ├─ CAN perform skills (fishing, gathering)
  ├─ CAN gain items (+1 to +5 items)
  ├─ CANNOT engage in serious combat
  ├─ CANNOT level up significantly
  ├─ Moderate experience gain (+25-50 XP)
  ├─ Can lose small amounts of HP (1-5)
  └─ Status effects: Fatigue, Hunger possible

Level 3 (HIGH):
  ├─ CAN engage in combat (not boss-level)
  ├─ CAN travel to new locations
  ├─ CAN complete mini-quests
  ├─ CAN craft complex items
  ├─ CAN level up (+1-2 levels)
  ├─ CAN change equipment
  ├─ High experience gain (+100-250 XP)
  ├─ Can lose moderate HP (5-20)
  ├─ Can gain new skills (non-ultimate)
  └─ Temporary status effects possible

Level 4 (MAXIMUM):
  ├─ CAN engage in boss battles
  ├─ CAN unlock new game mechanics
  ├─ CAN teleport to new worlds/areas
  ├─ CAN acquire legendary items
  ├─ CAN level up significantly (+2-5 levels)
  ├─ CAN gain ultimate skills
  ├─ EXTREME experience gain (+500-1500 XP)
  ├─ Can lose significant HP (up to 50%)
  ├─ Can change character appearance
  ├─ Permanent story progression
  └─ New chapters unlocked
```

---

## 🤖 **LLM PROMPT ADJUSTMENT BY LEVEL**

### **Level 1 Prompt**
```
"Character has been idle for 60+ seconds at [LOCATION].
Generate a SHORT, SUBTLE, SAFE action (20-30 seconds) that:

✓ Feels natural for waiting
✓ No combat or danger
✓ No major state changes
✓ Examples: examine item, stretch, look around, chat briefly

Action types allowed:
- examine_item
- look_around
- stretch_yawn
- check_inventory
- talk_greeting

Safety: Keep it BORING and SAFE. Character is just passing time."
```

### **Level 2 Prompt**
```
"Character has been idle for 120+ seconds at [LOCATION].
Generate a MODERATE, INTERESTING action (30-45 seconds) that:

✓ Shows character taking initiative
✓ Can have minor state changes
✓ Feels organic and engaging
✓ Viewers think 'Oh cool, what's happening?'

Action types allowed:
- craft_simple_item
- explore_nearby
- talk_to_npc
- gather_resources
- minor_skill_practice

Safety: Make it interesting but NOT risky. Character is getting bored."
```

### **Level 3 Prompt**
```
"Character has been idle for 240+ seconds at [LOCATION].
Generate an EXCITING, ADVENTUROUS action (45-60 seconds) that:

✓ Significant story progression
✓ Moderate risk/reward
✓ Can change character state substantially
✓ Viewers think 'WOW what's happening?!'

Action types allowed:
- encounter_enemy
- explore_new_area
- complete_quest
- craft_complex_item
- discover_secret

Safety: Allow INTERESTING consequences. Character is seeking adventure."
```

### **Level 4 Prompt**
```
"Character has been idle for 420+ seconds at [LOCATION].
Generate an EPIC, DRAMATIC action (60-90 seconds) that:

✓ MAJOR story events
✓ Significant risk and great reward
✓ Can unlock new game systems
✓ Can change character permanently
✓ Viewers think 'OMGGGG THIS IS INSANE!!'

Action types allowed:
- boss_battle
- teleportation
- major_plot_twist
- ultimate_skill_unlock
- character_transformation
- world_changing_event

Safety: Allow SIGNIFICANT consequences. Character is in adventure mode!"
```

---

## 📈 **ENGAGEMENT METRICS**

```
Level 0 (Idle Loop):
  • Viewer engagement: ⭐ (low)
  • Action frequency: N/A
  • State change risk: 0%
  • Video cost: LOW (cached loop)
  • Expected retention: 15-20 seconds

Level 1 (Subtle):
  • Viewer engagement: ⭐⭐ (medium)
  • Action frequency: Every 60s
  • State change risk: 5%
  • Video cost: MEDIUM (new generation)
  • Expected retention: 30-45 seconds

Level 2 (Moderate):
  • Viewer engagement: ⭐⭐⭐ (high)
  • Action frequency: Every 60s (escalated)
  • State change risk: 25%
  • Video cost: MEDIUM-HIGH
  • Expected retention: 45-75 seconds

Level 3 (High):
  • Viewer engagement: ⭐⭐⭐⭐ (very high)
  • Action frequency: Every 60s (intense)
  • State change risk: 60%
  • Video cost: HIGH (complex scenes)
  • Expected retention: 60-120 seconds

Level 4 (Maximum):
  • Viewer engagement: ⭐⭐⭐⭐⭐ (extreme)
  • Action frequency: Every 60-90s (epic)
  • State change risk: 90%
  • Video cost: VERY HIGH (cinematic)
  • Expected retention: 90-180 seconds
  • Donation impulse: HIGHEST
```

---

## 💰 **DONATION INCENTIVE BY LEVEL**

```
Why viewers donate at different levels:

Level 0 (Idle):
  Viewers think: "Nothing interesting is happening"
  Donation incentive: LOW
  Message: "Come on, make the character do something!"

Level 1 (Subtle):
  Viewers think: "Oh, the character is doing something small"
  Donation incentive: MEDIUM-LOW
  Message: "Let me control what happens next!"

Level 2 (Moderate):
  Viewers think: "Ooh this is cool, what if I..."
  Donation incentive: MEDIUM-HIGH
  Message: "I want to see what the character does if..."

Level 3 (High):
  Viewers think: "WAIT this is actually exciting!"
  Donation incentive: HIGH
  Message: "I want to influence this epic sequence!"

Level 4 (Maximum):
  Viewers think: "OMGGGG I NEED TO CONTROL THIS NOW!"
  Donation incentive: EXTREME
  Message: "TAKE MY MONEY! I'm invested!"

Result: 
  Higher levels = More engaged viewers = More donations
  More donations = More user control = Back to exciting content
```

---

## 🔄 **LEVEL RESET CONDITIONS**

```
Level resets when:
  ✓ User sends new command/donation
  ✓ Character changes major location
  ✓ Boss defeated in Level 3/4
  ✓ Plot twist completed in Level 4
  ✓ Explicitly triggered by admin

Level escalates when:
  ✓ Idle time: Level 0 → Level 1 @ 60s
  ✓ Idle time: Level 1 → Level 2 @ 120s (cumulative)
  ✓ Idle time: Level 2 → Level 3 @ 240s (cumulative)
  ✓ Idle time: Level 3 → Level 4 @ 420s (7 minutes)

Level downgrades when:
  ✓ User interacts → back to Level 0
  ✓ Server load too high → down 1 level
  ✓ Video generation fails → stay same level
```

---

## 🎮 **IMPLEMENTATION CHECKLIST**

```
Database:
  ☐ Add idle_level column to character_state
  ☐ Add level_triggered_at timestamp
  ☐ Add cumulative_idle_time counter
  ☐ Track which actions used per level per location

LLM System:
  ☐ Create 4 separate prompt templates (one per level)
  ☐ Implement level-appropriate action filtering
  ☐ Add creativity/risk scoring by level
  ☐ Test LLM response quality per level

Video Generation:
  ☐ Implement video cache for repeated actions
  ☐ Adjust generation parameters by level
  ☐ Create fallback videos for each level
  ☐ Monitor API costs by level

Monitoring:
  ☐ Track level escalation frequency
  ☐ Measure viewer retention per level
  ☐ Monitor donation rate correlation
  ☐ Track video generation success rate
  ☐ Alert if stuck in same level too long

Testing:
  ☐ Test idle counter incrementing correctly
  ☐ Test level transitions timing
  ☐ Test action appropriateness per level
  ☐ Test state changes restrictions
  ☐ Stress test video generation at Level 4
```

---

## 🎬 **EXAMPLE ACTION LIBRARY BY LEVEL**

### **Level 1 Actions (20-30s)**
```json
{
  "level": 1,
  "actions": [
    "examine_shelf_items",
    "look_out_window",
    "check_time",
    "stretch_and_yawn",
    "adjust_clothing",
    "look_at_reflection",
    "pick_up_small_object",
    "smell_flowers",
    "listen_to_ambient_sound",
    "brief_greeting_to_npc"
  ]
}
```

### **Level 2 Actions (30-45s)**
```json
{
  "level": 2,
  "actions": [
    "gather_berries",
    "fish_in_pond",
    "simple_crafting",
    "explore_nearby_area",
    "talk_to_npc_longer",
    "sit_and_rest",
    "practice_basic_skill",
    "solve_simple_puzzle",
    "climb_tree",
    "discover_item"
  ]
}
```

### **Level 3 Actions (45-60s)**
```json
{
  "level": 3,
  "actions": [
    "combat_encounter_weak_enemy",
    "explore_dungeon_entrance",
    "complete_side_quest",
    "craft_complex_item",
    "find_treasure_chest",
    "encounter_mysterious_npc",
    "unlock_new_skill",
    "navigate_maze",
    "discover_secret_passage",
    "face_environmental_challenge"
  ]
}
```

### **Level 4 Actions (60-90s)**
```json
{
  "level": 4,
  "actions": [
    "boss_battle_epic",
    "teleport_to_new_realm",
    "major_plot_revelation",
    "unlock_ultimate_skill",
    "character_transformation",
    "encounter_legendary_npc",
    "solve_ancient_prophecy",
    "unlock_new_game_area",
    "acquire_artifact",
    "trigger_world_changing_event"
  ]
}
```

---

**นี่คือระบบที่จะสร้าง:**
- ✅ **Progressive engagement** - ยิ่งนาน ยิ่ง exciting
- ✅ **Automatic storytelling** - เรื่องราวดำเนินต่อ
- ✅ **Viewer incentive** - อยากให้คำสั่งที่ Level 3-4
- ✅ **Natural pacing** - ไม่กระโดดเลือกจากบ่อย
- ✅ **Replayability** - ต่างกันทุกครั้ง

**ชอบแนวคิดนี้ไหมครับ? มีอะไรต้องปรับแก้?** 🚀
