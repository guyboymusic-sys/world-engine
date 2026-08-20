# World Engine - Complete System Architecture & Diagrams
## Full Overview with Model Recommendations

---

## 📊 COMPLETE SYSTEM DIAGRAM

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                        WORLD ENGINE - FULL ARCHITECTURE                        │
└────────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════════
LAYER 1: INPUT - YOUTUBE LIVE STREAM
═══════════════════════════════════════════════════════════════════════════════════

    👥 VIEWERS watching YouTube Live
              ↓
    ┌─────────────────────────────────────┐
    │ YouTube Live Chat                   │
    │                                     │
    │ Viewer A: "$5 /walk forest"         │
    │ Viewer B: "$10 /craft sword"        │
    │ Viewer C: "$3 /open inventory"      │
    └─────────────┬───────────────────────┘
                  ↓
    ┌─────────────────────────────────────┐
    │ YouTube API Integration             │
    │ • Real-time chat monitoring         │
    │ • Donation detection                │
    │ • Message parsing                   │
    │ • Rate limiting & validation        │
    └─────────────┬───────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 2: COMMAND PROCESSING & VALIDATION
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Command Parser                                          │
    │ ✓ Extract command: /walk, /craft, /inventory, etc      │
    │ ✓ Validate syntax                                       │
    │ ✓ Extract parameters                                    │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Donation Validator                                      │
    │ ✓ Verify amount >= minimum threshold                   │
    │ ✓ Check user spam cooldown                             │
    │ ✓ Verify against blacklist                             │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Game State Manager                                      │
    │ ┌─────────────────────────────────────────────────┐     │
    │ │ Fetch from Database:                            │     │
    │ │  • Character state (position, inventory, HP)    │     │
    │ │  • Current location                             │     │
    │ │  • Available items & NPCs                        │     │
    │ │  • Character appearance hash                     │     │
    │ │  • Environment visual state                      │     │
    │ └─────────────────────────────────────────────────┘     │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Command Router                                          │
    │ ├─ /walk → Location Handler                            │
    │ ├─ /craft → Crafting Handler                           │
    │ ├─ /inventory → Inventory Handler                      │
    │ ├─ /take → Item Pickup Handler                         │
    │ ├─ /use → Item Use Handler                             │
    │ └─ /talk → NPC Interaction Handler                     │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 3A: VIDEO GENERATION - ACTION VIDEO
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Prompt Engineering System                               │
    │                                                         │
    │ Input Data:                                             │
    │  • Command: "/walk convenience_store"                  │
    │  • Current State: position, inventory, appearance      │
    │  • Target: destination location                        │
    │  • Camera: first-person POV                            │
    │  • Reference: character visual hash, environment ref   │
    │                                                         │
    │ Generated Prompt:                                       │
    │ ┌──────────────────────────────────────────────────┐   │
    │ │ "Generate a 20-second first-person video:        │   │
    │ │  Character walks from current location to         │   │
    │ │  convenience store. POV shows realistic movement  │   │
    │ │  and surroundings. Character appearance:          │   │
    │ │  [VISUAL_HASH]. High cinematic quality."          │   │
    │ └──────────────────────────────────────────────────┘   │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ 🎬 VIDEO GENERATION MODEL (Runway / Pika / Custom)     │
    │                                                         │
    │ ⏳ Processing: 15-25 seconds                           │
    │                                                         │
    │ Output: 20-30 second high-quality video                │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Post-Processing                                         │
    │ ✓ Extract last frame                                   │
    │ ✓ Save to cloud storage                                │
    │ ✓ Update character state in database                   │
    │ ✓ Log video generation metrics                         │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 3B: IDLE LOOP GENERATION
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Idle Loop Prompt Generator                              │
    │                                                         │
    │ Generated Prompt:                                       │
    │ ┌──────────────────────────────────────────────────┐   │
    │ │ "Generate 60-second LOOPABLE idle animation:     │   │
    │ │  Character standing in convenience store,        │   │
    │ │  waiting. Show subtle breathing, blinking,       │   │
    │ │  micro-movements. END FRAME = START FRAME        │   │
    │ │  (seamless loop). Appearance: [VISUAL_HASH].     │   │
    │ │  High quality, realistic."                       │   │
    │ └──────────────────────────────────────────────────┘   │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ 🎬 VIDEO GENERATION MODEL (Runway / Pika / Custom)     │
    │                                                         │
    │ ⏳ Processing: 15-20 seconds                           │
    │                                                         │
    │ Output: 60-second seamlessly loopable video            │
    │         (end frame matches start frame perfectly)      │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Idle Loop Cache Manager                                 │
    │ ✓ Cache video (location + character combo)             │
    │ ✓ Set TTL: 30 minutes                                  │
    │ ✓ LRU policy: keep top 10 locations                    │
    │ ✓ Reuse if character/location unchanged                │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 3C: AUTO-NARRATIVE ENGINE (LLM-Powered)
