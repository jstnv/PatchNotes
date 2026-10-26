# Live Store graph — source audit, 2026-10-18

Static source reconciliation, not a simulation or candidate adoption. 27 Primitive grants/reserve Features + 15 later Store Features = 42 IDs. All listed parents are live; parent order is authoritative. A granted/previously owned child does not retroactively require its parents.

| ID | Lane | Kind | First parent | Second parent | Cross-lane join |
|---|---|---|---|---|---|
| `text` | Visuals | Primitive | ROOT | — | no |
| `sprites` | Visuals | Primitive | `4_color_palette` | — | no |
| `4_color_palette` | Visuals | Primitive | ROOT | — | no |
| `scrolling` | Visuals | Primitive | `text` | — | no |
| `colored_text` | Visuals | later | `text` | — | no |
| `animated_sprites` | Visuals | later | `sprites` | — | no |
| `8_color_palette` | Visuals | later | `4_color_palette` | — | no |
| `multi_directional_scrolling` | Visuals | later | `scrolling` | — | no |
| `8_bit_sound` | Audio | Primitive | `sound_effects` | — | no |
| `8_bit_music` | Audio | Primitive | `music` | — | no |
| `sound_effects` | Audio | Primitive | ROOT | — | no |
| `music` | Audio | Primitive | ROOT | — | no |
| `recorded_sounds` | Audio | later | `8_bit_sound` | — | no |
| `16_bit_music` | Audio | later | `8_bit_music` | — | no |
| `keyboard_and_mouse` | Technology & Tools | Primitive | ROOT | — | no |
| `controller` | Technology & Tools | Primitive | ROOT | — | no |
| `menu_system` | Technology & Tools | Primitive | ROOT | — | no |
| `split_screen` | Technology & Tools | Primitive | ROOT | — | no |
| `save_files` | Technology & Tools | later | ROOT | — | no |
| `branching_nodes` | Technology & Tools | later | `save_files` | — | no |
| `local_leaderboards` | Gameplay | Primitive | `high_scores` | — | no |
| `score_system` | Gameplay | Primitive | ROOT | — | no |
| `lives_system` | Gameplay | Primitive | ROOT | — | no |
| `controls` | Gameplay | Primitive | ROOT | — | no |
| `enemies` | Gameplay | Primitive | `lives_system` | — | no |
| `power_ups` | Gameplay | Primitive | ROOT | — | no |
| `general_combat` | Gameplay | Primitive | `enemies` | — | no |
| `scripted_ai` | Gameplay | later | `enemies` | — | no |
| `difficulty_levels` | Gameplay | later | `turn_based_combat` | `scripted_ai` | no |
| `high_scores` | Gameplay | later | `score_system` | — | no |
| `turn_based_combat` | Gameplay | later | `general_combat` | — | no |
| `character_classes` | Gameplay | later | `general_combat` | `save_files` | yes |
| `simple_story` | Story & World | Primitive | ROOT | — | no |
| `dialogue` | Story & World | Primitive | `simple_story` | — | no |
| `character_backstories` | Story & World | Primitive | `simple_story` | — | no |
| `multiple_endings` | Story & World | Primitive | `branching_dialogue` | — | no |
| `levels` | Story & World | Primitive | ROOT | — | no |
| `maps` | Story & World | Primitive | `levels` | — | no |
| `exploration` | Story & World | Primitive | `levels` | — | no |
| `secrets` | Story & World | Primitive | `exploration` | — | no |
| `character_development` | Story & World | later | `character_backstories` | `save_files` | yes |
| `branching_dialogue` | Story & World | later | `dialogue` | `branching_nodes` | yes |

## Conditional acquisition routes from all eight v2 starts

Each cell is the missing IDs in legal parent-first order, stopping at actual granted ownership. After the initial window, admit and finish each listed Feature through paid FIFO Research before admitting its dependent child. Requires available cash at every step; this source review does not assert a funded playthrough, a fastest route, or victory eligibility. No speculative release/era gate is applied to current live Features.

| Specialty | Cross-lane Character Development milestone role | Difficulty Levels same-tree join |
|---|---|---|
| action | `simple_story` → `character_backstories` → `save_files` → `character_development` | `turn_based_combat` → `scripted_ai` → `difficulty_levels` |
| adventure | `save_files` → `character_development` | `turn_based_combat` → `enemies` → `scripted_ai` → `difficulty_levels` |
| role_playing | `save_files` → `character_development` | `turn_based_combat` → `enemies` → `scripted_ai` → `difficulty_levels` |
| strategy | `simple_story` → `character_backstories` → `save_files` → `character_development` | `turn_based_combat` → `scripted_ai` → `difficulty_levels` |
| simulation | `simple_story` → `character_backstories` → `save_files` → `character_development` | `general_combat` → `turn_based_combat` → `scripted_ai` → `difficulty_levels` |
| puzzle | `save_files` → `character_development` | `turn_based_combat` → `enemies` → `scripted_ai` → `difficulty_levels` |
| sports | `simple_story` → `character_backstories` → `save_files` → `character_development` | `general_combat` → `turn_based_combat` → `scripted_ai` → `difficulty_levels` |
| racing | `simple_story` → `character_backstories` → `save_files` → `character_development` | `general_combat` → `turn_based_combat` → `scripted_ai` → `difficulty_levels` |

Complete four-target route data: [graph-audit.json](graph-audit.json). These role examples do not select required Innovation milestones. Legacy v1 Strategy/Simulation/Sports retain Maps and lack Levels; Maps satisfies its own ownership test without retroactive Levels. A newly purchased Exploration or other Levels descendant still requires buying Levels.
