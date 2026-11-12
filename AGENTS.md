# FUSE ANYTHING! — Game Bible for Codex

You are a senior Roblox developer working on this game in **Luau** through the
**Roblox Studio MCP server** (already connected). Read this whole file before every task.
The place file `Fuse Anything.rbxl` in Studio is the source of truth; the `.luau` files in
this folder are mirrors — keep them in sync after every change.

---

## 0. Golden rules (follow always)

1. **Plan first.** Show a short checklist plan and WAIT for "go".
2. **Small steps.** One feature at a time. After each: playtest, read the console, fix every error,
   take a screenshot, `save_place`, update the matching `.luau` file and add a line to `CHANGELOG.md`.
3. **Server decides everything.** Coins, fusions, rewards, purchases, steals, World Firsts are validated on the server. Never trust the client. Rate-limit every remote.
4. **Mobile first.** Big tap targets, side bar + max 2 action buttons, test at phone size.
5. **Free only.** Free Roblox features and free open-source modules.
6. **Kid-safe.** Cartoon style, no blood/gore, no player-typed text (names are auto-generated).
7. **Performance.** Meshes under 20k triangles. Pool and clean up parts. StreamingEnabled is on.
8. **Monetization rules.** No paid random items. Every Robux purchase gives a known, direct result.
   If any Robux-bought thing ever has a random outcome (incl. luck boosts), show ALL outcomes with exact %
   odds before purchase and respect `PolicyService` `ArePaidRandomItemsRestricted`.
9. **Data safety.** All saves go through `DataService.Change` (UpdateAsync + retries, idempotent receipts).
   Never write the DataStore directly from other services.

---

## 1. Pitch

**Grab 2 random objects, throw them in the Fuse Pot, BECOME the creature, survive 60 seconds of chaos —
then show your creatures off in your Creature Lab, where they earn coins (and other players can try to steal them).**

Thumbnail: **"DUCK + TOASTER = ???"** (`Launch Art/`).

---

## 2. World layout (workspace)

- `FuseArena` — round arena (radius 64, center 0,0,0). Fuse Pot (AI mesh `PotMachine` over the old pot parts, `Brew` is the neon liquid),
  candy-material platforms (`LavaPlatform` safe spots with neon `Glow` rims, `StepHigh/StepLow`, `Bumper`), lobby `LabFloor` at (0,11,-100),
  lobby obby pads, VIP lounge (-43,18,-112). Out of bounds during rounds = >72 studs from center or y < -12.
- `LabWorld` — indoor toy-lab room (walls, ceiling lights, neon trims, glowing tanks, pipes). `Goo` is a deadly neon pit at y -11 (`GooKill` script).
- `CreatureLabs` — bridge + walkway behind the lobby and 8 plots (`Plot1..Plot8`, x = ±20, ±56, ±92, ±128, z = -170).
  Each plot: `Base`, `Edge`, `Pedestal1..6`, `CollectPad` (green), `LockButton` (pink), `OwnerSign`. **Server max players = 8** (one plot each).

## 3. Core round loop (RoundService)

Lobby (8s) → **Grab** (25s, touch 2 objects, Slap steals) → **Fuse** (5s, jump in pot, you become the creature) →
**Chaos** (60s random event: Rising Lava, Falling Fruit, Sumo Ring, Giant Fan Storm) → **Reward** (10s) → repeat.
Duo Fusion: two players opt in and share one creature (one drives, one fires the ability).

## 4. Fusion system

- 40 ingredients in `ReplicatedStorage.Shared.Ingredients` (Id, DisplayName, Tier, NameStart/NameEnd, Trait, Ability, Color, Shape, Model).
- Models: `ReplicatedStorage.Assets.<id>` = Model with one textured MeshPart `Core` (~3 studs), AI-generated. Old primitive versions are in `ServerStorage.OldAssets`.
- `Catalog` builds all ordered pairs: A+B ≠ B+A → 1,560 creatures. Body + Ability from A, Head + Trait from B. Name = A.NameStart .. B.NameEnd.
- `Recipes` = hand-made secret overrides (Rocket Potato, Toastuck Deluxe, Orbit Magnet).
- Mutations (free, random, never sold): Golden 2%, Giant 3%, Tiny 3%, Rainbow 0.5%.
- **Abilities (9):** Dash, Bounce, Ground Slam, Glide, Blast, Magnet, Spin, Blink, Rocket Flight (secret). Cooldowns in `Shared.Abilities`, logic in `AbilityService.Use`.
  To add one: add a branch in `AbilityService.Use`, a cooldown in `Abilities`, and assign it to ingredients.

## 5. Creature Lab (CreatureLabService) — the long-term loop

- Each player is assigned a plot on join. Creatures in their slots stand on tier-colored pedestals, bob (client `LabCreatureBob`), and earn coins.
- Income per minute by tier: Common 2, Rare 4, Epic 8, Legendary 16, Mythic 32. Mutation boost: Rainbow ×3, Golden ×2, Giant ×1.5, Tiny ×1.25.
  × Lab Power (1 + 0.25 × level). Offline income banked up to 6 hours (`LabCollect` timestamp). Collect on the green pad. 2× Lab Income pass doubles collections.