═══════════════════════════════════════════════════════════════════════════════════

    Idle Time Monitoring:
    No command for 60+ seconds? → TRIGGER AUTO-NARRATIVE

    ┌─────────────────────────────────────────────────────────┐
    │ Level Detector                                          │
    │ ├─ 60s idle → Level 1 (Subtle)                         │
    │ ├─ 120s idle → Level 2 (Moderate)                      │
    │ ├─ 240s idle → Level 3 (High)                          │
    │ └─ 420s+ idle → Level 4 (Maximum)                      │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ 🤖 LLM DECISION ENGINE (Claude 3.5 / GPT-4 / Llama)    │
    │                                                         │
    │ Input Context:                                          │
    │  • Current location                                     │
    │  • Character inventory & status                         │
    │  • Action history (last 10 actions)                     │
    │  • Idle level (1-4)                                     │
    │  • World state changes                                  │
    │  • Random narrative seed                                │
    │                                                         │
    │ LLM Response (2-3 seconds):                             │
    │ ┌──────────────────────────────────────────────────┐   │
    │ │ {                                                 │   │
    │ │   "action": "talk_to_npc",                       │   │
    │ │   "duration": 30,                                │   │
    │ │   "description": "Character talks to cashier",   │   │
    │ │   "narrative_reason": "Waiting for customer",    │   │
    │ │   "state_changes": {                             │   │
    │ │     "location": "convenience_store",             │   │
    │ │     "inventory_delta": {},                       │   │
    │ │     "xp_gain": 0,                                │   │
    │ │     "health_change": 0                           │   │
    │ │   }                                              │   │
    │ │ }                                                │   │
    │ └──────────────────────────────────────────────────┘   │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Auto-Narrative Prompt Generator                         │
    │                                                         │
    │ Convert LLM decision → Video prompt:                    │
    │ ┌──────────────────────────────────────────────────┐   │
    │ │ "Generate 30-second video: Character is in       │   │
    │ │  convenience store, starts talking to cashier.   │   │
    │ │  Show dialogue, facial expressions, hand         │   │
    │ │  gestures. Realistic conversation flow.          │   │
    │ │  Appearance: [VISUAL_HASH]. Quality."            │   │
    │ └──────────────────────────────────────────────────┘   │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ 🎬 VIDEO GENERATION MODEL (Runway / Pika / Custom)     │
    │                                                         │
    │ ⏳ Processing: 10-20 seconds                           │
    │                                                         │
    │ Output: 25-45 second auto-narrative video              │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 4: AUDIO GENERATION (SFX & AMBIENT SOUND)
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Audio Context Extractor                                 │
    │ • Action type: walking, crafting, talking, etc         │
    │ • Location atmosphere: shop, forest, cave, etc         │
    │ • Background ambience: traffic, wind, NPCs             │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ 🎙️ AUDIO GENERATION MODEL (ElevenLabs / Bark / Tortoise) │
    │                                                         │
    │ Options:                                                │
    │ • Character dialogue (if talking to NPCs)              │
    │ • Ambient sound effects (footsteps, wind, etc)         │
    │ • Background music (location-based)                    │
    │ • Sound design synthesis                               │
    │                                                         │
    │ ⏳ Processing: 5-10 seconds per 30s video              │
    │                                                         │
    │ Output: Audio track to sync with video                 │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 5: VIDEO + AUDIO SYNC & ENCODING
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Video-Audio Synchronizer                                │
    │ • Align generated video with generated audio            │
    │ • Add subtitle layers (if needed)                       │
    │ • Add donation/command overlay                          │
    │ • Add viewer name credits                               │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Video Encoder (FFmpeg)                                  │
    │ • Encode to streaming format (H.264/H.265)              │
    │ • Bitrate optimization                                  │
    │ • Add metadata                                          │
    │ • Quality check                                         │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 6: BROADCAST TO YOUTUBE LIVE
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Video Queue Manager                                     │
    │ • Queue videos in order                                 │
    │ • Handle timing between videos                          │
    │ • Manage smooth transitions                             │
    │ • Handle fallback/retry logic                           │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ RTMP Broadcaster                                        │
    │ • Stream to YouTube Live RTMP endpoint                  │
    │ • Maintain persistent connection                        │
    │ • Monitor stream health                                 │
    │ • Handle reconnection                                   │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ YouTube Live Stream                                     │
    │                                                         │
    │ 🎥 Screen showing:                                      │
    │  • Generated video playing (character doing action)     │
    │  • Live chat overlay (viewers sending donations)        │
    │  • Viewer name + donation amount + command              │
    │  • Current stats (character level, HP, inventory)       │
    │  • Countdown to next auto-narrative if idle             │
    │                                                         │
    │ 👥 Viewers watching in real-time                        │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 7: DATABASE & STATE MANAGEMENT
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ PostgreSQL Database                                     │
    │                                                         │
    │ Tables:                                                 │
    │ ├─ Characters                                           │
    │ │  └─ id, name, level, hp, mp, experience, appearance  │
    │ │                                                       │
    │ ├─ Character_Appearance                                │
    │ │  └─ visual_hash, embedding, reference_image, ...     │
    │ │                                                       │
    │ ├─ Inventory                                            │
    │ │  └─ character_id, item_id, quantity, equipped        │
    │ │                                                       │
    │ ├─ World_State                                          │
    │ │  └─ location_id, items_available, npcs_present, ...  │
    │ │                                                       │
    │ ├─ Locations                                            │
    │ │  └─ id, name, description, environment_visual_ref    │
    │ │                                                       │
    │ ├─ Transactions                                         │
    │ │  └─ id, viewer_id, amount, command, timestamp, ...   │
    │ │                                                       │
    │ ├─ Video_Cache                                          │
    │ │  └─ action_id, video_path, generation_time, ...      │
    │ │                                                       │
    │ ├─ Idle_Loop_Cache                                      │
    │ │  └─ location_id, character_id, video_path, ttl, ...  │
    │ │                                                       │
    │ └─ Action_History                                       │
    │    └─ session_id, timestamp, action, result, ...       │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Redis Cache                                             │
    │ • Character state (current session)                     │
    │ • Idle loop cache (fast retrieval)                      │
    │ • Recent actions (for narrative context)                │
    │ • Queue of pending commands                             │
    └─────────────┬───────────────────────────────────────────┘
                  ↓

