# Avatar Progression & XP System — Brainstorm / Plan

## 1. The 5 Avatars (GLB)

| # | File | Suggested Name | Unlock Level |
|---|------|----------------|--------------|
| 1 | `assets/traveler.glb` | Traveler | 1 (starter) |
| 2 | `assets/Junior_traveler.glb` | Junior | 3 |
| 3 | `assets/adult_traveler.glb` | Adult Traveler | 6 |
| 4 | `assets/Old_elf_traveler.glb` | Old Elf | 10 |
| 5 | `assets/old_man_traveler.glb` | Old Man | 15 |

*(Levels are adjustable — pick thresholds that feel rewarding based on the XP curve)*

---

## 2. What Needs to Happen

### A. Avatar Unlock Data Layer

**Store unlocked avatars per user.**
- Add `_unlockedAvatarSrcs` (or similar) to `UserModel` or a new `AvatarUnlockProvider`.
- Persist via `SharedPreferences` (same pattern as badges/streaks).
- On level-up: check if new level grants a new avatar → auto-unlock.

**Hook into level-up flow:**
- In `UserModel.addXp()` (or in `RewardOrchestrator` when processing `LevelUp`), check `AvatarUnlockService.isUnlockLevel(level)`.
- If yes → mark avatar as unlocked → queue `AvatarUnlocked` reward event.

### B. UI: Avatar Selection / Showcase Screen

Build a new **"Avatar Showcase"** screen that replaces or supersedes `avatar_test_screen.dart`:

| Feature | Detail |
|---------|--------|
| 3D viewer | Keep `O3D.asset()` to render the selected GLB |
| Avatar list (scrollable) | Show all 5 avatars in a horizontal or vertical list |
| **Locked state** | Greyed-out thumbnail, lock icon overlay, dimmed |
| **Unlock preview** | Badge on locked card: "Unlocks at level 3" |
| **Current selection** | Highlighted border + checkmark |
| **Progress indicator** | Show user's current level, and which avatars are unlocked |
| **Save / Equip** | Button to equip the selected unlocked avatar |

### C. Avatar Equip State

- `AvatarProvider` (or new model) stores `_equippedAvatarSrc` (the GLB path).
- `AvatarWidget` picks up the equipped GLB path and renders it via `O3D.asset()`.
- The 3D avatar replaces (or augments) the existing PNG avatar system throughout the app.

### D. XP / Level Integration

The existing XP system is solid:

```
Level  1 → 2:   100 XP    (total:   100)
Level  2 → 3:   150 XP    (total:   250)
Level  3 → 4:   200 XP    (total:   450)   ← Junior unlocked
Level  4 → 5:   250 XP    (total:   700)
Level  5 → 6:   300 XP    (total:  1000)
Level  6 → 7:   350 XP    (total:  1350)   ← Adult Traveler unlocked
Level  7 → 8:   400 XP    (total:  1750)
Level  8 → 9:   450 XP    (total:  2200)
Level  9 → 10:  500 XP    (total:  2700)
Level 10 → 11:  550 XP    (total:  3250)   ← Old Elf unlocked
Level 11 → 12:  600 XP    (total:  3850)
Level 12 → 13:  650 XP    (total:  4500)
Level 13 → 14:  700 XP    (total:  5200)
Level 14 → 15:  750 XP    (total:  5950)
Level 15 → 16:  800 XP    (total:  6750)   ← Old Man unlocked
```

**No changes needed to `XpConfig` or the level curve** — just map unlock levels on top.

### E. Reward / Celebration on Unlock

- When an avatar unlocks, show a mini celebration overlay (similar to `BadgeUnlockOverlay` or `LevelUpOverlay`):
  - "New avatar unlocked!" 
  - Show the 3D model preview
  - "Equip now" button

---

## 3. Architecture Decisions

| Question | Proposal |
|----------|----------|
| **New provider?** | Create `AvatarProgressionProvider` (ChangeNotifier) that holds unlocked set + equipped avatar. Persist via SharedPreferences. |
| **Where to check unlock?** | In `UserModel.addXp()` after level change, or in `RewardOrchestrator`'s `LevelUp` handler. Latter is cleaner. |
| **Keep both PNG & GLB?** | Transition toward GLB as primary. Keep PNG as fallback. |
| **Replace avatar_test_screen?** | Yes — repurpose into the full "Avatar Showcase" screen with lock/unlock/equip. Route: `/app/avatar/showcase`. |
| **Achievement integration?** | The achievement system already has `avatarUnlocked` condition type. Wire it: unlocking avatar X triggers achievement check. |
| **Data model for unlock mapping** | Simple config class: `AvatarUnlockConfig { level; src; name; }`. |

---

## 4. Implementation Steps (Ordered)

1. **Create `AvatarUnlockConfig`** — data class mapping level → avatar src → display name
2. **Create `AvatarProgressionProvider`** — manages unlocked set, equipped avatar, persistence
3. **Integrate with `UserModel.addXp()`** — after level-up, check + unlock new avatars
4. **Add `AvatarUnlocked` event type** to `RewardOrchestrator` + overlay
5. **Rewrite `avatar_test_screen.dart`** — full showcase with lock states, unlock preview, equip
6. **Wire equipped avatar** into `AvatarWidget` / `TravelerViewer` for main app display
7. **Add avatar unlock achievements** to `Achievement.getDefaultAchievements()`
8. **Polish** — XP burst on unlock, profile screen shows equipped avatar

---

## 5. Open Questions

- Should locked avatars show a "preview" (greyed-out 3D render) or just a placeholder card?
- Should the starter avatar (Traveler) also be unlockable or given free at level 1?
- Do we keep the old PNG avatar selection screen or migrate fully to GLB?
- Single equip (one avatar at a time) or can the user pick different avatars for different contexts?