- Slots: Lab level 1–4 → 3–6 slots (upgrade cost Lab×100). **Lab Power**: endless upgrade, cost 150 × 1.55^level.
- New discoveries auto-place (empty slot first, else replace the weakest by rate). `Lab.Settle(saved)` must be called inside any Data.Change that changes slots/power, so income is banked at the old rate.
- **Stealing:** a visitor holds E (2s) on another player's creature → carries a copy above their head (slowed) → must reach THEIR OWN green pad within 30s.
  Success: thief gets the recipe in their Book (+ auto-place) and 20% of the victim's waiting coins (victim's `LabCollect` moves forward). Victim never loses the creature.
  Fail: owner gets within 5.5 studs (caught), timer runs out, or thief dies. Steal cooldown 45s.
  Protection: Lock button (60s force field, 3 min cooldown), and labs are auto-shielded while the owner is in a round.
- `GoLab` remote teleports a non-playing player to their plot (side bar "My Lab").

## 5b. Progression (ProgressionService + Hooks)

- `Hooks` is a tiny event hub. Events fired: `Fuse(player, recipe, mutation, isNew)` (RetentionService.Discover), `Survive(player)` (Retention.Win),
  `Collect(player, coins)` and `Steal(thief)` (CreatureLabService), `FirstFuse(player)` (RoundService.reveal). Listen with `Hooks.On`. Use it instead of new cross-requires.
- **Starter gift:** new players get `pineapple+strawberry` (Rare "Pineberry") placed in their Lab on first join (`StarterGift` flag).
- **Lucky first fusion:** while `FirstFusePending` (player attribute, from `FirstFuseDone` profile flag) the first real fusion is always Golden.
- **Daily Quests:** 3 per player per UTC day, picked deterministically from a 9-quest pool (`questsFor(userId, day)`); progress in `profile.Quests = {Day, P, C, Bonus}`.
  Rewards × (1 + 0.5 × Rebirths); +300 bonus for all three. `QuestReady` attribute makes the 📜 side bar button pulse. Claim via Progress remote action "Quest".
- **Rebirth:** needs Lab level 4 (6 slots) and 3000 × (Rebirths+1) coins. Resets Coins, Lab, LabPower; keeps Book and slots 1–3. Lab income × (1 + 0.5 × Rebirths)
  (inside `Lab.Multiplier`), round coins + 25% per rebirth (RoundService reward). ⭐ name tag over the head. Action "Rebirth".
- **Invites:** 👋 side bar button opens `SocialService:PromptGameInvite`. When a friend joins with `GetJoinData().ReferredByPlayerId` = an in-server player,
  both get 250 coins once per friend (`profile.Referrals`).
- **Client:** `Guide` (big step banner while Discoveries < 4), `Emotes` (victory dance after surviving + 💃/👋 buttons), lab creatures face/hop/wiggle when you're near.

## 6. UI (client)

- `UIController` (round HUD), `ProgressController` (menu window with tabs Book/Lab/Daily/Ranks/Codes/Shop; exposes `FuseProgress.OpenTab` BindableEvent and `MenuAllowed` attribute).
- `SideBar` — left icon buttons: 📖 Book, 🧪 My Lab, 🛒 Shop, 🎁 Daily (pulses when `DailyReady`), 🏆 Ranks, 🔊 Music (mute).
- `UIStyle` — restyles FuseHUD/FuseProgress/FuseSideBar: Fredoka font, thick outlines, gloss gradients, bounce on hover/press.
- `Juice` — "+N 🪙" coin popups and camera punch + "🧪 FUSED!" on transform. `Music` — APM cartoon playlist.

## 7. Retention

Fusion Book (+50 coins every 10 discoveries), World First (global, UpdateAsync), Daily Mystery Recipe + badge, daily login streak,
codes (`FUSE25`), leaderboards (Wins, Discoveries, World Firsts), Creature Lab offline income, stealing drama.

## 8. Monetization (`Shared.ShopCatalog`, IDs are 0 until created in Creator Hub)

Passes: 2× Round Coins, VIP, Third Hand (triple fusions), Book Hints, Candy Pot skin, Gold Burst FX, Mint Trail, **2× Lab Income**.
Products: Ingredient Pick voucher, Solo Revive, 1,000 Coins, 5,000 Coins. Coins buy Lab slots and Lab Power. Private servers: enable in Creator Hub.

## 9. Launch checklist (owner does these)

Publish → set max players 8 → create passes/products and paste IDs → create daily badge (`Config.DailyBadgeId`) →
upload thumbnail/icon → test purchases, saves, stealing with a friend, and phone play → go public.

## 10. Ideas backlog (next updates)

Weekly: +5 ingredients and 1 chaos event. Then: Rebirth (reset lab for permanent income multiplier), limited-time event creatures,
lab decorations (cosmetic coin sink), trading copies between friends, more secret recipes, seasonal Fuse Pot skins.
