## Data-only active-rival checkpoint. The player Studio payload and this world
## field are published in one CheckpointStore generation. Disk input supplies
## no classes, resource paths, constructors or executable Variant objects.
extends RefCounted
## Exact published and Phase3A worlds captured before this repair; full actor,
## history, annual ledger, finance and RNG validation still applies.
# Exact pre-repair editor source, verified from a legal Contract/Search save pair.
const CONTRACT_LATENCY_PREDECESSORS := [
	"bd7cbb9e1f604086a16588e7b6c79c4dc8f684e2c748c6b4c60b0cfaff050d30", # Verified pre-Studio-slide-layer source; gameplay and saved state unchanged.
	"35dfed1c2b25d7758b1eaa588e6e2c37a0c1da9ff0fc81436af010ce720cb2db", # Verified pre-Studio-button-motion source; gameplay and saved state unchanged.
	"1bddc849d257cff1394f76bf797d8b9100b69e14ef6c655f7b256ecba5567196", # Exact pre-Studio-note-visualizer source; gameplay and saved state unchanged.
	"35b2bd3ce642ac9d99865692a7a9b1bb85aabbff6c5588bc93d464a046778562", # Verified pre-Studio-notice presentation source; saved rules and state are unchanged.
	"870b788c4ab78798f55c130a02e795646e96841a79e9db28b1a6bc8580d2e800", # Verified pre-note-visualizer player and eight-rival checkpoint; gameplay state unchanged.
	"348e0d3ef90079bb8281466805bec9685c48e52b8f0e0bd9cdab43d8e5eda9f3", # Exact pre-panel-clearance presentation source; saved rules and state are unchanged.
	"97967757abe3de7a216351f7d75086775fc28a43a9b3ec3984e8e5894499ee8b", # Exact pre-typeface presentation source; saved rules and state are unchanged.
	"3d435180b9ae88d5d66aa1ee74b2aeebbcaac163a96b75577fe8f1472c6e6d84", # Exact pre-played-hand-panel presentation source; saved rules and state are unchanged.
	"6853bbd663c4505de6c1fff4d378f74f6fb94734edcaa3a631aacbd37d2c0e08", # Exact pre-Studio-panel presentation source; gameplay and saved state are unchanged.
	"b21a01145140d8845916cc17c4f73d643bfa3617ffc56e09f2fe5eff7a929419", # Exact pre-menu-note presentation source; gameplay and saved state are unchanged.
	"38d060f1b0d13bd62c4849365785df4eaf66e661ed3a41d233b436f29b22ee03", # Exact pre-exhausted-scope-prompt source; saved rules and state are unchanged.
	"4e8abae4d9f9720b6d585094a317aed924d54be813b0b19e283fb347259b60e7", # Exact pre-Studio-toggle source; saved rules and state are unchanged.
	"2329dfddf82421b727b974f1e08bcfd375f1c9f93c41a354c9043b9d35a171a8", # Exact pre-window-preference source; saved rules and state are unchanged.
	"32cd01836ce9840b38bc8aee2ff5bcb4fb600e7369b2fc827cdf1b64e38c8877", # Exact pre-trail presentation source; saved rules and state are unchanged.
	"5499674a2d7fbe43fb805816f5fffa9c14d08c2daa0278311a0c570666c166b3", # Published pre-header source; saved rules and state are unchanged.
	"8797ab6a761ea58d0702ee86d6e2f6943c990bc7c09c3c0b586833bdbb3a669c", # Exact pre-late-career-performance source; saved rules and state are unchanged.
	"cc2565a22815987d69aa388eae2811e0ca1cb9e66d0b1d657f088b1b2763f69f", # Exact pre-byte-budget source; saved rules and state are unchanged.
	"7867f5e1df6a0272ef155aac431b2ee4344c9a5368c947e153b96dddb9bbac6e", # Exact pre-node-budget source; saved rules and state are unchanged.
	"a9c205fa16d07f7b0fbc690ef927afeb04548d33439948b8ec1fe51eeb81a10f", # Exact pre-hidden-finance-refresh source; saved rules and state are unchanged.
	"b009937f6918808b85a3f3238dee8302f200f5da5619a5801b300d51d59c8942", # Exact pre-read-cache source; gameplay and saved state are unchanged.
	"6f6e4d21df0fe60d25917ffa014f576914bd75194a5119b04347c1e82e90189d", # Exact pre-parallel-load source; saved rules and data remain unchanged.
	"48802a7683eeb66de1e6a7e790c040933b2907605db27238e53253bde997e014", # Exact pre-local-snapshot-proof source; saved rules and data remain unchanged.
	"895333f906bade35dd1c5b7abdd593097d7834dac1d754623dbb420bf08a9894", # Exact pre-Market-render source; gameplay and saved state remain unchanged.
	"45e7136c8f79582903ea6ca846824bcc0681468737f14e4a791b30adb9d39c8b", # Exact pre-exit-warning source; gameplay and saved state remain unchanged.
	"7809cd4cbb823e6445adcf1cc2348a92110be7c517ef589a349e08d7b7261c22", # Exact pre-cache-cap source; validation and saved state remain unchanged.
	"d159801f53cb4ba0a0052985d3e62451cce920493f7e1600f467c70aa929d8c0", # Exact pre-background-title-inspection source; gameplay and saved state are unchanged.
	"4e08d682d5226b13dbab3598e5168b1b2c017fd95f5ece9461e75b2d190f7f1d", # Exact pre-parallel-save-encoding source; saved rules and state are unchanged.
	"5a3406596ed5436af3092ad709365f8d476df262966e466376614db592ab092b", # Exact pre-Store-refresh optimization; saved rules and state are unchanged.
	"21d185f0d7b82870eaa8ef3484cb99fbe2059e48b4df8c96b22f547cef00e5b4", # Exact pre-save-serialization optimization; state and rules remain unchanged.
	"fe5ac14f16e34f3634e9940aecabff24e155781d11f61d7f5b893155bd2d4c0f", # Exact pre-persistent-circuits source; gameplay and saved state are unchanged.
	"0a4fd9376cb933df378d93106d2f99e4216ea608eaa32a0f8239d3e4ae0e0a8a", # Exact pre-menu-surroundings presentation source; gameplay and saved state are unchanged.
	"38d7aaef796efb7613184979432c3cd274db6ac2d209e5ef7b640c9a62082d19", # Exact pre-challenge-notice presentation source; gameplay and saved state are unchanged.
	"b0615874b4094a781bde453c875d93542b07787fb4254b0190452509a8eef7e7", # Exact pre-engine-upgrade presentation source; gameplay and saved state are unchanged.
	"1eafc270a7aa34df1ae2a1fb892c68c32f17b8f6f25f6d3b6db3260d82ff26c3", # Exact pre-course-view switch; gameplay and saved state are unchanged.
	"4f63f0aa608ce7bf418a3cf780641a0f0187016e874c1f9ad6d79a6ecaa621b7", # Exact pre-priority teardown and artwork-warning fix; saved rules and data are unchanged.
	"90d668d693c9a21af4f6f573b7fc22743d9391315a253a7e299a46308425f00c", # Exact pre-Store-trails runtime; gameplay and saved state are unchanged.
	"885e752317658d9f7749c0caf9cde052910ac62cc475e0cdeb472ea8c20565ae", # Exact pre-lower-tree layout; gameplay and saved state are unchanged.
	"2e56c2a16fe44e056f10a78a1a38f48793c4d987102d9c76b1236982a3a1772a", # Exact pre-horizontal Store headings; gameplay and saved state are unchanged.
	"df60dc3e95c17266d01069846c79109a605dd824e3cd7f58e9946072657c1f83", # Exact pre-Store text-outline runtime; gameplay and saved state are unchanged.
	"5d104eb150215abcbbd532defc7c73fa64b4d7abd7b09bbee558e18853b2ce49", # Exact pre-Continue-invitation runtime; saved rules and data are unchanged.
	"7666325e2bd71d20a712643e4ab0c574dc3727c33a63c19379b6c1f40524c27e", # Exact pre-default-fullscreen runtime; gameplay and saved state are unchanged.
	"902004e8a4927a54816be76549b30e52db8fa46026b10984aaa8d1ad5ffb8a2d", # Exact pre-title-bar-entrance runtime; gameplay and saved state are unchanged.
	"016b0c2c46a922e280ad39e3028a3ba096d805e9c73d43cf4908c6f8127c1a00", # Exact pre-splice-alignment runtime; gameplay and saved state are unchanged.
	"df8a7ab0023dee8ba74f0cb885c145861b42c0fbaf9e2c5beb6dd4119bca578d", # Exact pre-parallel-splice runtime; gameplay and saved state are unchanged.
	"8e03071cf48338067c706d8a98afc1b1ba77f0ce811f1b5d5b0b3ed9d1b7a952", # Exact pre-bar-splice runtime; gameplay and saved state are unchanged.
	"863db0d2b0193e1cd6c9c20dc7c84c615f791e8be4fd8f458f47fb5cb543c5e2", # Exact pre-60fps-opening runtime; gameplay and saved state are unchanged.
	"0d9c2a28f9d8469410f709d9dc2a6a083f2568d80a7591bf6e47daf912955036", # Exact pre-title-bar-colors runtime; gameplay and saved state are unchanged.
	"0c5f90b428b714ced838e0535e27eca271c5d89f500856ce454b5b00d443c109", # Exact pre-early-Start runtime; gameplay and saved state are unchanged.
	"845467299d2b5fdb490fe09528beaffe8bf5780c188883877bcbace9a9dd14b9", # Exact pre-circuit-audio refinement; gameplay and saved state are unchanged.
	"7f088389c1a63ad1969c7295454b9767593ebc9c5438ce01beb61a4cb1001e63", # Exact pre-boot-clipping runtime; gameplay and saved state are unchanged.
	"26038e08cd2c407f852aaa59eb41dab7f3402f2781f946e382b7226e0ce31242", # Exact pre-title-wave refinement; gameplay and saved state are unchanged.
	"9b35aaa085c89b2685214bf1ecc7e5019697e6443b48269aac6eab7e116359fd", # Exact pre-logo-refinement runtime; gameplay and saved state are unchanged.
	"1f8cba039af0f8c72facae25b728cc6218fab73de548514d3d203900e45ee232", # Exact pre-menu-sequence runtime; gameplay and saved state are unchanged.
	"eba7f5b0cbf87ad431c94b755aec0cb9a4e9232df7a1f23b196b831e84148459", # Exact pre-Search & Fix source; existing player and rival data remain valid.
	"03e5a286aa14210a7c4f80d4f93b2aa9bf12d95675002daa7df2be2479e3a5b7", # Exact pre-boot UI/audio runtime; gameplay state and rules are unchanged.
	"a2c79f83a47ebbeb4f2bf6c4cc328c538e8eb85c538d56d9654c165c09c866fc",
	"03fabeee4439912bfad06e4126d5526696fafa33585483ff2e202319530de04a",
	"1323b8b1e504024f8fed2b874d71a8b26606df70831aa0a3ced73d37d1a4415f",
	"a073c94a054dd9c3080a98aa54f2b14b816a0779612209c96f9707865be9d7d7",
	"2a76082e51e9465efda444e12a9b91c79ae0b3000d8e63c8b1542f098f7bf042",
	"a16105547ae52b2f41e33908977f53ae6a230af6434fbd637902f084e5544afb",
	"b3bca0e2764772c746b82f4c76a8e087e540714fc4892f81395dd30b9a76e47f",
	"4f84dd8baa0d27022f04b5626629a430496d64fd2f3b84a6af45d22cda79f858", # Exact captured pre-grid UI runtime; current gameplay/finance/RNG unchanged.
	"6b3fa06073593241c439c080903dcada00360f952fe2b084ff591656080d6563", "b496434dc8095aefd67d498de3f9f98c2992abaa5d531bbd36ff7017ec9a2547", "5d27b061021aac5944f855395ab011b9f3de844e4145f17c857bdac88f2f01eb", "e4512254abfa3817c820f5f42923946f25ea75012aa7cb1dfa6358d18595cc75", "035345172f2253b32d3e4540f1b299bbdb389f8d4bec487862397a91465fe0c0", "e1720b670204ebb318ed54e92b68cf157b9d9466cd0a61882f92601957c2edf9", "07ce9e0e59fcd60944fc4a117890c0d9ce4a2f437fa4c3b9375693db5908455d", "dd3874909e76aa243eaa8f855230561956c7e18744cd0c2842cabb4035f8dc35", "b8c50f210b5a300f0de547d64cce1e3b4888aeea0f763ae201a4e36954ba8e9e", "a574d685e47db14036bd4ab445a688dd6166de6993026fef1ed94253b42ce3ef"]
