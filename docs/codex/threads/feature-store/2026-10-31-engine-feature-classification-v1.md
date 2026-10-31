# Feature-by-Feature Engine Technology Classification — 2026-10-31

**RESEARCH / proposed taxonomy only.** All 54 Feature IDs in the live Primitive and later Store ledgers are listed, including four retired IDs retained for historical saves. This is a design judgment about each card's main role, not a recommendation to move its existing Scope or Core points. `A` = underlying engine technology; `B` = game feature/content; `C` = hybrid capability and player-facing feature. An `A` card still belongs to the current Feature Store until a separately approved migration exists. The UI lane is presentation metadata and is **not** the ledger's `department` field; `—` below means the ledger field is empty.

**Columns:** D/A phase = Design/Alpha. G/S/T/D Core = printed Graphics/Sound/Technology/Design; a `+` joins printed primary and secondary contributions, before hand synergy. `P1/P2/P3` are the current Primitive base acquisition prices for Scope 1/2/3: **$300/$450/$600**. Later Store prices are ledger `base_price_cents`, before familiarity and Resourceful effects. `—` in Era means no explicit `min_year`/`era_year` gate in that card's ledger; parents, cash and research still apply. Parent IDs are the **effective acquisition graph**, including Primitive parents supplied by `FeatureStoreCatalog`, and `&` means all named parents. A retired card is not offered for new future supply.

## Primitive Feature ledger — 27 IDs

| Feature (ID) | Dept | Phase | Scope | Printed Core | Acquisition parents | Base | Era/state | Class | Reason |
|---|---|---|---:|---|---|---:|---|:---:|---|
| Text (`text`) | — | D | 1 | G3 | — | P1 | — | A | Text renderer foundation |
| Sprites (`sprites`) | — | D | 2 | G7 | `4_color_palette` | P2 | — | A | Sprite rendering capability |
| 4-Color Palette (`4_color_palette`) | — | D | 1 | G2 | — | P1 | — | A | Color-depth foundation |
| 8-Bit Sound (`8_bit_sound`) | — | D | 2 | S5 | — | P2 | — | A | Audio playback foundation |
| 8-Bit Music (`8_bit_music`) | — | D | 1 | S2 | `music` | P1 | retired | A | Legacy audio format |
| Keyboard & Mouse (`keyboard_and_mouse`) | — | D | 1 | T3 | — | P1 | — | A | Input-device support |
| Controller (`controller`) | — | D | 1 | T3 | — | P1 | — | A | Input-device support |
| Scrolling (`scrolling`) | — | D | 2 | T7 | `text` | P2 | — | C | Camera/rendering plus level traversal |
| Menu System (`menu_system`) | — | D | 2 | T5 | — | P2 | — | C | Reusable UI plus visible menus |
| Local Leaderboards (`local_leaderboards`) | — | D | 1 | D2 | `high_scores` | P1 | — | B | Player-facing competitive scoring |
| Split Screen (`split_screen`) | — | D | 3 | D5+T4 | `branching_nodes` & `scrolling` | P3 | — | C | Display pipeline plus play mode |
| Score System (`score_system`) | — | D | 1 | D2 | — | P1 | — | B | Scoring rule |
| Lives System (`lives_system`) | — | D | 1 | D2 | — | P1 | — | B | Lives rule |
| Simple Story (`simple_story`) | story | A | 1 | D2 | — | P1 | — | B | Narrative content |
| Dialogue (`dialogue`) | story | A | 1 | D2 | `simple_story` | P1 | — | B | Spoken/written game content |
| Character Backstories (`character_backstories`) | story | A | 1 | D2 | `simple_story` | P1 | — | B | Character content |
| Multiple Endings (`multiple_endings`) | story | A | 2 | D3+T2 | `branching_dialogue` | P2 | — | B | Narrative outcomes |
| Controls (`controls`) | gameplay | A | 1 | T1+D1 | — | P1 | — | C | Input mapping plus player feel |
| Enemies (`enemies`) | gameplay | A | 2 | G2+T3 | `lives_system` | P2 | — | B | Opponent mechanics |
| Power-Ups (`power_ups`) | gameplay | A | 1 | S1+T1 | `categorized_scores` | P1 | — | B | Player boost mechanic |
| General Combat (`general_combat`) | gameplay | A | 2 | D5 | `enemies` | P2 | — | B | Combat rules |
| Levels (`levels`) | world_design | A | 2 | G3+D2 | — | P2 | — | B | Playable level content |
| Maps (`maps`) | world_design | A | 2 | G3+T2 | `levels` | P2 | — | B | Player-facing world maps |
| Exploration (`exploration`) | world_design | A | 1 | G1+S1 | `levels` | P1 | — | B | World navigation loop |
| Secrets (`secrets`) | world_design | A | 1 | S1+D1 | `exploration` | P1 | — | B | Discoverable content |
| Sound Effects (`sound_effects`) | audio | A | 1 | S2+T1 | — | P1 | retired | C | Legacy audio content/playback |
| Music (`music`) | audio | A | 2 | S7 | — | P2 | retired | C | Legacy soundtrack content/system |