═══════════════════════════════════════════════════════════════════════════════════
LAYER 8: ANALYTICS & MONITORING
═══════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────────────────────────┐
    │ Analytics Aggregator                                    │
    │ • Track total donations                                 │
    │ • Monitor most-requested commands                       │
    │ • Track viewer engagement by level                      │
    │ • Measure video generation success rate                 │
    │ • Monitor system performance                            │
    └─────────────┬───────────────────────────────────────────┘
                  ↓
    ┌─────────────────────────────────────────────────────────┐
    │ Dashboard                                               │
    │ • Real-time metrics                                     │
    │ • Donation history                                      │
    │ • Engagement graphs                                     │
    │ • System health status                                  │
    │ • Video generation queue                                │
    └──────────────────────────────────────────────────────────┘
```

---

## 🔄 **COMPLETE DATA FLOW TIMELINE**

```
SCENARIO: User donates $5 with "/craft sword" command at T+0

T+0s
  ↓
  [YouTube Chat] "$5 /craft sword" ← Viewer donation arrives
  ↓
  [Command Parser] Extract: command=/craft, param=sword
  ↓
  [Validator] Check: $5 ≥ $3 minimum ✓, user not spamming ✓
  ↓
  [Game State Manager] Get: current_location=convenience_store
                            inventory=[iron_ore, wood, coal]
                            character_appearance_hash=abc123...
                            environment_ref_image=url...