const AWARDS_PRESENTATION_PREDECESSORS := ["ee16630a62508df8170e15b6dbc39a874a24d977792a42e0f3b56bd8bf10254f", "89b2459915e55f7d203780d6fc0d4b73218c3e44997b3a3111e33267f31080e1"]
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const AWARD_LEDGER_PREDECESSORS := ["303959a85af6268f88e1cd4b855e747838a25fad8779d85621a17f77a0b19253"]

const CAREER_PREDECESSORS := ["2b93740a7ca8a4eb1ed01946e63ea8cfa4e944f4aad1198f0e60f3a831225ae6"]
## Studio Management navigation only; exact preceding current-content world.
## 2026-10-31 hub/cash feedback and prospective free Contract recovery; exact prior saved data.
const STUDIO_MANAGEMENT_PREDECESSORS := ["2e5049b58267d27fbff11408109e37f43dea6b2cbd84fd570ffcc94acabe3015", "bf3dffde495d7149a9556091c4434c06af9db8b7c16ac27b6415378c0590b4f3"]
## Spawn-only pool correction: restore exact old ownership/projects unchanged.
const RIVAL_POOL_PREDECESSORS := ["33f44f0c61446daf6f464bee3c04f689a437d4b08704d2c3dbc65874778a1f27"]
## Read-only historical Market presentation; persisted rules/fields are exact.
const MARKET_HISTORY_PREDECESSORS := ["c4436b020d6580b0ddc79f40e18f085e43c742965e2bcfdce75104fe386255d1"]
## Exact immediately preceding unversioned-budget builds; active projects finish
## under explicit legacy rules, and all newly begun projects use2/K8.
const VERSIONED_BUDGET_PREDECESSORS := [
	"303959a85af6268f88e1cd4b855e747838a25fad8779d85621a17f77a0b19253", # Exact pre-flexible-hand award-bearing source; retain v1 counters and all saved results.
	"ef14cc34682dbe4ab3e739ea13396da9979c3a8efb9c057c7c8cfa25d78980f6", # Genuine pre-awards capture; closed optional receipt schema, unchanged prior rules.
	"5717e5e2573ea90a83ac8fe2bc87bbd3c6c10da3fe67524603ae57d3286cf54a", # Genuine calendar-v2 world; same rules/state, fixture/report closeout.
	"eea06deffab0895c9a80adacc7f6238cbef5cc313cd03d2f93f6b3d2e1603b3e", # Verified pre-calendar Public build; old raw profiles validate before migration.
	"46036810d92d20c22d3e08f554de308c1352673ce8d525764b007a0288370d33", # Exact pre-Public Studio/world; retain its v1 access and frozen projects.
	"52a411b66e7b0856cc0cf280cff26d95275c6d2529d59111f4fc7bc5e224bf72", # Before prospective stored-rent admission; existing values/history retained.
	"d7295bdcea8bd5093115b42ddba4913f4d7125ff6f697bf5945dc8c62fca0e09", "dabfdcc4484b44727f7cc0f772811346c13655c617ee0564562a110d723ef692", "b0f37941fa67561712612a41b31e2c7817ca7199156ce43883765324ced57bfa", "4a2cc02b5371a69f7b0c138b11eac6be863f1523975869d26895f725fb78fb0e", "4dfa8bc8f6520136df0757848f7931fc74e9baa48b373d67f004e796f16d0df0"]
const BUDGET_PREDECESSORS := ["ac5b36c205824b47262a192e83fc7b8c724314088a1fa7578279a774b1920e07", "5b253e0c999d11652782544266cdb222ad052cd01d49ab8969f9669b074a70c2"]
const Session := preload("res://scripts/simulation/campaign_session.gd")

## Studio header observer only; exact previous editor source with current content.
const STUDIO_GLOW_PREDECESSORS := ["962fd5777112cef637936e53749b009f02c4eef1b4837e4086d47078fc9335cd", "b5f2bb073310a6524c0294335dfd4e88d89b716a21b94f26e7aa83409c75dc17"]
## Research admission dialog presentation only; exact preceding current-content world.
const RESEARCH_CONFIRMATION_PREDECESSORS := ["56b304839cd4653d27baa368bcadb7f6cc83c8afc7ed4d813ef5d1c94766b60d"]
## Central roots/local-arrow presentation only; current rules and state stay exact.
## Exact pre-Audio editor catalog; preserve old player/rival state verbatim.
## Technology root spacing only; exact prior Audio world, same content rules.
## Exact preceding editor before additive Gameplay/three-parent acquisition.
const GAMEPLAY_RESTORATION_PREDECESSORS := ["39413580c9c5addc58d5ed5e3b60de49be3e2a77c2ebc6fa4bb65c4c8a2add9d"]
const TECH_ROW_PRESENTATION_PREDECESSORS := ["c15b025cf78073ccbed099f6d6df522279ead2a413de4636b8b37bd3a6714409"]
const AUDIO_PREDECESSOR_SOURCES := ["8f88b96a3f39b7de4c6d3af3e6886c6168bfd749cbc6beb6b45671e67e5eeeb6"]
const STORE_ROOT_PRESENTATION_PREDECESSORS := ["0c86786e04d95976d42933e18e1b37580bca4dba88d27818d4560376394997f6"]
## Exact latest pre-grid presentation; content pairs use the pinned old catalog.
const GRID_PREDECESSOR_SOURCES := ["a5c5d543474d24a1dc6ee2c901f4446380b1d0e572ddb414fe63e5d173439328"]
## Store prerequisite navigation only; exact preceding world and rules retained.
const STORE_NAVIGATION_PREDECESSORS := ["98e0b0926f13b8cf207ef375ff41bf2d8d9a82f6e7ac26d63aa447dc0fb50083"]

const Book:=preload("res://scripts/market/rival_standard_book.gd")
const Historical := preload("res://scripts/market/historical_standard_trial.gd")