## Later Store Feature ledger — 27 IDs

| Feature (ID) | Dept | Phase | Scope | Printed Core | Acquisition parents | Base | Era/state | Class | Reason |
|---|---|---|---:|---|---|---:|---|:---:|---|
| Colored Text (`colored_text`) | — | D | 1 | G2 | `text` & `4_color_palette` | $650 | — | A | Text-rendering upgrade |
| Animated Sprites (`animated_sprites`) | — | D | 2 | G5 | `sprites` | $1,700 | — | A | Animation/rendering support |
| 8-Color Palette (`8_color_palette`) | — | D | 1 | G2 | `4_color_palette` | $750 | — | A | Color-depth upgrade |
| Recorded Sounds (`recorded_sounds`) | — | D | 2 | S5 | `8_bit_sound` | $1,700 | — | C | Recording pipeline plus game audio assets |
| 16-Bit Music (`16_bit_music`) | — | D | 2 | S5 | `8_bit_music` | $1,700 | retired | A | Legacy audio-format upgrade |
| Save Files (`save_files`) | — | D | 2 | T5 | `menu_system` | $2,200 | — | C | Persistence tech plus player save feature |
| Scripted AI (`scripted_ai`) | — | D | 2 | T5 | `enemies` | $1,900 | — | C | Behavior tooling plus opponent behavior |
| Multi-Directional Scrolling (`multi_directional_scrolling`) | — | D | 2 | T5 | `scrolling` | $1,700 | — | C | Camera tech plus level navigation |
| Branching Nodes (`branching_nodes`) | — | D | 2 | D5 | `save_files` | $1,500 | — | C | Logic graph plus branching game structure |
| Difficulty Levels (`difficulty_levels`) | — | D | 1 | D2 | `turn_based_combat` & `scripted_ai` | $1,100 | — | B | Player-selectable challenge |
| High Scores (`high_scores`) | — | D | 1 | D2 | `score_system` | $650 | — | B | Player-visible scoring record |
| Turn-Based Combat (`turn_based_combat`) | gameplay | A | 2 | D5 | `general_combat` | $1,700 | — | B | Combat mode |
| Character Classes (`character_classes`) | gameplay | A | 2 | T2+D3 | `general_combat` & `save_files` | $1,700 | — | B | Character build mechanics |
| Character Development (`character_development`) | story | A | 2 | D5 | `character_backstories` & `save_files` | $1,700 | — | B | Character progression/narrative |
| Branching Dialogue (`branching_dialogue`) | story | A | 2 | T2+D3 | `dialogue` & `branching_nodes` | $1,700 | — | B | Player-facing conversation choices |
| Player Level Editor (`player_level_editor`) | — | D | 2 | T4+D1 | `save_files` & `levels` | $1,700 | ≥1983 | C | Authoring tool plus player feature |
| Ability-Gated Exploration (`ability_gated_exploration`) | world_design | A | 2 | G2+D3 | `exploration` & `power_ups` | $1,700 | ≥1986 + 1984 receipt | B | Gated world traversal |
| Switchable Protagonists (`switchable_protagonists`) | story | A | 2 | T3+D2 | `character_backstories` & `controls` | $1,700 | ≥1987 + 1984 receipt | B | Character-switch mechanic |
| Character Skill Checks (`character_skill_checks`) | story | A | 2 | D4+T1 | `character_development` & `exploration` | $1,700 | ≥1988 + 1984 receipt | B | Choice/stat mechanic |
| 16-Bit Sound (`16_bit_sound`) | — | D | 2 | S7 | `8_bit_sound` | $1,700 | — | A | Audio-fidelity upgrade; replaces future 8-Bit Sound supply |
| Main Theme (`main_theme`) | audio | A | 2 | S7 | `8_bit_sound` | $1,700 | — | B | Specific soundtrack content |
| Multiple Soundtracks (`multiple_soundtracks`) | — | D | 2 | S5+D2 | `main_theme` | $1,900 | — | C | Playback choice plus soundtrack design |
| Instrumental Sounds (`instrumental_sounds`) | audio | A | 2 | S7 | `recorded_sounds` | $1,900 | — | B | Produced audio content |
| Dynamic Sequencing (`dynamic_sequencing`) | — | D | 3 | S7+T2 | `multiple_soundtracks` & `instrumental_sounds` | $2,400 | — | C | Adaptive-audio tech plus musical design |
| Timer System (`timer_system`) | — | D | 1 | T2+D1 | — | $950 | — | B | Timed gameplay/scoring |
| Inventory System (`inventory_system`) | — | D | 2 | T3+D2 | — | $1,700 | — | B | Item management mechanic |
| Categorized Scores (`categorized_scores`) | — | D | 3 | D7+T2 | `timer_system` & `score_system` & `lives_system` | $2,400 | — | B | Scoring categories/rules |