T+0.5s
  ↓
  [Crafting Handler] Verify: iron_ore ✓, wood ✓, coal ✓
                     All materials available for sword ✓
  ↓
  [Prompt Engineer] Create detailed prompt for action video:
    "First-person POV: Character in workshop crafting sword
     using hammer, anvil. Show metalwork process, sparks flying,
     realistic physics. Appearance: [abc123...]. High cinematic."

T+1s
  ↓
  [🎬 Video Generation API] Send prompt to Runway/Pika
  ↓
  ⏳ GENERATING VIDEO (15-25 seconds processing)
  ↓

T+20s
  ↓
  [Video Generation Complete] 30-second video received
    Shows: Character crafting sword with realistic detail
  ↓
  [Extract Last Frame] Save final frame (character with sword)
  ↓
  [Audio Generator] Generate SFX: hammer strikes, metalwork
  ↓
  [Audio Sync] Merge video + audio (5 seconds)
  ↓
  [Video Encoder] Convert to streaming format (3 seconds)

T+28s
  ↓
  [Transaction Logger] Record:
    {
      viewer_id: "user_123",
      amount: $5,
      command: "/craft sword",
      video_id: "video_001",
      timestamp: T+28s
    }
  ↓
  [Game State Update] Update database:
    character.inventory.remove(iron_ore)
    character.inventory.remove(wood)
    character.inventory.remove(coal)
    character.inventory.add(sword)
    character.xp += 50
    character.last_action = "crafted_sword"
  ↓
  [Idle Loop Generator] Create new idle video:
    Prompt: "60-second loopable idle in workshop.
             Character holding sword, breathing, shifting weight.
             Appearance: [abc123...]. Seamless loop."
  ↓
  ⏳ GENERATING IDLE LOOP (15-20 seconds processing)
  ↓

T+48s
  ↓
  [Idle Loop Generated] 60-second seamlessly loopable video
  ↓
  [Idle Cache] Save with TTL=30 minutes:
    {
      location_id: "workshop",
      character_id: "protagonist",
      video_path: "/cache/idle_workshop_60s.mp4",
      expires_at: T+1800s
    }

T+50s
  ↓
  [Video Queue] Add to broadcast queue:
    1. Action video (30s) - crafting sword
    2. Idle loop (60s) - standing in workshop
  ↓
  [RTMP Broadcaster] Start streaming

T+50-T+80s
  ↓
  🎥 BROADCAST: Action video plays
     👥 Viewers see character crafting sword
     💬 Chat: "Wow that's cool!" "Nice sword!" etc
  ↓

T+80-T+140s
  ↓
  🎥 BROADCAST: Idle loop plays (and repeats seamlessly)
     👥 Viewers see character standing with sword
     💬 Chat: New donations coming in...
  ↓

T+140s (60 seconds of idle)
  ↓
  [Idle Time Monitor] Detect: 60 seconds idle → LEVEL 1
  ↓
  [LLM Decision Engine] "Character has been waiting. What should they do?"
  ↓
  [🤖 LLM Response]
    {
      "action": "examine_sword",
      "duration": 20,
      "description": "Character admires the newly crafted sword",
      "level": 1
    }
  ↓
  [Auto-Narrative Prompt] Generate video prompt
  ↓
  [🎬 Video Generation] Create 20-second video
  ↓
  ⏳ Processing (10-15 seconds)
  ↓

T+155s
  ↓
  [Auto-Narrative Video Ready] 20-second video of character
     examining sword, admiring craftsmanship
  ↓
  [Queue] Add to broadcast queue

T+155-T+175s
  ↓
  🎥 BROADCAST: Auto-narrative video plays
     Character examining the sword they just made
  ↓
  [Game State] No state change (just animation)

T+175-T+235s
  ↓
  🎥 BROADCAST: Idle loop plays again (repeats seamlessly)