## User-approved 2026-10-27: exact pre-Research-optimization editor only.
## Current player/rival content revisions and all ordinary validation still apply.
const RESEARCH_PERFORMANCE_PREDECESSORS := ["25dc0a8892df95b95b93690b5224d12e4242a97426ad5d4dbf4c98d42696af59"]
## Confirmation presentation only; exact quit/discard predecessor worlds restore.
const QUIT_PRESENTATION_PREDECESSORS := ["274023dedb8414b9b7ba852d470b36091a25fb954fde32f44325a5689109ac06", "0aaa98ba2e0eef306dc0c046d8732a2b3a5a80226649bc01729c3ff2d0ee9f7d", "e3b0d13708d22ce1755a99012dad6a6fbdc13cb5a4a28f47e6734d3a2a327421", "700d6a166649a7487ecc2abd87655435a69dfcdcaea4c5e6d09278abdc31bbee"]
## Title audio observer only; preceding saved world, ownership and RNG stay exact.
const STORE_ERA_PREDECESSORS := ["3b2a7b9b837a714768da133f90d6ce893fd9385bebd4ad2795b3acc10e9ad760"]
const MENU_VISUALIZER_PREDECESSORS := ["6e31125897228a4a80f175f449f0fdd52400079450a310b4ee6f40a71d063d4a"]
## Twelve-Scope grants apply to new Studios only; retain old ownership and RNG.
const STARTER_SCOPE_PREDECESSORS := ["3eb0f864ee07afc000f7ac087b5b1b7c2396d93e89056b53a84900b9e4954560"]
## Exact pre-optimization editor and shipped v0.03 sources. Rules, persisted
## fields and RNG are unchanged; every ordinary field check still applies.
const LATENCY_PREDECESSOR_SOURCES := ["a866e98020c0018f943ce8b98bbbd564b83d4ecd356bc6a4fd5cf66b0c483fa7", "617a97c83aabe2bba6613a8b4e5bddca7f1b9c4a974b8efb06e3595ad7334c94", "ce24d2a07703a664edd86574b2c678666f9307c5160710a62ce55603c7a74692", "a458650917031ee5dddd23c8a5b7c79986254f731f03a0113ddab4377aab0435"]
## Exact preceding Search editor/compiled presentation; saved fields unchanged.
const SEARCH_PRESENTATION_SOURCES := ["efc6ef13b947a784ad4db20d7220920498b3e43c28923c9965baafcf61016580","c1be4bc1ac2c8818d69b00e6e523e475382b0b6047e6e99a42891d7b8960304b","3eecb919ab1e100c930dfd792abeaca8066fe1f9977ed2e7785188f78e8b1fd2"]
## Exact editor sources before gradual pause audio/menu; saved fields unchanged.
const PAUSE_TRANSITION_SOURCES := [
	"3a8f41da6754dcf17269623586337daf39e1523263cbdb1aefcf0e8a9dba3ccc",
	"abbfa387743973cc6c727912041bee407ebeebe4fa370fd26751a1d9d87eace7",
]
## Temporary Insider hold/cap expansion is prospective; retain old world/RNG.
const INSIDER_HOLD_PREDECESSORS := ["f479c5b654d756972e5cb822756328ae3fae7eff2fdf66eb4e7badf967d20311"]
## Employee navigation only; retain the exact preceding saved world and RNG.
const EMPLOYEE_MENU_PREDECESSORS := ["71f86b840b0af8d425f8166caf169b853229e6c6ff3f4f32db22ecd7712ad019"]
## Exact pre-card-pop presentation; retained gameplay, world and RNG fields.
const CARD_POP_PREDECESSORS := ["a4d9fc318694ef143ea9d59147ae8c5e33a823d31d05a68b35d74203025b51c5"]
## Balanced 1.25 reward is prospective: retain historical scores and RNG.
const BALANCED_BOOST_PREDECESSORS := ["1c28c28f1f82b53cfb76f246f66562d476ffeb23d1ca152cd455108a693c5b4e"]
## Positive one-point Balanced allowance is prospective; saved state stays exact.
const BALANCED_SMALL_HAND_PREDECESSORS := ["9d30a157bfbcdec10be0de7120979ca282c137b23d327bb5b4e24fe2842c6cac"]
## Floating score presentation only; exact preceding player/world/RNG retained.
const SCORE_FLOAT_PREDECESSORS := ["8593779f9afa7deab4ca218fab64118864efe5d763ff088485f8d6ad43be7ab8", "02e62ac6d53d7b50c642ffb2a6e70fd64afcf01eec07dee4c919d4394773c3cc", "c3e80e9a7118d84803ef047dbf11e641030b3c6ebfcaeabc12dc6344f12d4c78", "797d2689941140d51cb8637fd2d03efa1f2011a6794a3803b65af68ac6213d4c", "6b46939ffd7efda8229858ecdbf9790cb9b12444180e7eea0db729ae22f82635", "f9854f69fe47880510e5c933b80aefbbc7f6469226328321f8ff55e33bdbe3b4", "4bc1caa6263cc6a965101c5231288465b97d4c1b76c2890d4e507441c58be0e0"]
## New grants change prospectively; existing world ownership/RNG is retained.
const EMPLOYEE_PRE_SEARCH_SOURCES := ["5dd56b5b84e8e72065c4394ca301f89694461a8a32b62486565fb1f9c49400bd","9216e53b16f5381247b2d4f6a7bfcfd168523cfc6ef5e9d0e11107280367bb31"]
const ROOT_FIRST_PREDECESSOR_SOURCES := [
	"874feab75c9d0221fc22dce1ac844a812f8a610bd58c12e203f9080c9c370392", # Pre-v3 editor.
	"57da40e29af0d492f12109030c79b549e64814faaeefba0528ce195dfc0baeac", # Actual Studio Fix EXE.
]
const USABILITY_PREDECESSOR_SOURCES := [
	"22f504d07fd73970dda3d8746e0cf23ca741afc1436acd5ff3f1630787933036",
	"6fffe610efd5a29e99f6b6359091f470f56f182814179328c91f6c8ffb5b92cc",
]
# Prerequisite link presentation only. Actual preceding editor/PCK worlds retain
# every field/RNG; admit only these identities with the current content revision.
const USABILITY_PRESENTATION_SOURCES := [
	"8216dc125219a21db6dd1b8971b6a6740c95e80ca472b4fc9bcb0d680d015d5f", # Before staged new-save invitation and neutral starter guidance.
	"3607c90b10a02bc26723b3e060618cda73f5755477f46fb32891f045c7a5a26e", # Actual Menu Slides EXE; saved gameplay unchanged.
	"224bb3f908474499968aace094e06d4e80e2ce9e48ac9fb2c26c2b2e297d21ef", # Before Container-aware title navigation motion.
	"aca924c0fd065ecf213fab534004e7f8afc32f7484a2be0db8fccfbe15b30c95", # Actual Menu Spacing EXE; persisted fields unchanged.
	"900512cd4167008a122720e252e6d2a1afd5215e0186b3f196279e4f7c9aeb87", # Before layout-safe automatic menu entrances.
	"91681dc365c033cede4a383c90299b2193f4c79886f8023ade9de30b1bc45e9c", # Actual Root First EXE; saved fields unchanged.
	"783a29291ac592ebc055867155cb640c481893c7ef900ebc36fe9adab56678ab", # Before refreshing Studio actions after the already committed first release.
	"0b0443b989c38ddd34b943846617d8bebdab3ee0cbe4e7b2dd6885f456202488", # Exact preceding Paper Icon EXE; unchanged stored gameplay fields.
	"900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c", # Before the shared folder Theme and retained setup navigation.
	"6800a07e9c01c2aa0476d8251afdfc3f0f3c61ad5989ff2c99bcd813d1c2ae65", # Before offering the optional tutorial on every save opening.
	"b8785b47ebb32a94fbf1dbbf682b015be4171259a8ce9631a2df9fc93f7a6205", # Before shared tutorial/live scoreboard layout.
	"8c8ef44726aae9dbd4a7967f8a750702a0ab5887f582b7880d65a77cb0f74944", # Before optional standalone tutorial.
	"57d64e0f6a00e04918e78445f0d46caf212a900c367d4b14d794d0a9c85e0d83", # Actual v0.02 embedded Windows build.
	"1a65c871916b3b42eef25df2684c5f2e7ef1087565563864c55f41158c39019b", # Before temporarily disabling the Studio Employees button.
	"6b39be120a228132e8cd78b6c00194fc95f734430ee485901d3479d20b61d315",
	"123a714caaa52bc8b9bf150620d7bbbf178263078a397e9d91373e6fff0b67c9",
]
const Development := preload("res://scripts/simulation/development_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Legacy := preload("res://scripts/legacy/legacy_world.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
# Verified 2026-10-17 export: live rival releases, active second projects and
# exact cold Continue at cycles7/9. All normal field/catalog checks still run.
const COMPATIBLE_V1_SOURCES := ["3e0d3958740f71149b3bb5b3e9f0b15b70cc6d71c96c6c03dd1f594d56a71c8f"]
# Exact pre-victory source: unchanged sessions/finance/RNG, v1 Founder codec
# retained. Full field, catalog, ownership and journal validation still applies.
const COMPATIBLE_FOUNDER_V1_SOURCES := ["0679720d9518de5ce8eb7f94ba7cd2970d001afad945b3a0e4156e5396de7040"]
# 2026-10-18 title-to-Studio audio timing and pause menu; the source fingerprint
# includes presentation scripts. Exact prior world/Founder v2 state is verified.
const COMPATIBLE_PRESENTATION_SOURCES := [
	"f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412", # Pre-Store-header UI; exact prior-world restore verified.
	"580bd1331cdc4bca578230005e3ca4f9cc91ead0b03b78be3238bdb7c9fc5150", # Explicit always-processing music transport; unchanged persisted fields.
	"38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e", # Pre-pause-music presentation; persisted world fields unchanged.
	"236a7e6184d14ff5b8f0f14fff01e61643f208e1318385c64cebea24f21a3ac3", # Pre-tooltip Pause routing; unchanged persisted world fields.
	"f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de",
	"200a5b089b34f95c31231bade1e3f6720b77b8ec87c9691e19b496b91098bfd6",
	"fd7e8a3bfe749b1c121b7515e150c35ea926f80f5511b2ba86d8ee5dceb8c867", # Pre-sales-HUD UI source.
	"ac944a5fafd1470251f51fafd9496b4c54542e6f51baaa963fd3c860cef5d2f5", # Pre-folder-guide UI source.
]
# Branch acquisition upgrade preserves saved sessions, ownership and admitted queues.
# Only future unowned purchases use the new gates; unknown sources still reject.
const COMPATIBLE_PRE_BRANCH_SOURCES := ["1365082d5d1d70e81749e19931215f74cc303678edbba35479db9676ce7415a3"]
# Contracts4 preserves already-completed results; new acceptances freeze trial challenges.
const COMPATIBLE_PRE_CHALLENGE_SOURCES := ["b3e0baf68815977cad07a3915045a85f53c18df341f3bf3bbe2d8bcc24c94d46"]
# Cardinal Store trees: retain actual saved ownership and admitted payments.
const COMPATIBLE_PRE_CONE_SOURCES := ["ea4268bd65ae08e2a5a344384eb82dbd1a2fd9f3ef710def8443a0ce578f910c", "81d4c3577b722bd2bbf552618ae3011cd9f8672f5ee83b3f4c0851c4aa750aed"]
# Actual pre-roster-v2 player and active rivals; hydrate never rebuilds grants.
const COMPATIBLE_PRE_ROSTER_SOURCES := ["9f321103092057b23ced7fc43ebefdffc1aa56e620b237dc734e17a451a1cbf7"]
# Exact pre-synergy-policy world. Saved hands/RNG/outcomes are preserved;
# only future rival decisions use the approved current-cohort trial selector.
const COMPATIBLE_PRE_SYNERGY_SOURCES := ["bf8d5157c91dd608456d66470d61e4927edb283401ef001c93b3a62d34b9aa6f"]
# Reverb-only pause presentation: exact preceding editor/compiled market1
# builds, with unchanged persisted rules. All current field checks still run.
const COMPATIBLE_MARKET_PRESENTATION_SOURCES := [
	"6a54626db35988186fd6a1fd7f47af9191dfb4421dc798720a0725032a75f8c1", # Audited Market/Finance build before first-refusal Esc routing; saved rules unchanged.
	"e024ceb5e6aa2d9f94cacd203e121b52ce6e70c70107a12da592176e7661e94e", # Shared-header predecessor; exact old-world fields verified for Market browser.
	"37cde6dfe643cc6c13f399eac460b2621e12ca92049feaef103e999c9cadcf6d", # First Market build; only stale-tip dismissal changed; legal campaign restore checked.
	"5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536",
	"d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72",
]
# Exact P1 preceding canonical source, tested with an unmodified whole-world
# payload. Paired content revisions are checked before ordinary validation.
const RELATIONSHIP_PREDECESSOR_SOURCE := "652f14adf47d7b305e40503e6f624ce1acfe8813fe72d31e249e8572930de14f"
# Audited pre-P1 release PCK identities differ from editor source fingerprints.
# Actual disk generations, never relabeled envelopes, exercise these migrations.
const RELATIONSHIP_PREDECESSOR_EXPORTS := [
	"30aceef1a405ac3c3b3db2cd03b35bae45d3d8959d0aacd23a0aacf5a0267453",
]
# Verified P1 editor generations and the actual audited P1 export. These pair
# only with the frozen P1 content revision; arbitrary source relabeling rejects.
const COMMISSION_PREDECESSOR_SOURCES := [
	"f790d724cb86a93efe8e6da471ba8adfb33b69fa0c217736ad81e15339404a0d",
	"026fcaf5c59c1a01cceeeea7262a8711705269488bb911afd27ca53214b47e3a",
	"568ed2c259d020443008d625c8279b23a49807e6bdfce486468222297b582631",
]
# Card entrance/tooltip presentation only: exact P2/P3 editor and audited PCK
# predecessors pair with current rules. Full world validation remains mandatory.
const COMPATIBLE_COMMISSION_PRESENTATION_SOURCES := [
	"a6766632c3c57c6abf5df0b4c981390c7f0dece678c6665d843bb84de8076cbe",
	"1be636f8f92822d4d693179a1bf9b5ed693a92ee2269133674d73ed22bacd113",
]
const SUPPORT_PREDECESSOR_SOURCES := [
	"d4065bc10fd797b32405c507044bc2349b339c2d2a5b2a5c414817d17bc398d9",
	"db23e0912d985cc67ddcc404447e5d3161589c2ff140fa1a315b0af62e7ed54e",
]
const MAX_RIVALS := 8
const PROJECT_INTS := ["_current_scope","_hidden_bugs","_known_bugs","_fixed_bugs","_marketing_output","_alpha_hidden_bugs_generated","_required_scope","_current_cycle"]
const PROJECT_FLOATS := ["_accumulated_bug_pressure","_accumulated_alpha_bug_pressure"]
const PROJECT_BOOLS := ["_has_design_bug_finalization","_was_perfect_production","_competitor_snapshot_revealed","_market_forecast_snapshot_revealed","_has_alpha_finalization","_has_beta_finalization"]
const PROJECT_IDS := ["_release_id","_competitor_snapshot_id","_market_forecast_snapshot_id","_genre_id","_theme_id"]
const PROJECT_ID_ARRAYS := ["_exhausted_beta_card_ids","_implemented_design_feature_ids","_unimplemented_design_feature_ids","_implemented_alpha_feature_ids","_unimplemented_alpha_feature_ids","_feature_supply_ids"]
const RESULT_FIELDS := ["_review_result","_awareness_result","_launch_market_context_result","_units_sold_result","_month_one_sales_revenue_result"]
const HAND_COMMON := ["priorities","candidate_ids","next_candidate_id","revision","active"]
const CareerPreviousWorld := preload("res://scripts/persistence/pre_rival_career/world.gd")
var error := ""

static func _project_schema() -> Dictionary:
	var schema := {"_base_name":"text","_core_scores":CheckpointSchema.map_of("uint","uint"),"_genre_ratios":CheckpointSchema.array_of("uint"),"_market_standards":CheckpointSchema.array_of("uint"),"_market_snapshot_id":"text","_market_details":CheckpointSchema.market_details()}
	for field: String in PROJECT_INTS: schema[field] = "uint"
	for field: String in PROJECT_FLOATS: schema[field] = "float"
	for field: String in PROJECT_BOOLS: schema[field] = "bool"
	for field: String in PROJECT_IDS: schema[field] = "id"
	for field: String in PROJECT_ID_ARRAYS: schema[field] = CheckpointSchema.array_of("id")
	var with_engine := schema.duplicate(true)
	with_engine._engine_id = "id"
	var frozen_engine:=with_engine.duplicate(true)
	frozen_engine._engine_capacity="uint"
	var with_skill:=frozen_engine.duplicate(true)
	with_skill._skill_pass_remainders=CheckpointSchema.map_of("id","uint")
	return CheckpointSchema.union_of([schema,with_engine,frozen_engine,with_skill])

static func _hand_schema(phase: int) -> Dictionary:
	var schema := {"priorities":CheckpointSchema.map_of("id" if phase==2 else "uint","uint"),"candidate_ids":CheckpointSchema.array_of("uint"),"candidate_cards":CheckpointSchema.array_of("id"),"next_candidate_id":"uint","revision":"uint","active":"bool"}
	if phase == 0:
		schema.available_features = CheckpointSchema.array_of("id")
		schema.exhausted = CheckpointSchema.map_of("id","bool")
		schema.finalization_requested = "bool"
	elif phase == 1:
		schema.available_features = CheckpointSchema.array_of("id")
		schema.exhausted = CheckpointSchema.map_of("id","bool")
		schema.pending_playtest = CheckpointSchema.array_of("uint")
	else:
		schema.injected_candidate_ids = CheckpointSchema.array_of("uint")
		schema.pending_corrective_pass_ids = CheckpointSchema.array_of("id")
		schema.launch_confirmation_pending = "bool"
	if phase==1:
		var protected_schema:=schema.duplicate(true)
		protected_schema.injected_candidate_ids=CheckpointSchema.array_of("uint")
		return CheckpointSchema.union_of([schema,protected_schema])
	return schema

static func _development_schema(phase: int) -> Dictionary:
	var legacy: Dictionary={"phase_index":"uint","sequence":"uint","awaiting_confirmation":"bool","finalized":"bool","project":_project_schema(),"hand":_hand_schema(phase)}
	var current:=legacy.duplicate(true)
	var old_budget: Dictionary={"version":"uint","origin":"text","printed":"uint","spent":"uint"}
	var skill_budget:=old_budget.duplicate(true);skill_budget.bonus_centi="uint"
	current.pass_budget=CheckpointSchema.union_of([old_budget,skill_budget])
	return CheckpointSchema.union_of([current,legacy])

static func _archive_schema() -> Dictionary:
	return {"id":"id","title":"text","year":"uint","genre":"id","theme":"id","review_tenths":"uint"}

static func _projected_archive_schema() -> Dictionary:
	var result := _archive_schema()
	result.release_cycle = "uint"
	result.cores = CheckpointSchema.array_of("uint")
	return result

static func _release_schema() -> Dictionary:
	return {"studio_id":"id","release_id":"id","release_cycle":"uint","title":"text","genre":"id","theme":"id","review_tenths":"uint"}

static func _book_source_schema() -> Dictionary:
	return {"studio_id":"text","release_id":"text","release_cycle":"uint","review_tenths":"uint","genre":"text","cores":CheckpointSchema.array_of("uint")}
static func _market_schema() -> Dictionary:
	var ordinary: Dictionary={"version":"uint","cycle_start":"uint","id":"text","facts":CheckpointSchema.array_of({"studio_id":"text","release_id":"text","release_cycle":"uint","genre":"text","theme":"text","review_tenths":"uint","cores_available":"bool","cores":CheckpointSchema.array_of("uint")})}
	var book: Dictionary=ordinary.duplicate(true)
	book.epoch_offset="uint";book.basis=CheckpointSchema.map_of("text",{"first":_book_source_schema(),"benchmarks":CheckpointSchema.array_of(_book_source_schema())})
	return CheckpointSchema.union_of([ordinary,book,CheckpointSchema.dict_with_calendar(ordinary),CheckpointSchema.dict_with_calendar(book)])

static func _origin_schema() -> Dictionary:
	return {"source_id":"text","content_revision":"text","cycle":"uint","active_projects":CheckpointSchema.map_of("id","id")}

func _expected_market_facts(market: Dictionary, player_payload: Dictionary, studio_rows: Array) -> Variant:
	var sources: Array=[{"id":str(player_payload.get("run_id","")),"run":player_payload.get("run",{}),"offset":0}]
	for studio: Variant in studio_rows:
		if not studio is Dictionary or not studio.get("run") is Dictionary: return null
		var offset_codec:=CheckpointCodec.new()
		var offset: Variant=offset_codec.integer(studio.get("offset","0"))
		if not offset_codec.error.is_empty(): return null
		sources.append({"id":str(studio.get("id","")),"run":studio.run.get("run",{}),"offset":offset})
	var facts: Array=[]
	for source: Dictionary in sources:
		var run: Variant=source.run
		if source.id.is_empty() or not run is Dictionary or not run.get("release_metadata") is Array or not run.get("released_games") is Array: return null
		var closed: Dictionary={}
		for closed_entry: Variant in run.get("closed_historical_ids",[]):
			if not closed_entry is Dictionary or not closed_entry.get("key") is String: return null
			closed[closed_entry.key]=true
		var sales_by_id: Dictionary={}
		for sale: Variant in run.released_games:
			if not sale is Dictionary or not sale.get("key") is String or not sale.get("value") is Dictionary or sales_by_id.has(sale.key): return null
			sales_by_id[sale.key]=sale.value
		for entry: Variant in run.release_metadata:
			if not entry is Dictionary or not entry.get("key") is String or not entry.get("value") is Dictionary or not sales_by_id.has(entry.key): return null
			if closed.has(entry.key): continue
			var meta: Dictionary=entry.value
			var codec:=CheckpointCodec.new()
			var release_cycle: Variant=codec.integer(meta.get("release_cycle"))
			if not codec.error.is_empty(): return null
			release_cycle-=int(source.offset)
			if release_cycle<0: return null
			if not Market.within_window(release_cycle,int(market.cycle_start),Market.calendar_for(market)):continue
			var review_tenths: Variant=codec.integer(sales_by_id[entry.key].get("review_tenths"))
			if not codec.error.is_empty() or not meta.get("review") is Dictionary: return null
			var core_values: Array=[]
			var raw_cores: Variant=meta.review.get("cores")
			var available: bool=raw_cores is Array and raw_cores.size()==4
			if available:
				for raw: Variant in raw_cores:
					var parsed: Variant=codec.integer(raw)
					if not codec.error.is_empty(): return null
					core_values.append(parsed)
			facts.append({"studio_id":source.id,"release_id":entry.key,"release_cycle":release_cycle,
				"genre":str(meta.get("genre","")),"theme":str(meta.get("theme","")),
				"review_tenths":review_tenths,"cores_available":available,"cores":core_values})
	facts.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if a.studio_id!=b.studio_id: return a.studio_id<b.studio_id
		return a.release_id<b.release_id)
	return facts