## Inventory validation and reading cautions

- Primitive ledger: **27 Feature + 4 Pass + 9 Beta = 40 card IDs**. Store ledger: **27 Feature IDs**. Combined: 54 unique Feature IDs; four retired (`8_bit_music`, `music`, `sound_effects`, `16_bit_music`) and 50 active. The 24 active Primitive Features have 35 printed Scope. The 26 active later Store Features have 49 printed Scope; those sums are catalog inventories, **not** a single playable engine capacity or project requirement. `16_bit_sound` replaces `8_bit_sound` in future supply after acquisition.
- Primitive prices are computed from Scope for the opening reserve. Later Store rows use ledger base prices of $650–$2,400. Ordinary later research admits at half base price and completes one paid productive action for the other half, with parent-familiarity discount (10% per earned credit, capped 50%) on that due amount and a possible Resourceful saving. The table therefore reports **base**, not an always-payable final quote.
- Twelve later Store entries explicitly have `play_cost_cents: 0`; the other fifteen omit the field. A separate 2026-10-31 design decision selected trial nonzero play fees for the twelve, but those fees are **not implemented** in this source snapshot. Do not treat `TBD` as free or silently alter price/Scope.
- Store UI lanes are `Visuals`, `Audio`, `Technology & Tools`, `Gameplay`, and `Story & World`, defined separately from the ledger `department` field. A blank department does not mean a card lacks a UI lane or necessarily belongs to Engine Technology.
- Historical specialty grants and already frozen projects can own cards without satisfying their **current acquisition** parents. The parent table describes new acquisition, not a retroactive save validator. `min_year`/`era_year` exist only on the four tagged later Store rows shown above; an era receipt requires a distinct committed Studio release that met its frozen required Scope.