T+235s (60+ more seconds of idle)
  ↓
  [LLM Decision] "Still idle for 2 minutes. Escalate to Level 2"
  ↓
  [🤖 LLM Response]
    {
      "action": "go_to_blacksmith_shop",
      "duration": 35,
      "description": "Character travels to town blacksmith for inspection",
      "level": 2
    }
  ↓
  [Auto-Narrative Prompt] Generate travel sequence
  ↓
  [🎬 Video Generation] 35-second video
  ↓

T+270s
  ↓
  [Auto-Narrative Video Ready]
  ↓
  🎥 BROADCAST: Character traveling to blacksmith

T+305-T+365s
  ↓
  🎥 BROADCAST: New idle loop (blacksmith location)

... CONTINUES UNTIL USER SENDS NEW COMMAND ...

IF USER DONATES AT T+290s with "$7 /sell sword":
  ↓
  [Command Arrives] Immediately preempt current idle loop
  ↓
  [Command Processing] Process "/sell sword"
  ↓
  [Video Generation] Generate new action video
  ↓
  [Broadcast] Play new action → new idle → potentially new auto-narrative
```

---

## 🎬 MODEL RECOMMENDATIONS FOR WORLD ENGINE

---

## 🎥 **VIDEO GENERATION MODELS**

### **Option 1: Runway Gen-3 (RECOMMENDED) ⭐⭐⭐⭐⭐**

**Pros:**
- ✅ Highest quality output (cinematic, detailed)
- ✅ Best for first-person POV videos
- ✅ Excellent character consistency
- ✅ Superior physics simulation
- ✅ Up to 10 seconds per generation (can repeat)
- ✅ Seamless looping support
- ✅ Great for action sequences

**Cons:**
- ❌ Slower generation (~30-40 seconds per 10s video)
- ❌ Most expensive ($0.015-0.02 per 10 seconds)
- ❌ API quota limitations

**Cost per action video (30s):**
- 3-4 generations × $0.02 = **$0.06-0.08 per video**

**Best for:**
- Level 3-4 actions (epic scenes)
- High-quality crafting sequences
- Boss battles
- Cinematic story moments

**Recommendation: PRIMARY for major actions** ✅

---

### **Option 2: Pika 1.0 (GOOD BALANCE) ⭐⭐⭐⭐**

**Pros:**
- ✅ Faster generation (~15-20 seconds per video)
- ✅ Good quality for game-style animations
- ✅ Lower cost (~$0.005-0.01 per video)
- ✅ Better for repetitive idle animations
- ✅ Good character consistency
- ✅ Easier looping implementation

**Cons:**
- ❌ Slightly lower quality than Runway
- ❌ Less realistic physics
- ❌ More stylized appearance

**Cost per action video (30s):**
- Multiple generations × $0.008 = **$0.03-0.05 per video**

**Best for:**
- Level 1-2 actions (everyday activities)
- Idle loops (60-second seamless)
- Quick auto-narrative responses
- High-frequency generation

**Recommendation: SECONDARY for frequent actions** ✅

---

### **Option 3: Stable Diffusion + ControlNet (BUDGET) ⭐⭐⭐**

**Pros:**
- ✅ CHEAPEST option ($0.001-0.002 per video)
- ✅ Runs on YOUR RTX 6000 locally!
- ✅ No API quota limits
- ✅ Fast generation (~5-10 seconds)
- ✅ Unlimited usage

**Cons:**
- ❌ Lowest quality output
- ❌ Less consistent character appearance
- ❌ Needs fine-tuning for first-person POV
- ❌ Requires maintenance & monitoring
- ❌ More artifacts/glitches

**Cost:**
- **FREE** (except electricity)
- Your RunPod RTX 6000 handles it locally

**Best for:**
- Level 0 idle loops (use cached, low quality okay)
- Fallback when API fails
- Testing & development
- Cost-sensitive scenarios

**Recommendation: TERTIARY as fallback** ⚠️

---

### **Option 4: Hybrid Approach (BEST) 🚀**

```
Priority Queue:
1. User Command arrives ($$$)
   → Use Runway Gen-3 (highest quality)
   