func _encode(value: Variant, schema: Variant) -> Variant:
	var codec := CheckpointCodec.new()
	var result: Variant = codec.encode(value,schema)
	if not codec.error.is_empty(): error = codec.error
	return result

func _decode(value: Variant, schema: Variant) -> Variant:
	var codec := CheckpointCodec.new()
	var result: Variant = codec.decode(value,schema)
	if not codec.error.is_empty(): error = codec.error
	return result

func _project_state(project: ProjectState) -> Dictionary:
	if project == null: return {}
	for field: String in RESULT_FIELDS:
		if project.get(field) != null: error = "Rival launch result was not settled"; return {}
	var result := {}
	for field: String in PROJECT_INTS + PROJECT_FLOATS + PROJECT_BOOLS + PROJECT_IDS + PROJECT_ID_ARRAYS + ["_base_name","_core_scores","_genre_ratios","_market_standards","_market_snapshot_id","_market_details"]:
		result[field] = project.get(field)
	result._engine_id = project.get_engine_id()
	result._engine_capacity=project._engine_capacity
	if not project._skill_pass_remainders.is_empty():result._skill_pass_remainders=project._skill_pass_remainders.duplicate(true)
	return result

func _hand_state(hand: RefCounted, phase: int) -> Dictionary:
	var candidate_cards: Array[StringName] = []
	for card: CardData in hand._candidate_cards: candidate_cards.append(card.id)
	var result := {"candidate_cards":candidate_cards}
	for field: String in HAND_COMMON: result[field] = hand.get(field)
	if phase < 2:
		result.available_features = hand._available_features.map(func(card: CardData) -> StringName: return card.id)
		result.exhausted = hand._exhausted_card_ids if phase == 0 else hand._exhausted_feature_ids
		if phase == 0: result.finalization_requested = hand.finalization_requested
		else:
			result.pending_playtest = hand._pending_playtest_categories
			if not hand.injected_candidate_ids.is_empty():result.injected_candidate_ids=hand.injected_candidate_ids
	else:
		result.injected_candidate_ids = hand.injected_candidate_ids
		result.pending_corrective_pass_ids = hand._pending_corrective_pass_ids
		result.launch_confirmation_pending = hand.launch_confirmation_pending
	return result

func _snapshot_development(session: RefCounted) -> Variant:
	if session.in_studio: return null
	var dev: RefCounted = session.development
	if dev == null or dev.phase_index < 0 or dev.phase_index > 2: error = "Invalid active rival phase"; return null
	var project := _project_state(dev.project)
	if not error.is_empty(): return null
	var state := {"phase_index":dev.phase_index,"sequence":dev.sequence,"awaiting_confirmation":dev.awaiting_confirmation,"finalized":dev.finalized,"project":project,"hand":_hand_state(dev.hand,dev.phase_index),"pass_budget":dev.pass_budget_state()}
	# Only plain detached values cross to the writer; no Project/Hand/Card objects.
	return state.duplicate(true)

func _capture_development(session: RefCounted) -> Variant:
	var state: Variant=_snapshot_development(session)
	return null if state==null else _encode(state,_development_schema(state.phase_index))

func snapshot(world: RivalWorld, studio_adapter: StudioCheckpoint = null) -> Dictionary:
	error = ""
	if world == null or world.player == null or world._busy or world.cycle != world.player.get_completed_run_cycles() or world.studios.is_empty() or world.studios.size() > MAX_RIVALS: error = "World is not at a save boundary"; return {}
	if not world.calendars_aligned():error="Rival/player calendar profiles differ";return {}
	var projected: bool=not world.calendar_offsets.is_empty()
	if not world.policy_states.is_empty() and world.policy_states.size()!=world.studios.size():error="Unknown career policy owner";return {}
	if projected and (world.calendar_offsets.size()!=world.studios.size() or world.player._calendar_start_year!=1980): error="Invalid projected world calendar"; return {}
	if not Market.valid(world.market_snapshot) or world.market_snapshot.cycle_start!=Clock.month_start(world.cycle,world.player.get_calendar_profile()): error = "Invalid committed market month"; return {}
	var rows: Array = []
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName,b: StringName) -> bool: return str(a) < str(b))
	var adapter := studio_adapter if studio_adapter != null else StudioCheckpoint.new()
	for id: StringName in ids:
		var session: RefCounted = world.studios[id]
		if session.run._rival_founder_profile=="rival-founder-active-1977-v2" and not world.policy_states.has(id):error="Missing career policy memory";return {}
		var offset: int=int(world.calendar_offsets.get(id,0))
		if (projected and (offset!=72 or session.run._historical_close_cycle!=72 or session.run._calendar_start_year!=1977)) or session.run.get_completed_run_cycles() != world.cycle+offset or session.contract != null: error = "Rival clock or Contract unavailable"; return {}
		var active_id: StringName = &"" if session.in_studio else session.project_id()
		var saved_run := adapter.snapshot(session.run,active_id)
		if saved_run.is_empty(): error = adapter.error; return {}
		var development: Variant = _snapshot_development(session)
		if not error.is_empty(): return {}
		var archive: Variant = world.historical_archive.get(id,[])
		if not archive is Array: error="Invalid rival archive"; return {}
		archive=archive.duplicate(true)
		if projected:
			for title: Dictionary in archive:
				for field: String in ["id","genre","theme"]: title[field]=StringName(title[field])
		if not error.is_empty(): return {}
		var row := {"id":str(id),"run":saved_run,"sequence":str(session.sequence),"development":development,"archive":archive}
		if projected: row["offset"] = str(offset)
		if not world.policy_states.is_empty():
			if not world.policy_states.has(id):error="Missing career policy state";return {}
			row["policy"]=world.policy_states[id].duplicate(true)
		rows.append(row)
	var history: Variant = world.detached_live_history()
	if not error.is_empty(): return {}
	var encoded_market: Variant = world.market_snapshot.duplicate(true)
	if not error.is_empty(): return {}
	var payload := {"schema_version":("3" if not world.policy_states.is_empty() else "2") if projected else "1","rng_algorithm":RunRandom.ALGORITHM,"cycle":str(world.cycle),"studios":rows,"history":history,"market":encoded_market}
	if not world.market_origin.is_empty():
		payload["market_origin"]=world.market_origin.duplicate(true)
		if not error.is_empty(): return {}
	if not world.legacy.is_empty():
		if not Legacy.valid(world.legacy,world): error="Invalid founder world"; return {}
		payload["legacy"]=Legacy.encode(world.legacy)
	# Run snapshots, encoded development/legacy and observation history already
	# own their values. Only the live archive/market/origin containers above need
	# copying; re-copying every detached rival ledger stalls the main thread.
	if world.annual_awards.is_empty() or not preload("res://scripts/awards/annual_awards_ledger.gd").valid(world,world.annual_awards): error="Invalid annual award provenance";return {}
	payload["annual_awards"]=world.annual_awards.duplicate(true)
	return payload

## Each worker owns only detached rival DTOs and its own codec/adapter. Results
## are joined and consumed in original row order; live sessions never cross.
class ActorEncodeWorker extends RefCounted:
	var items: Array=[]
	func encode() -> Dictionary:
		var adapter:=StudioCheckpoint.new()
		var result:Dictionary={}
		for item:Dictionary in items:
			var value:=adapter.encode_snapshot(item.run)
			result[item.index]={"value":value,"error":adapter.error}
		return result

func _encode_actor_runs_parallel(rows: Array) -> Dictionary:
	if rows.is_empty():return {}
	var count:=mini(rows.size(),mini(4,maxi(1,OS.get_processor_count()-1)))
	var jobs:Array[ActorEncodeWorker]=[]
	for i in count:jobs.append(ActorEncodeWorker.new())
	for i in rows.size():jobs[i%count].items.append({"index":i,"run":rows[i].run})
	var results:Dictionary={}
	if count==1:return jobs[0].encode()
	var threads:Array[Thread]=[]
	for job in jobs:
		var thread:=Thread.new()
		threads.append(thread)
		if thread.start(job.encode,Thread.PRIORITY_LOW)!=OK:results.merge(job.encode())
	for i in threads.size():
		if not threads[i].is_started():continue
		var result:Variant=threads[i].wait_to_finish()
		results.merge(result if result is Dictionary else jobs[i].encode())
	return results

func encode_snapshot(native: Dictionary, parallel_actors: bool=false) -> Dictionary:
	error = ""
	var payload := native.duplicate(true)
	var adapter := StudioCheckpoint.new()
	var actor_results:=_encode_actor_runs_parallel(payload.studios) if parallel_actors else {}
	for index in payload.studios.size():
		var row: Dictionary=payload.studios[index]
		if row.development!=null:
			row.development=_encode(row.development,_development_schema(int(row.development.phase_index)))
			if not error.is_empty():return {}
		if payload.schema_version=="3":
			row.policy=_encode(row.policy,_policy_schema())
			if not error.is_empty():return {}
		if parallel_actors:
			var encoded_actor: Dictionary=actor_results.get(index,{"value":{},"error":"Actor encoding failed"})
			row.run=encoded_actor.value
			if row.run.is_empty():error=encoded_actor.error;return {}
		else:
			row.run=adapter.encode_snapshot(row.run)
			if row.run.is_empty(): error=adapter.error; return {}
		row.archive=_encode(row.archive,CheckpointSchema.array_of(_projected_archive_schema() if payload.schema_version in ["2","3"] else _archive_schema()))
		if not error.is_empty(): return {}
	payload.history=_encode(payload.history,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	payload.market=_encode(payload.market,_market_schema())
	if not error.is_empty(): return {}
	if payload.has("market_origin"):
		payload.market_origin=_encode(payload.market_origin,_origin_schema())
		if not error.is_empty(): return {}
	if payload.has("annual_awards"):
		payload.annual_awards=_encode(payload.annual_awards,preload("res://scripts/awards/annual_awards_ledger.gd").schema())
		if not error.is_empty():return {}
	payload["source_identity"]=Replay.source_identity()
	return payload

func capture(world: RivalWorld) -> Dictionary:
	var native := snapshot(world)
	return {} if native.is_empty() else encode_snapshot(native)

## Detached current-format actors can be validated independently. The caller
## consumes the results in row order, preserving its existing error precedence.
class ActorValidationWorker extends RefCounted:
	var items: Array=[]
	func validate() -> Dictionary:
		var adapter:=StudioCheckpoint.new()
		var result: Dictionary={}
		for item: Dictionary in items:
			result[item.index]=adapter.validate_active_rival(item.payload) if item.active else adapter.validate(item.payload)
		return result

func _parallel_current_actor_validation(rows: Array) -> Dictionary:
	if rows.size()<2:return {}
	var adapter:=StudioCheckpoint.new()
	var revision:=adapter.revision()
	for row: Variant in rows:
		if not row is Dictionary or not row.get("run") is Dictionary or not row.has("development"):return {}
		var actor: Dictionary=row.run
		if actor.get("source_build")!=StudioCheckpoint.BUILD or actor.get("content_revision")!=revision or not actor.get("run") is Dictionary or not actor.run.has("calendar"):return {}
	var count:=mini(rows.size(),mini(4,maxi(1,OS.get_processor_count()-1)))
	if count<2:return {}
	var jobs:Array[ActorValidationWorker]=[]
	for i in count:jobs.append(ActorValidationWorker.new())
	for i in rows.size():jobs[i%count].items.append({"index":i,"payload":rows[i].run.duplicate(true),"active":rows[i].development!=null})
	var threads:Array[Thread]=[]
	var result:Dictionary={}
	for job in jobs:
		var thread:=Thread.new();threads.append(thread)
		if thread.start(job.validate,Thread.PRIORITY_LOW)!=OK:result.merge(job.validate())
	for i in threads.size():
		if not threads[i].is_started():continue
		var values:Variant=threads[i].wait_to_finish()
		result.merge(values if values is Dictionary else jobs[i].validate())
	return result

func _read_checked(payload: Dictionary, player_payload: Dictionary, captured_source_identity: String = "") -> Dictionary:
	if player_payload.get("run") is Dictionary and not player_payload.run.has("calendar_start_year"):
		var previous:=CareerPreviousWorld.new()
		# Code-owned exact prior runtime; never accept a source supplied by data.
		var native: Dictionary=previous._read(payload,player_payload,"673d2891707ec1092aff6d929a92c96ff38f3f8a620754f5de3d0d3ffc9325d1")
		if native.is_empty():error=previous.error;return {}
		# The preceding reader has verified the exact source/content pair. Retain
		# that generation provenance, rather than the adapter runtime identity.
		var legacy_origin: String=str(payload.get("source_identity",""))
		if not _known_budget_origin(legacy_origin):error="Unknown legacy Pass Budget source";return {}
		for row: Dictionary in native.rows:
			row.offset=0
			if not row.development.is_empty():row.development.pass_budget={"version":0,"origin":legacy_origin,"printed":0,"spent":0}
		return native

	error = ""
	var predecessor_source: Variant = payload.get("source_identity")
	var relationship_predecessor: bool = predecessor_source == RELATIONSHIP_PREDECESSOR_SOURCE or predecessor_source in RELATIONSHIP_PREDECESSOR_EXPORTS or predecessor_source in COMPATIBLE_MARKET_PRESENTATION_SOURCES
	var commission_predecessor: bool = predecessor_source in COMMISSION_PREDECESSOR_SOURCES
	var support_predecessor: bool = predecessor_source in SUPPORT_PREDECESSOR_SOURCES or predecessor_source in COMPATIBLE_COMMISSION_PRESENTATION_SOURCES
	var usability_predecessor: bool = predecessor_source in USABILITY_PREDECESSOR_SOURCES
	var current_source := Replay.source_identity() if captured_source_identity.is_empty() else captured_source_identity
	var grid_predecessor: bool = predecessor_source in GRID_PREDECESSOR_SOURCES+RESEARCH_PERFORMANCE_PREDECESSORS+QUIT_PRESENTATION_PREDECESSORS+STORE_NAVIGATION_PREDECESSORS
	var source_ok: bool = predecessor_source in CAREER_PREDECESSORS or predecessor_source in STUDIO_GLOW_PREDECESSORS or predecessor_source in RESEARCH_CONFIRMATION_PREDECESSORS or predecessor_source in GAMEPLAY_RESTORATION_PREDECESSORS or predecessor_source in TECH_ROW_PRESENTATION_PREDECESSORS or predecessor_source in AUDIO_PREDECESSOR_SOURCES or grid_predecessor or predecessor_source in STORE_ROOT_PRESENTATION_PREDECESSORS or predecessor_source==current_source or predecessor_source in RESEARCH_PERFORMANCE_PREDECESSORS or predecessor_source in QUIT_PRESENTATION_PREDECESSORS or predecessor_source in STORE_NAVIGATION_PREDECESSORS or predecessor_source in STORE_ERA_PREDECESSORS or predecessor_source in MENU_VISUALIZER_PREDECESSORS or predecessor_source in STARTER_SCOPE_PREDECESSORS or predecessor_source in SCORE_FLOAT_PREDECESSORS or predecessor_source in BALANCED_SMALL_HAND_PREDECESSORS or predecessor_source in BALANCED_BOOST_PREDECESSORS or predecessor_source in CARD_POP_PREDECESSORS or predecessor_source in EMPLOYEE_MENU_PREDECESSORS or predecessor_source in INSIDER_HOLD_PREDECESSORS or predecessor_source in PAUSE_TRANSITION_SOURCES or predecessor_source in LATENCY_PREDECESSOR_SOURCES or predecessor_source in SEARCH_PRESENTATION_SOURCES or predecessor_source in EMPLOYEE_PRE_SEARCH_SOURCES or predecessor_source in ROOT_FIRST_PREDECESSOR_SOURCES or predecessor_source in USABILITY_PRESENTATION_SOURCES or usability_predecessor or support_predecessor or relationship_predecessor or commission_predecessor
	var paired_revision: String = StudioCheckpoint.RelationshipPrevious.new().revision() if relationship_predecessor else StudioCheckpoint.new().pre_course_revision() if predecessor_source==current_source or predecessor_source in STUDIO_GLOW_PREDECESSORS or predecessor_source in RESEARCH_CONFIRMATION_PREDECESSORS or predecessor_source in RESEARCH_PERFORMANCE_PREDECESSORS or predecessor_source in QUIT_PRESENTATION_PREDECESSORS or predecessor_source in STORE_NAVIGATION_PREDECESSORS or predecessor_source in STORE_ROOT_PRESENTATION_PREDECESSORS else StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_ERA_RULES)
	if predecessor_source==current_source:paired_revision=StudioCheckpoint.new().revision()
	if predecessor_source in STUDIO_MANAGEMENT_PREDECESSORS+RIVAL_POOL_PREDECESSORS+MARKET_HISTORY_PREDECESSORS+BUDGET_PREDECESSORS+VERSIONED_BUDGET_PREDECESSORS+AWARDS_PRESENTATION_PREDECESSORS+CONTRACT_LATENCY_PREDECESSORS:
		source_ok=true;paired_revision=StudioCheckpoint.new().revision()
	if predecessor_source in CAREER_PREDECESSORS:paired_revision=StudioCheckpoint.new().pre_course_revision()
	if predecessor_source in AUDIO_PREDECESSOR_SOURCES+STORE_ROOT_PRESENTATION_PREDECESSORS: paired_revision=StudioCheckpoint.new().pre_audio_revision()
	if predecessor_source in GAMEPLAY_RESTORATION_PREDECESSORS+TECH_ROW_PRESENTATION_PREDECESSORS: paired_revision=StudioCheckpoint.new().pre_gameplay_revision()
	if grid_predecessor: paired_revision=StudioCheckpoint.new().pre_grid_revision()
	if predecessor_source!=current_source and predecessor_source in ROOT_FIRST_PREDECESSOR_SOURCES+USABILITY_PRESENTATION_SOURCES:
		paired_revision=StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_EMPLOYEE_RULES)
	if predecessor_source in EMPLOYEE_PRE_SEARCH_SOURCES:paired_revision=StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_SEARCH_RULES)
	if commission_predecessor: paired_revision = StudioCheckpoint.CommissionPrevious.new().revision()
	if support_predecessor: paired_revision = StudioCheckpoint.SupportPrevious.new().revision()
	if usability_predecessor: paired_revision = StudioCheckpoint.UsabilityPrevious.new().revision()
	if source_ok:
		if player_payload.get("content_revision") != paired_revision or not payload.get("studios") is Array:
			error = "Mismatched relationship source/content pair"; return {}
		for row: Variant in payload.studios:
			if not row is Dictionary or not row.get("run") is Dictionary or row.run.get("content_revision") != paired_revision:
				error = "Mismatched relationship Studio source/content pair"; return {}
	var projected: bool=payload.get("schema_version") in ["2","3"]
	var career: bool=payload.get("schema_version")=="3"
	if payload.size()!=7+int(payload.has("legacy"))+int(payload.has("market_origin"))+int(payload.has("annual_awards")) or payload.get("schema_version") not in ["1","2","3"] or not source_ok or payload.get("rng_algorithm")!=RunRandom.ALGORITHM or not payload.get("studios") is Array or not payload.get("history") is Array or not payload.get("market") is Dictionary:
		error = "INCOMPATIBLE_RIVAL_WORLD_SOURCE_OR_SCHEMA"
		return {}
	if (predecessor_source==current_source or predecessor_source in AWARD_LEDGER_PREDECESSORS+AWARDS_PRESENTATION_PREDECESSORS+CONTRACT_LATENCY_PREDECESSORS) and captured_source_identity.is_empty() and not payload.has("annual_awards"):
		error="Missing current annual world ledger";return {}
	var annual: Dictionary={}
	if payload.has("annual_awards"):
		if predecessor_source!=current_source and predecessor_source not in AWARD_LEDGER_PREDECESSORS+AWARDS_PRESENTATION_PREDECESSORS+CONTRACT_LATENCY_PREDECESSORS:error="Legacy source cannot manufacture awards";return {}
		var decoded_annual: Variant=_decode(payload.annual_awards,preload("res://scripts/awards/annual_awards_ledger.gd").schema())
		if not error.is_empty() or not decoded_annual is Dictionary:error="Malformed annual ledger";return {}
		annual=decoded_annual
	var legacy := {}
	if payload.has("legacy"):
		if not payload.legacy is Dictionary: error="Malformed founder world"; return {}
		legacy=Legacy.decode(payload.legacy)
		if legacy.is_empty(): error="Malformed founder world"; return {}
	var codec := CheckpointCodec.new()
	var cycle: Variant = codec.integer(payload.get("cycle"))
	if not codec.error.is_empty() or cycle != int(player_payload.run.completed_run_cycles): error = "Rival/player calendar mismatch"; return {}
	var origin := {}
	if payload.has("market_origin"):
		var decoded_origin: Variant=_decode(payload.market_origin,_origin_schema())
		if not error.is_empty() or not decoded_origin is Dictionary: error="Malformed market migration origin"; return {}
		origin=decoded_origin
		var migration: RefCounted=load("res://scripts/market/market_save_migration_trial.gd").new()
		if not migration.known_source(origin.source_id) or migration.SOURCE_REVISIONS[origin.source_id]!=origin.content_revision or origin.cycle>cycle: error="Unknown market migration origin"; return {}
	var market: Variant = _decode(payload.market,_market_schema())
	if not error.is_empty() or not Market.valid(market): error = "Invalid market snapshot"; return {}
	if market.cycle_start!=Clock.month_start(cycle,_payload_calendar(player_payload)): error = "Rival market calendar mismatch"; return {}
	if payload.studios.is_empty() or payload.studios.size()>MAX_RIVALS: error = "Invalid rival count"; return {}
	var seen := {}
	var all_archive_ids := {}
	var rows: Array = []
	var budget_definitions: Dictionary={}
	var adapter := StudioCheckpoint.new()
	# Writing already has a detached worker and usually warm actor proofs.
	# Older actors retain the original serial migration/validation route.
	var actor_results:=_parallel_current_actor_validation(payload.studios) if captured_source_identity.is_empty() else {}
	var actor_index:=-1
	for row: Variant in payload.studios:
		actor_index+=1
		if not row is Dictionary or row.size()!=((7 if career else 6) if projected else 5) or not row.get("id") is String or not row.get("run") is Dictionary or not row.get("sequence") is String or not row.has("development") or not row.get("archive") is Array or (projected and not row.get("offset") is String):
			error = "Malformed rival record"; return {}
		var id := StringName(row.id)
		if id.is_empty() or seen.has(id) or row.run.get("run_id")!=row.id or row.id==player_payload.run_id: error = "Duplicate or mismatched rival ID"; return {}
		seen[id]=true
		var sequence: Variant = codec.integer(row.sequence)
		if not codec.error.is_empty() or sequence > RunState.MAX_SIGNED_INT: error = "Invalid rival sequence"; return {}
		var offset: int=0
		if projected:
			var parsed_offset: Variant=codec.integer(row.offset)
			if not codec.error.is_empty() or parsed_offset!=72: error="Invalid projected rival offset"; return {}
			offset=parsed_offset
		var active := row.development != null
		var reason: String
		if actor_results.has(actor_index):reason=actor_results[actor_index]
		else:reason=adapter.validate_active_rival(row.run) if active else adapter.validate(row.run)
		if not reason.is_empty(): error = reason; return {}
		if int(row.run.run.completed_run_cycles) != cycle+offset: error = "Rival run cycle mismatch"; return {}
		var archive: Variant = _decode(row.archive,CheckpointSchema.array_of(_projected_archive_schema() if projected else _archive_schema()))
		if not error.is_empty(): return {}
		if archive.is_empty() and (legacy.is_empty() or row.id not in legacy.founder.career_studio_ids): error = "Missing frozen rival archive"; return {}
		var historical_ids := {}
		for title: Dictionary in archive:
			if title.id.is_empty() or all_archive_ids.has(title.id) or title.year>=(1980 if projected else RunState.START_YEAR) or title.review_tenths>100 or PrimitivePredevelopment.find_entry("genres",title.genre).is_empty() or PrimitivePredevelopment.find_entry("themes",title.theme).is_empty(): error = "Invalid rival archive"; return {}
			historical_ids[title.id] = true
			all_archive_ids[title.id] = true
		var dev := {}
		if active:
			if not row.development is Dictionary or not row.development.get("phase_index") is String: error = "Malformed active rival"; return {}
			var phase: Variant = codec.integer(row.development.phase_index)
			if not codec.error.is_empty() or phase>2: error = "Invalid rival phase"; return {}
			# These exact predecessors already froze engine identity and capacity.
			# Check before legacy schema decoding can supply default engine terms.
			if predecessor_source==current_source or predecessor_source in AWARDS_PRESENTATION_PREDECESSORS+CONTRACT_LATENCY_PREDECESSORS:
				var frozen: Variant=row.development.get("project")
				if not frozen is Dictionary or not frozen.has("_engine_id") or not frozen.has("_engine_capacity"):error="Missing current frozen engine state";return {}
			dev = _decode(row.development,_development_schema(phase))
			if not error.is_empty() or dev.is_empty(): return {}
			if not dev.has("pass_budget"):
				if predecessor_source==current_source or predecessor_source in VERSIONED_BUDGET_PREDECESSORS+AWARDS_PRESENTATION_PREDECESSORS+CONTRACT_LATENCY_PREDECESSORS:error="Missing current Pass Budget state";return {}
				dev.pass_budget={"version":0,"origin":str(predecessor_source),"printed":0,"spent":0}
			if budget_definitions.is_empty():
				for entry: Dictionary in FeatureStoreCatalog.starting_features()+FeatureStoreCatalog.entries():budget_definitions[StringName(entry.id)]=entry
			if not _valid_pass_budget(dev,budget_definitions):return {}
			if not Market.valid_details(dev.project._market_details,dev.project._genre_id) or dev.project._market_details.standards!=dev.project._market_standards or dev.project._market_details.snapshot_id!=dev.project._market_snapshot_id: error="Invalid frozen rival market target"; return {}
			if dev.project._release_id != StringName(row.run.active_project_id) or dev.project._release_id in historical_ids or dev.finalized or dev.project._has_beta_finalization: error = "Invalid active project boundary"; return {}
			var active_native := _decode_run(adapter,row.run,true)
			var engine_id: StringName=dev.project.get("_engine_id",&"legacy_engine")
			var engine_capacity: int=dev.project.get("_engine_capacity",0)
			var engine_state: Dictionary=active_native.run.get("engine_features",{})
			var skill_state: Dictionary=active_native.run.get("proprietary_engines",{}).get("engines",{}).get(engine_id,{})
			var remainders: Dictionary=dev.project.get("_skill_pass_remainders",{})
			for branch: StringName in remainders:
				if branch not in [&"graphics",&"sound"] or int(remainders[branch])<0 or int(remainders[branch])>9 or not skill_state.get("pass_effectiveness",{}).has(branch):error="Invalid Skill Tree Pass remainder";return {}
			if int(dev.pass_budget.get("bonus_centi",0))>0 and skill_state.get("pass_efficiency",{}).is_empty():error="Unowned Skill Tree budget bonus";return {}
			if engine_capacity==0 and engine_id!=&"legacy_engine" and preload("res://scripts/engines/engine_marketplace.gd").find(engine_id).is_empty():error="Missing proprietary capacity";return {}
			if not engine_state.is_empty():
				if not engine_state.engines.has(engine_id):error="Invalid frozen engine identity/capacity";return {}
				var bound: Dictionary=engine_state.engines[engine_id]
				var valid_capacity: bool=engine_capacity==bound.capacity
				if bound.origin==preload("res://scripts/engines/proprietary_engine_state.gd").ORIGIN:
					valid_capacity=preload("res://scripts/engines/proprietary_engine_state.gd").valid_frozen_capacity(engine_capacity,bound.capacity)
				if engine_capacity>0 and not valid_capacity:error="Invalid frozen engine identity/capacity";return {}
				for feature: StringName in dev.project._feature_supply_ids:
					if feature not in engine_state.engines[engine_id].implemented:error="Unimplemented frozen engine Feature";return {}

			if active_native.run.support_deals.has(dev.project._release_id):
				var terms: Dictionary = active_native.run.support_deals[dev.project._release_id]
				if terms.base_name != dev.project._base_name or terms.genre != dev.project._genre_id or terms.theme != dev.project._theme_id or terms.required_scope != dev.project._required_scope: error="Support/project mismatch"; return {}
			if active_native.run.commission_deals.has(dev.project._release_id):
				var terms: Dictionary = active_native.run.commission_deals[dev.project._release_id].terms
				if terms.base_name != dev.project._base_name or terms.genre != dev.project._genre_id or terms.theme != dev.project._theme_id or terms.required_scope != dev.project._required_scope: error="Commission/project mismatch"; return {}
			if dev.hand.candidate_ids.size()!=dev.hand.candidate_cards.size(): error = "Invalid rival hand"; return {}
		if projected and not _validate_projected_archive(adapter,row.run,archive,dev,offset): return {}
		var memory: Dictionary={}
		if career:
			memory=_decode(row.get("policy",{}),_policy_schema())
			if not error.is_empty() or memory.version!="career-v1" or memory.beta_hands>12 or memory.marketing_hands>12 or memory.loan_project< -1:error="Invalid career policy memory";return {}
			var released: Array=row.run.run.released_games
			var previous_project: String="" if released.is_empty() else str(released[-1].key)
			var active_project: String="" if dev.is_empty() else str(dev.project._release_id)
			if memory.project_id not in [previous_project,active_project] or (memory.loan_project!=-1 and (memory.loan_project<1 or memory.loan_project>released.size()+1)):error="Unproven career policy project";return {}
		rows.append({"id":id,"run":row.run,"sequence":sequence,"development":dev,"archive":archive,"offset":offset,"policy":memory})
	if career:
		var project_ids: Dictionary={}
		for row: Dictionary in rows:
			var native: Dictionary=_decode_run(adapter,row.run,not row.development.is_empty())
			for release_id: StringName in native.run.released_games:
				if project_ids.has(release_id):error="Duplicate owner release identity";return {}
				project_ids[release_id]=true
		for row: Dictionary in rows:
			if row.development.is_empty():continue
			var active_id: StringName=row.development.project._release_id
			if project_ids.has(active_id):error="Duplicate active owner project identity";return {}
			project_ids[active_id]=true
	var history: Variant = _decode(payload.history,CheckpointSchema.array_of(_release_schema()))
	if not error.is_empty(): return {}
	var expected_facts: Variant=_expected_market_facts(market,player_payload,payload.studios)
	if expected_facts==null or expected_facts!=market.facts: error="Market owner provenance mismatch"; return {}
	if not _validate_frozen_market(player_payload,payload.studios,rows,cycle,origin): return {}
	if Market.is_book(market) and not _book_matches_owners(market,rows):return {}

	return {"cycle":cycle,"rows":rows,"history":history,"legacy":legacy,"market":market,"market_origin":origin,"annual_awards":annual}