2. Level 3-4 Auto-Narrative (epic moment)
   → Use Runway Gen-3 (spectacular)
   
3. Level 1-2 Auto-Narrative (everyday)
   → Use Pika 1.0 (faster, sufficient quality)
   
4. Idle Loop (looping, less detail)
   → Cache + Reuse OR Pika (cost-effective)
   
5. Fallback/API Down
   → Use local Stable Diffusion (always available)
```

**Cost per day (estimating 200 user commands):**
- 200 user actions × Runway ($0.07) = $14
- 200 auto-narrative L1-2 × Pika ($0.04) = $8
- **Total: ~$22/day for high-quality stream**

---

## 🎙️ **AUDIO/VOICE MODELS**

### **Option 1: ElevenLabs (RECOMMENDED) ⭐⭐⭐⭐⭐**

**Use for:** NPC dialogue, character voice acting

**Pros:**
- ✅ Most natural-sounding voices
- ✅ Excellent voice cloning (if you want consistent character voice)
- ✅ Multiple language support
- ✅ Emotion/style control
- ✅ Fast generation (~2-3 seconds per 30-second dialogue)

**Cons:**
- ❌ Pricing: ~$0.003 per 1000 characters

**Best for:**
- NPC conversations
- Character narration
- Dialogue sequences

**Recommendation: PRIMARY for dialogue** ✅

---

### **Option 2: Bark by Suno (GOOD + FREE) ⭐⭐⭐⭐**

**Use for:** Sound effects, ambient sounds, character reactions

**Pros:**
- ✅ FREE to use (open source)
- ✅ Runs locally on RTX 6000
- ✅ Good for sound effects & ambient
- ✅ Fun voice variety
- ✅ Controllable prosody

**Cons:**
- ❌ Less natural than ElevenLabs for long dialogue
- ❌ Requires fine-tuning
- ❌ Shorter generation window

**Best for:**
- Ambient background sounds
- Character reactions (gasps, laughs)
- Environmental audio
- Fallback when API costs too high

**Recommendation: SECONDARY for SFX** ✅

---

### **Option 3: Tortoise TTS (LOCAL + FREE) ⭐⭐⭐**

**Use for:** Ambient narration, background dialogue

**Pros:**
- ✅ 100% free (open source)
- ✅ Runs on your RTX 6000
- ✅ High quality voice cloning
- ✅ Good emotional range

**Cons:**
- ❌ Slower generation (~10-20 seconds)
- ❌ Needs GPU vram

**Best for:**
- Character monologues
- Narrative voiceover
- Background ambient dialogue

---

### **Hybrid Audio Strategy:**

```
Short Dialogue (NPC)
  → ElevenLabs (natural, fast)
  
Ambient/SFX (wind, footsteps, clinking)
  → Bark (free, local, sufficient quality)
  
Long Narration/Voiceover
  → Tortoise TTS (local, high quality)
  
Background Music
  → Stable Audio or local generation
```

**Cost per 30-second video:**
- If dialogue: ElevenLabs ~$0.01
- If SFX only: Bark (FREE)
- **Total: $0-0.01 per video for audio**

---

## 🤖 **LLM MODELS FOR AUTO-NARRATIVE**

### **Option 1: Claude 3.5 Sonnet (RECOMMENDED) ⭐⭐⭐⭐⭐**

**Pros:**
- ✅ Best reasoning ability (understand game context)
- ✅ Excellent narrative generation
- ✅ Understands character/world consistency
- ✅ Good at creative but sensible decisions
- ✅ Fast (2-3 seconds response time)
- ✅ Supports long context (100K tokens)
- ✅ Handles complex game state logic

**Cons:**
- ❌ Moderate cost (~$0.003 per 1000 input tokens)

**Best for:**
- Level decision-making (which action?)
- Narrative coherence
- Game logic validation
- Story continuity

**Cost per auto-narrative decision:**
- Input: ~500 tokens × $0.003/1K = $0.0015
- Output: ~100 tokens × $0.0006/1K = $0.00006
- **Total: ~$0.002 per decision**

**Recommendation: PRIMARY LLM** ✅

---

### **Option 2: GPT-4o (ALTERNATIVE) ⭐⭐⭐⭐**

**Pros:**
- ✅ Strong multimodal understanding
- ✅ Good narrative generation
- ✅ Can analyze reference images
- ✅ Reliable consistency

**Cons:**
- ❌ More expensive (~$0.005 per 1000 input tokens)
- ❌ Slightly slower

**Best for:**
- Complex scenario analysis
- Visual consistency checking
- If budget allows

---

### **Option 3: Mistral 7B or Llama 2 (BUDGET) ⭐⭐⭐**

**Pros:**
- ✅ FREE via Together AI (~$0.0002 per token)
- ✅ Can run locally on RTX 6000
- ✅ Unlimited usage
- ✅ No rate limiting

**Cons:**
- ❌ Lower quality narratives
- ❌ Less game logic understanding
- ❌ Needs prompt engineering
- ❌ Slower local inference

**Best for:**
- Development/testing
- Cost-sensitive approach
- Fallback when Claude/GPT-4 fail

---

### **Recommended LLM Strategy:**

```
LIVE STREAM (Real-time, consistent quality needed):
  → Claude 3.5 Sonnet (PRIMARY)
  → GPT-4o (BACKUP if Claude rate-limited)
  
DEVELOPMENT/TESTING:
  → Llama 2 via Together AI (free, fast iteration)
  
FALLBACK (If API down):
  → Local Llama 2 on RTX 6000

Cost per stream day:
  200 auto-narrative decisions × $0.002 = $0.40/day
  Total LLM cost: **~$12/month**
```

---

## 💰 **COMPLETE COST BREAKDOWN (per day)**

### **Streaming 4-6 hours/day with 100+ user commands**

```
Video Generation:
  ├─ User Actions (100 × Runway Gen-3): 100 × $0.07 = $7.00
  ├─ Auto-Narrative L1-2 (100 × Pika): 100 × $0.04 = $4.00
  └─ Idle Loop Caching (minimal regens): $0.50
  SUBTOTAL: ~$11.50/day

Audio Generation:
  ├─ NPC Dialogue (100 × ElevenLabs): 100 × $0.01 = $1.00
  ├─ SFX/Ambient (Bark LOCAL): FREE
  └─ Narration (Tortoise LOCAL): FREE
  SUBTOTAL: ~$1.00/day

LLM Decision Engine:
  ├─ Auto-narrative decisions (100 × Claude): 100 × $0.002 = $0.20
  └─ Fallback (Llama LOCAL): FREE
  SUBTOTAL: ~$0.20/day

TOTAL DAILY COST: ~$12.70/day
TOTAL MONTHLY COST: ~$380/month

RTX 6000 Usage (for local models):
  ├─ Idle Loops (Stable Diffusion): ~$5-10/month electricity
  ├─ Local LLM inference: ~$2-5/month electricity
  └─ Local Audio: ~$1-2/month electricity
  SUBTOTAL: ~$10/month electricity