func _validate_projected_archive(adapter: StudioCheckpoint, encoded_run: Dictionary, archive: Array, development: Dictionary, offset: int) -> bool:
	var native: Dictionary=_decode_run(adapter,encoded_run,not development.is_empty())
	if native.is_empty(): error=adapter.error; return false
	var run: Dictionary=native.run
	if run.calendar_start_year!=1977 or run.historical_close_cycle!=offset or run.closed_historical_ids.size()!=archive.size(): error="Projected owner closure mismatch"; return false
	var first_cycle:=RunState.MAX_SIGNED_INT
	var first_id: StringName=&""
	for title: Dictionary in archive:
		var id: StringName=title.id
		if not run.closed_historical_ids.has(id) or not run.release_metadata.has(id) or not run.released_games.has(id): error="Unproven projected archive ID"; return false
		var meta: Dictionary=run.release_metadata[id]
		var sales: Dictionary=run.released_games[id]
		if title.year<1977 or title.release_cycle>=offset or title.release_cycle!=meta.release_cycle or title.year!=meta.release_year or title.title!=meta.release_title or title.genre!=meta.genre or title.theme!=meta.theme or title.review_tenths!=sales.review_tenths or title.cores!=meta.review.cores: error="Projected archive/owner mismatch"; return false
		if title.release_cycle<first_cycle: first_cycle=title.release_cycle; first_id=id
	if not development.is_empty() and str(development.project._market_details.snapshot_id).begins_with(Historical.PREFIX):
		var details: Dictionary=development.project._market_details
		var source: Dictionary=Historical.decoded_source(details.snapshot_id)
		if source.is_empty() or source.release_id!=str(first_id) or source.release_cycle!=first_cycle: error="Projected historical source missing"; return false
		var first: Dictionary=run.release_metadata[first_id]
		if source.studio_id!=str(run.bank_run_id) or source.genre!=str(first.genre) or source.cores!=first.review.cores or source.review_tenths!=run.released_games[first_id].review_tenths: error="Projected historical source mismatch"; return false
	return true