```

---

## 🎯 **FINAL RECOMMENDATIONS**

### **TIER 1: QUALITY (Starting Recommended)**

| Component | Model | Reason |
|-----------|-------|--------|
| **Video** | Runway Gen-3 + Pika 1.0 | Cinematic + Fast |
| **Audio** | ElevenLabs + Bark | Natural dialogue + Free SFX |
| **LLM** | Claude 3.5 Sonnet | Best narrative |
| **Fallback** | Local Stable Diffusion | Always available |
| **Monthly Cost** | ~$380 | Quality stream |

---

### **TIER 2: BALANCED (Budget-Conscious)**

| Component | Model | Reason |
|-----------|-------|--------|
| **Video** | Pika 1.0 + Stable Diffusion | Faster + Cheaper |
| **Audio** | Bark + Tortoise | Local/Free |
| **LLM** | Llama 2 (Together AI) | Cheap |
| **Fallback** | Local everything | Always available |
| **Monthly Cost** | ~$50 | Budget stream |

---

### **TIER 3: HYBRID (RECOMMENDED FOR YOU) 🚀**

| Component | Model | Reason |
|-----------|-------|--------|
| **Video** | Runway (user actions) + Pika (auto) + SD (idle) | Quality where it matters |
| **Audio** | ElevenLabs (dialogue) + Bark (SFX) | Natural dialogue |
| **LLM** | Claude 3.5 Sonnet | Best narrative |
| **Local** | Stable Diffusion + Tortoise on RTX 6000 | Backup + idle loops |
| **Monthly Cost** | ~$380 | Professional quality |

**This is my recommendation** ✅

---

## 📊 **MODEL COMPARISON MATRIX**

```
┌────────────────────────────────────────────────────────────────┐
│ VIDEO GENERATION                                               │
├─────────────────────┬──────────┬─────────┬────────┬───────────┤
│ Model               │ Quality  │ Speed   │ Cost   │ Looping   │
├─────────────────────┼──────────┼─────────┼────────┼───────────┤
│ Runway Gen-3        │ ⭐⭐⭐⭐⭐ │ 30-40s  │ $0.07  │ Excellent │
│ Pika 1.0            │ ⭐⭐⭐⭐  │ 15-20s  │ $0.04  │ Good      │
│ Stable Diffusion    │ ⭐⭐⭐   │ 5-10s   │ FREE   │ Fair      │
└─────────────────────┴──────────┴─────────┴────────┴───────────┘

┌────────────────────────────────────────────────────────────────┐
│ AUDIO GENERATION                                               │
├─────────────────────┬──────────┬─────────┬────────┬───────────┤
│ Model               │ Quality  │ Speed   │ Cost   │ Best For  │
├─────────────────────┼──────────┼─────────┼────────┼───────────┤
│ ElevenLabs          │ ⭐⭐⭐⭐⭐ │ 2-3s    │ $0.01  │ Dialogue  │
│ Bark                │ ⭐⭐⭐⭐  │ 5-10s   │ FREE   │ SFX       │
│ Tortoise TTS        │ ⭐⭐⭐⭐  │ 10-20s  │ FREE   │ Narration │
└─────────────────────┴──────────┴─────────┴────────┴───────────┘

┌────────────────────────────────────────────────────────────────┐
│ LLM MODELS                                                     │
├─────────────────────┬──────────┬─────────┬────────┬───────────┤
│ Model               │ Quality  │ Speed   │ Cost   │ Best For  │
├─────────────────────┼──────────┼─────────┼────────┼───────────┤
│ Claude 3.5 Sonnet   │ ⭐⭐⭐⭐⭐ │ 2-3s    │ $0.002 │ Narrative │
│ GPT-4o              │ ⭐⭐⭐⭐⭐ │ 3-4s    │ $0.003 │ Complex   │
│ Llama 2             │ ⭐⭐⭐   │ 5-10s   │ FREE   │ Dev/Test  │
└─────────────────────┴──────────┴─────────┴────────┴───────────┘
```

---

## 🔧 **IMPLEMENTATION PRIORITY**

### **Phase 1: MVP (Weeks 1-2)**
```
✅ Video: Runway Gen-3 (user commands only)
✅ Audio: ElevenLabs (dialogue)
✅ LLM: Claude 3.5 Sonnet
✅ Idle: Static cached loop (no generation yet)
Cost: ~$7/day (actions only)
```

### **Phase 2: Auto-Narrative (Weeks 3-4)**
```
✅ Add: Pika for auto-narrative videos
✅ Add: Bark for SFX/ambient
✅ Add: Claude for Level 1-2 decisions
✅ Add: Idle loop generation (Pika or SD)
Cost: ~$15/day (with auto-narrative)
```

### **Phase 3: Optimization (Weeks 5+)**
```
✅ Add: Local Stable Diffusion (fallback + idle)
✅ Add: Local LLM inference (backup)
✅ Implement: Video caching (reduce API calls)
✅ Implement: Hybrid cloud+local architecture
Cost: ~$12/day (optimized)
```

---

**นี่คือการวิเคราะห์ที่สมบูรณ์ครับ! ตรงกับแนวคิดของคุณหรือต้องปรับแก้หรือจะเลือกรุ่นอื่นไหม?** 🚀