## All actual releases remain in owner ledgers, so past monthly inputs can be
## reconstructed without saving duplicate snapshots in every sales row.
func _validate_frozen_market(player_payload: Dictionary, encoded_rows: Array, decoded_rows: Array, cycle: int, origin: Dictionary) -> bool:
	var snapshots := {0:Market.neutral()}
	# These reconstructed snapshots are local and immutable throughout this read.
	var validated_snapshots: Dictionary={}
	var owners: Array=[{"id":player_payload.run_id,"run":player_payload,"development":{}}]
	owners.append_array(decoded_rows)
	var book_records: Array=[]
	for owner: Dictionary in owners:
		if int(owner.get("offset",0))!=72:continue
		var data: Dictionary=_decode_run(StudioCheckpoint.new(),owner.run,not owner.development.is_empty()).get("run",{})
		for id: StringName in data.get("released_games",{}):
			var m: Dictionary=data.release_metadata[id]
			if m.release_cycle>=72:continue
			book_records.append({"studio_id":str(owner.id),"release_id":str(id),"release_cycle":int(m.release_cycle),"review_tenths":int(data.released_games[id].review_tenths),"genre":str(m.genre),"cores":m.review.cores.duplicate()})
	var full_basis:=Book.build_records(book_records,72)
	if not full_basis.is_empty():snapshots[0]=Book.snapshot(full_basis,0,72)

	for owner: Dictionary in owners:
		var adapter:=StudioCheckpoint.new()
		var native: Dictionary=_decode_run(adapter,owner.run,not owner.development.is_empty())
		if native.is_empty(): error=adapter.error; return false
		var pending: Array=[]
		for id: StringName in native.run.released_games:
			var meta: Dictionary=native.run.release_metadata[id]
			for age: int in native.run.released_games[id].market_factors:
				var factor: Dictionary=native.run.released_games[id].market_factors[age]
				pending.append({"details":factor,"release":str(id),"genre":meta.genre,"theme":meta.theme,"earning_cycle":meta.release_cycle+Clock.month_end(age-1,native.run.released_games[id].get("calendar",{}))+1,"prelude":int(owner.get("offset",0))==72 and meta.release_cycle<72})
			if meta.review.has("market"): pending.append({"details":meta.review.market,"genre":meta.genre,"project_id":id,"prelude":int(owner.get("offset",0))==72 and meta.release_cycle<72})
		if not owner.development.is_empty(): pending.append({"details":owner.development.project._market_details,"genre":owner.development.project._genre_id,"project_id":owner.development.project._release_id})
		for item: Dictionary in pending:
			var d: Dictionary=item.details
			if item.get("prelude",false) and item.has("earning_cycle"):
				if item.earning_cycle>72 or d!=Market.neutral_factor():error="Invalid prelude neutral sales";return false
				continue
			if Book.is_details(d):
				var p:=Book.proof(d.snapshot_id)
				var begin_cycle: int=_historical_begin_cycle(native.run,StringName(item.get("project_id",&"")))
				if not Book.valid_details(d,item.genre):error="Invalid Book project proof";return false
				# Book epoch dates its historical inputs; the owner's offset dates
				# project work. The ordinary player's physical clock starts at0.
				var owner_offset: int=int(owner.get("offset",0))
				var freeze_clock: int=begin_cycle-(owner_offset if int(p.epoch_offset)==72 else 0)
				if begin_cycle<1 or freeze_clock<0 or p.owner!=str(owner.id) or (p.epoch_offset==0 and (owner_offset!=72 or begin_cycle>72)) or d.cycle_start!=Clock.month_start(freeze_clock,Clock.shift(native.run.get("calendar",{}),owner_offset if int(p.epoch_offset)==72 else 0)):error="Book project freeze boundary mismatch";return false
				var expected_basis: Dictionary=Book.build_records(book_records,int(d.cycle_start)+int(p.epoch_offset)).get(str(item.genre),{})
				var proof_context: Dictionary=d.duplicate(true)
				if p.has("calendar"):proof_context.calendar=p.calendar
				var facts: Array=[] if p.epoch_offset==0 else _expected_market_facts(proof_context,player_payload,encoded_rows)
				var expected: Dictionary=Book.details(Book.snapshot({str(item.genre):expected_basis} if not expected_basis.is_empty() else {},d.cycle_start,p.epoch_offset,facts,p.get("calendar",{})),str(owner.id),item.genre)
				if expected!=d:error="Book dated source provenance mismatch";return false
				continue
			if str(d.snapshot_id).begins_with(Historical.PREFIX):
				var begin_cycle: int=_historical_begin_cycle(native.run,StringName(item.get("project_id",&"")))
				if begin_cycle<1 or begin_cycle>72 or d.cycle_start!=begin_cycle-begin_cycle%2:error="Historical project freeze boundary mismatch";return false
				var historical: Dictionary=Historical.decoded_source(d.snapshot_id)
				var first: StringName=native.run.released_games.keys()[0] if not native.run.released_games.is_empty() else &""
				if int(owner.get("offset",0))!=72 or historical.is_empty() or not native.run.closed_historical_ids.has(first):error="Unproven prelude standard source";return false
				var meta: Dictionary=native.run.release_metadata[first]
				if historical.studio_id!=str(owner.id) or historical.release_id!=str(first) or historical.release_cycle!=meta.release_cycle or historical.genre!=str(meta.genre) or historical.cores!=meta.review.cores or historical.review_tenths!=native.run.released_games[first].review_tenths or not Market.valid_details(d,item.genre):error="Historical standard owner mismatch";return false
				continue
			if item.get("prelude",false):
				if Market.targets(Market.neutral(),str(owner.id),item.genre)!=d:error="Invalid first prelude benchmark";return false
				continue
			if item.has("earning_cycle"):item.earning_cycle-=int(owner.get("offset",0))
			if d.historical:
				if origin.is_empty() or d.snapshot_id!="pre-market-neutral:"+origin.source_id: error="Unproven historical market exemption"; return false
				if item.has("earning_cycle"):
					if item.earning_cycle>origin.cycle: error="Historical exemption after migration"; return false
				elif origin.active_projects.get(StringName(owner.id),&"")!=item.project_id: error="Unproven historical project"; return false
				continue
			if item.has("earning_cycle") and d.cycle_start!=Clock.month_start(item.earning_cycle,Clock.shift(native.run.get("calendar",{}),int(owner.get("offset",0)))): error="Market factor month mismatch"; return false
			if d.cycle_start>Clock.month_start(cycle,_payload_calendar(player_payload)): error="Future frozen market source"; return false
			if not snapshots.has(d.cycle_start):
				var dated: Dictionary=d.duplicate(true)
				if Market.calendar_source(str(d.snapshot_id)):dated.calendar=Clock.shift(native.run.get("calendar",{}),int(owner.get("offset",0)))
				var facts: Variant=_expected_market_facts(dated,player_payload,encoded_rows)
				if not facts is Array: error="Missing historical market facts"; return false
				snapshots[d.cycle_start]=Book.snapshot(full_basis,d.cycle_start,72,facts,Market.calendar_for(dated)) if not full_basis.is_empty() else Market.snapshot(d.cycle_start,facts,Market.calendar_for(dated))
			var snapshot: Dictionary=snapshots[d.cycle_start]
			var expected: Dictionary={}
			if item.has("release"):
				if not validated_snapshots.has(d.cycle_start):
					if not Market.valid(snapshot):error="Frozen market history/provenance mismatch";return false
					validated_snapshots[d.cycle_start]=true
				expected=Market._sales_factor_from_valid_snapshot(snapshot,str(owner.id),item.release,str(item.genre),str(item.theme))
			else:
				expected=Market.targets(snapshot,str(owner.id),item.genre)
			if expected!=d: error="Frozen market history/provenance mismatch"; return false
	return true

## The earliest productive development receipt is the authoritative Begin.
## This binds historical standards to actual pre-projection work, including
## the one project carried through January and later released normally.
func _historical_begin_cycle(run: Dictionary,project_id: StringName) -> int:
	if project_id.is_empty():return -1
	var first: int=RunState.MAX_SIGNED_INT
	for action: Dictionary in run.studio_finance.actions:
		if action.productive and action.kind==&"development" and action.source_id==project_id:first=mini(first,int(action.cycle))
	return -1 if first==RunState.MAX_SIGNED_INT else first

func validate(payload: Dictionary, player_payload: Dictionary) -> String:
	var decoded := _read(payload,player_payload)
	if not error.is_empty(): return error
	var adapter := StudioCheckpoint.new()
	var player := adapter.hydrate(player_payload)
	if player == null: error = adapter.error; return error
	var world := RivalWorld.new()
	world.player = player
	world.cycle = decoded.cycle
	world.legacy = decoded.legacy
	world.annual_awards = decoded.get("annual_awards",{}).duplicate(true)
	for row: Dictionary in decoded.rows:
		var run := adapter.hydrate(row.run,not row.development.is_empty())
		if run == null: error = adapter.error; return error
		var session := Session.new()
		session.run = run
		world.studios[row.id] = session
		if row.offset>0: world.calendar_offsets[row.id]=row.offset
	_check_history_and_legacy(world,decoded.history)
	if error.is_empty() and not _check_annual(world):error="Annual world provenance mismatch"
	return error

func _check_annual(world: RivalWorld) -> bool:
	if not world.annual_awards.is_empty():
		return preload("res://scripts/awards/annual_awards_ledger.gd").valid(world,world.annual_awards)
	# Older captures have no global result and cannot carry new owner awards.
	if world.player._fanbase.has("annual_awards"): return false
	for id: StringName in world.studios:
		if world.studios[id].run._fanbase.has("annual_awards"): return false
	return true

func _check_history_and_legacy(world: RivalWorld, history: Array) -> bool:
	var actual := {}
	for entry: Dictionary in history:
		if actual.has(entry.release_id) or (not world.studios.has(entry.studio_id) and (world.legacy.is_empty() or entry.studio_id!=world.player._bank_run_id)): error = "Invalid world release owner"; return false
		var run: RunState = world.player if entry.studio_id==world.player._bank_run_id else world.studios[entry.studio_id].run
		var meta := run.get_release_metadata(entry.release_id)
		var sales := run.get_released_game_sales(entry.release_id)
		var offset: int=int(world.calendar_offsets.get(entry.studio_id,0))
		if meta.is_empty() or sales.is_empty() or meta.release_cycle-offset!=entry.release_cycle or meta.release_title!=entry.title or meta.genre!=entry.genre or meta.theme!=entry.theme or sales.review_tenths!=entry.review_tenths: error = "World release provenance mismatch"; return false
		actual[entry.release_id] = entry
	for id: StringName in world.studios:
		for release_id: StringName in world.studios[id].run.get_released_game_ids():
			if world.studios[id].run._closed_historical_ids.has(release_id): continue
			if not actual.has(release_id) or actual[release_id].studio_id!=id: error = "Missing world release"; return false
	world.live_releases = actual
	if not world.legacy.is_empty() and not Legacy.valid(world.legacy,world): error = "Invalid restored founder world"; return false
	return true

func restore(payload: Dictionary, player_payload: Dictionary, player: RunState, catalog: RefCounted, captured_source_identity: String = "") -> RivalWorld:
	# Optional identity is a code-owned synchronous capture/write scope, never
	# an expected-source field taken from an untrusted checkpoint.
	var decoded := _read(payload,player_payload,captured_source_identity)
	if not error.is_empty() or player == null or catalog == null: return null
	var world := RivalWorld.new()
	world.player = player
	world.cycle = decoded.cycle
	world.market_snapshot = decoded.market
	world.market_origin = decoded.market_origin
	world.legacy = decoded.legacy
	world.annual_awards = decoded.get("annual_awards",{}).duplicate(true)
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): error = "Rival snapshots unavailable"; return null
	var adapter := StudioCheckpoint.new()
	for row: Dictionary in decoded.rows:
		if not row.get("policy",{}).is_empty():world.policy_states[row.id]=row.policy.duplicate(true)
		var active: bool = not row.development.is_empty()
		var run := adapter.hydrate(row.run,active)
		if run == null: error = adapter.error; return null
		var session := Session.new()
		session.run = run
		session.catalog = catalog
		session.snapshots = snapshots
		session.sequence = row.sequence
		session.in_studio = not active
		if active:
			var state: Dictionary = row.development
			var project := ProjectState.new(state.project._required_scope)
			project._engine_capacity=state.project.get("_engine_capacity",0)
			project._skill_pass_remainders=state.project.get("_skill_pass_remainders",{}).duplicate(true)
			project._pass_budget_version=state.pass_budget.version
			project._pass_budget_origin=state.pass_budget.origin
			for field: String in state.project:
				if field in PROJECT_ID_ARRAYS or field in ["_genre_ratios","_core_scores","_market_standards"]: continue
				project.set(field,state.project[field])
			var core_scores: Dictionary[ProjectState.CoreScore,int] = {}
			for category: int in state.project._core_scores: core_scores[category] = state.project._core_scores[category]
			project.set("_core_scores",core_scores)
			var ratios: Array[int] = []
			ratios.assign(state.project._genre_ratios)
			project.set("_genre_ratios",ratios)
			var market_standards: Array[int]=[]
			market_standards.assign(state.project._market_standards)
			project.set("_market_standards",market_standards)
			for field: String in PROJECT_ID_ARRAYS:
				var ids: Array[StringName] = []
				ids.assign(state.project[field])
				project.set(field,ids)
			var dev := Development.new()
			dev.project = project
			dev.run = run
			dev.catalog = catalog
			dev.snapshots = snapshots
			dev.phase_index = state.phase_index
			dev._create_phase(false)
			if state.phase_index<2:
				dev.hand._budget_printed=state.pass_budget.printed
				dev.hand._budget_spent=state.pass_budget.spent
				dev.hand._budget_bonus_centi=state.pass_budget.get("bonus_centi",0)
			dev.sequence = state.sequence
			dev.awaiting_confirmation = state.awaiting_confirmation
			dev.finalized = state.finalized
			var hand_state: Dictionary = state.hand
			for field: String in HAND_COMMON:
				if field != "candidate_ids": dev.hand.set(field,hand_state[field])
			var candidate_ids: Array[int] = []
			candidate_ids.assign(hand_state.candidate_ids)
			dev.hand.set("candidate_ids",candidate_ids)
			var candidate_cards: Array[CardData] = []
			for id: StringName in hand_state.candidate_cards:
				var card: CardData = catalog.get_card(id)
				if card == null: error = "Missing rival hand definition"; return null
				candidate_cards.append(card)
			dev.hand.set("_candidate_cards",candidate_cards)
			if dev.hand._candidate_cards.size()!=candidate_cards.size() or dev.hand.candidate_ids.size()!=candidate_ids.size(): error = "Rival hand restore mismatch"; return null
			if state.phase_index<2:
				var available_features: Array[CardData] = []
				for id: StringName in hand_state.available_features:
					var card: CardData = catalog.get_card(id)
					if card == null: error = "Missing rival Feature definition"; return null
					available_features.append(card)
				dev.hand.set("_available_features",available_features)
				if state.phase_index==0:
					var exhausted_cards: Dictionary[StringName,bool] = {}
					for id: StringName in hand_state.exhausted: exhausted_cards[id] = hand_state.exhausted[id]
					dev.hand.set("_exhausted_card_ids",exhausted_cards)
					dev.hand.finalization_requested = hand_state.finalization_requested
				else:
					var exhausted_features: Dictionary[StringName,bool] = {}
					for id: StringName in hand_state.exhausted: exhausted_features[id] = hand_state.exhausted[id]
					dev.hand.set("_exhausted_feature_ids",exhausted_features)
					var pending_playtest: Array[ProjectState.CoreScore] = []
					pending_playtest.assign(hand_state.pending_playtest)
					dev.hand.set("_pending_playtest_categories",pending_playtest)
					var injected: Array[int]=[]
					injected.assign(hand_state.get("injected_candidate_ids",[]))
					dev.hand.set("injected_candidate_ids",injected)
			else:
				var injected_ids: Array[int] = []
				injected_ids.assign(hand_state.injected_candidate_ids)
				dev.hand.set("injected_candidate_ids",injected_ids)
				var corrective_ids: Array[StringName] = []
				corrective_ids.assign(hand_state.pending_corrective_pass_ids)
				dev.hand.set("_pending_corrective_pass_ids",corrective_ids)
				dev.hand.launch_confirmation_pending = hand_state.launch_confirmation_pending
			session.development = dev
		world.studios[row.id] = session
		world.historical_archive[row.id] = row.archive
		if row.offset>0: world.calendar_offsets[row.id]=row.offset
	if not _check_history_and_legacy(world,decoded.history): return null
	if not _check_annual(world): error="Annual world provenance mismatch";return null
	if not world.calendars_aligned():error="Rival/player calendar profiles differ";return null
	world.bind_market_providers()
	return world

static func _policy_schema() -> Dictionary:
	return {"version":"text","project_id":"text","search_done":"bool","beta_hands":"uint","marketing_hands":"uint","loan_project":"int"}

func _book_matches_owners(market: Dictionary,rows: Array) -> bool:
	var records: Array=[]
	for row: Dictionary in rows:
		var data: Dictionary=_decode_run(StudioCheckpoint.new(),row.run,not row.development.is_empty()).get("run",{})
		for id: StringName in data.get("closed_historical_ids",{}):
			var m: Dictionary=data.release_metadata[id]
			records.append({"studio_id":str(row.id),"release_id":str(id),"release_cycle":int(m.release_cycle),"review_tenths":int(data.released_games[id].review_tenths),"genre":str(m.genre),"cores":m.review.cores.duplicate()})
	if market.epoch_offset!=72 or market.basis!=Book.build_records(records,72):error="Unproven opening standard book";return false
	return true

## Scoped read-only decode reuse. Never retained across reads or exposed as a
## mutable global DTO. Every semantic predicate still executes as before.
var _decode_scope:=false
var _decoded_runs: Dictionary={}
func _read(payload: Dictionary,player_payload: Dictionary,captured_source_identity: String="") -> Dictionary:
	_decoded_runs.clear();_decode_scope=true
	var result:=_read_checked(payload,player_payload,captured_source_identity)
	_decode_scope=false;_decoded_runs.clear();return result
func _decode_run(adapter: StudioCheckpoint,payload: Dictionary,active: bool=false) -> Dictionary:
	if not _decode_scope:return adapter._decode_payload(payload,active)
	var key:=var_to_bytes([payload,active])
	if _decoded_runs.has(key):adapter.error="";return _decoded_runs[key]
	var native:=adapter._decode_payload(payload,active)
	if not native.is_empty():_decoded_runs[key]=native
	return native

static func _known_budget_origin(source: String) -> bool:
	if source in BUDGET_PREDECESSORS+STUDIO_MANAGEMENT_PREDECESSORS+RIVAL_POOL_PREDECESSORS+MARKET_HISTORY_PREDECESSORS:return true
	# The two certified 1977 openings are admitted byte-for-byte by the
	# opening loader; their active projects predate Pass Budget counters.
	if source=="2e5049b58267d27fbff11408109e37f43dea6b2cbd84fd570ffcc94acabe3015":return true
	if source=="673d2891707ec1092aff6d929a92c96ff38f3f8a620754f5de3d0d3ffc9325d1":return true
	return not source.is_empty() and (source in CAREER_PREDECESSORS or source in STUDIO_GLOW_PREDECESSORS or source in RESEARCH_CONFIRMATION_PREDECESSORS or source in GAMEPLAY_RESTORATION_PREDECESSORS or source in TECH_ROW_PRESENTATION_PREDECESSORS or source in AUDIO_PREDECESSOR_SOURCES or (source in GRID_PREDECESSOR_SOURCES+RESEARCH_PERFORMANCE_PREDECESSORS+QUIT_PRESENTATION_PREDECESSORS+STORE_NAVIGATION_PREDECESSORS) or source in STORE_ROOT_PRESENTATION_PREDECESSORS or source=="" or source in RESEARCH_PERFORMANCE_PREDECESSORS or source in QUIT_PRESENTATION_PREDECESSORS or source in STORE_NAVIGATION_PREDECESSORS or source in STORE_ERA_PREDECESSORS or source in MENU_VISUALIZER_PREDECESSORS or source in STARTER_SCOPE_PREDECESSORS or source in SCORE_FLOAT_PREDECESSORS or source in BALANCED_SMALL_HAND_PREDECESSORS or source in BALANCED_BOOST_PREDECESSORS or source in CARD_POP_PREDECESSORS or source in EMPLOYEE_MENU_PREDECESSORS or source in INSIDER_HOLD_PREDECESSORS or source in PAUSE_TRANSITION_SOURCES or source in LATENCY_PREDECESSOR_SOURCES or source in SEARCH_PRESENTATION_SOURCES or source in EMPLOYEE_PRE_SEARCH_SOURCES or source in ROOT_FIRST_PREDECESSOR_SOURCES or source in USABILITY_PRESENTATION_SOURCES or (source in USABILITY_PREDECESSOR_SOURCES) or (source in SUPPORT_PREDECESSOR_SOURCES or source in COMPATIBLE_COMMISSION_PRESENTATION_SOURCES) or (source == RELATIONSHIP_PREDECESSOR_SOURCE or source in RELATIONSHIP_PREDECESSOR_EXPORTS or source in COMPATIBLE_MARKET_PRESENTATION_SOURCES) or (source in COMMISSION_PREDECESSOR_SOURCES))

func _valid_pass_budget(state: Dictionary,definitions: Dictionary) -> bool:
	var budget: Dictionary=state.pass_budget
	var bonus_centi: int=int(budget.get("bonus_centi",0))
	if bonus_centi<0 or bonus_centi>20*int(budget.get("printed",0)):error="Invalid Skill Tree budget bonus";return false
	if budget.version not in [0,1,2]:error="Unknown Pass Budget version";return false
	if state.hand.candidate_ids.size()!=state.hand.candidate_cards.size():error="Mismatched candidate arrays";return false
	var protected: Array = state.hand.get("injected_candidate_ids", [])
	var seen_protected := {}
	for token in protected:
		if token not in state.hand.candidate_ids or seen_protected.has(token):error="Invalid protected Pass token";return false
		seen_protected[token] = true
		var id: StringName = state.hand.candidate_cards[state.hand.candidate_ids.find(token)]
		if id not in [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"]:error="Protected candidate is not a corrective Pass";return false
	if state.hand.candidate_cards.size()-protected.size()>7:error="Ordinary candidate pool exceeds seven";return false
	if budget.version==0:
		if budget.printed!=0 or budget.spent!=0 or bonus_centi!=0 or not _known_budget_origin(budget.origin):error="Unproven legacy Pass Budget";return false
		return true
	if not budget.origin.is_empty():error="Unexpected Pass Budget origin";return false
	if state.phase_index==2:
		if budget.printed!=0 or budget.spent!=0 or bonus_centi!=0:error="Beta cannot carry active Pass counters";return false
		return true
	var printed:=0;var held:=0
	for id: StringName in state.hand.exhausted:
		if not state.hand.exhausted[id] or not definitions.has(id):error="Invalid budget Feature provenance";return false
		var card: Dictionary=definitions[id]
		if card.type!="feature" or card.phase!=["design","alpha"][state.phase_index]:error="Wrong budget Feature phase";return false
		if card.has("core_contributions"):
			for entry: Dictionary in card.core_contributions:printed+=int(entry.value)
		else:printed+=int(card.get("primary_value",0))+int(card.get("secondary_value",0))
	for id: StringName in state.hand.candidate_cards:
		if not definitions.has(id):held+=1 # Pass definitions are outside Feature table.
	var generated: int=preload("res://scripts/simulation/pass_budget.gd").generated(printed,budget.version,bonus_centi)
	if budget.printed!=printed or budget.spent>generated or held>generated-int(budget.spent) or (int(budget.spent)+state.hand.exhausted.size())/4 + int((int(budget.spent)+state.hand.exhausted.size())%4 != 0)>int(state.project._current_cycle):error="Inconsistent Pass Budget counters/reservations";return false
	return true

static func _payload_calendar(payload: Dictionary) -> Dictionary:
	var raw: Dictionary=payload.get("run",{})
	if not raw.has("calendar"):return {}
	var codec:=CheckpointCodec.new()
	var decoded: Variant=codec.decode(raw.calendar,CheckpointSchema.calendar_profile())
	return decoded if codec.error.is_empty() and decoded is Dictionary and Clock.valid(decoded) else {"invalid":true}
