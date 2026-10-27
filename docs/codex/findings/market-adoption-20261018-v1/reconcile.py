from integrate import PROJECT
def edit(path, old, new):
    p=PROJECT/path;s=p.read_text(encoding='utf-8');assert s.count(old)==1,(path,old[:100]);p.write_text(s.replace(old,new),encoding='utf-8')

edit('scripts/sales/released_game_sales.gd','extends RefCounted','extends RefCounted\n\nconst Market := preload("res://scripts/market/market_transaction_trial.gd")')
edit('scripts/sales/released_game_sales.gd','if not factor is Dictionary or factor.size()!=2 or not factor.get("factor_bp") is int or factor.factor_bp<7000 or factor.factor_bp>10000 or not factor.get("snapshot_id") is String or factor.snapshot_id.is_empty(): return false','if not Market.valid_factor(factor): return false')
edit('scripts/sales/released_game_sales.gd','snapshot_id: String = "market-0-neutral") -> Dictionary:', 'snapshot_id: String = "market-0-neutral", factor_details: Dictionary = {}) -> Dictionary:')
edit('scripts/sales/released_game_sales.gd','result.market_factors[age_month]={"factor_bp":factor_bp,"snapshot_id":snapshot_id}', '''var frozen := Market.neutral_factor() if factor_details.is_empty() else factor_details.duplicate(true)
		if frozen.factor_bp!=factor_bp or frozen.snapshot_id!=snapshot_id or not Market.valid_factor(frozen): return {}
		result.market_factors[age_month]=frozen''')
# Restore zero-organic skip from the unchanged baseline; validated factors cannot create units.
edit('scripts/sales/released_game_sales.gd','\t\twhile age_month <= last_age_month:\n', '''\t\twhile age_month <= last_age_month:
			if age_month > 2 and organic == 0 and not campaign_months.has(age_month):
				if campaign_index >= campaign_ages.size():
					active = 0
					monthly = 0
					break
				age_month = campaign_ages[campaign_index]
''')
edit('scripts/run_state.gd','int(factor.factor_bp), str(factor.snapshot_id))','int(factor.factor_bp), str(factor.snapshot_id),factor)')
edit('scripts/run_state.gd','var factor := {"factor_bp":10000,"snapshot_id":market.id}','var factor: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").neutral_factor()')
edit('scripts/fanbase/studio_fanbase.gd','int(source_factor.factor_bp),str(source_factor.snapshot_id))','int(source_factor.factor_bp),str(source_factor.snapshot_id),source_factor)')
edit('scripts/sales/released_game_monthly_report.gd','ReleasedGameSales.next_cycle(replay, cycle, cycle % 2 == 0, campaign)','ReleasedGameSales.next_cycle(replay, cycle, cycle % 2 == 0, campaign, record.market_factors[month].factor_bp, record.market_factors[month].snapshot_id, record.market_factors[month])')
edit('scripts/sales/released_game_monthly_report.gd','"slices": [], "payments": []','"market": record.market_factors[month].duplicate(true), "slices": [], "payments": []')
edit('scripts/persistence/checkpoint_schema.gd','\tresult.campaign_months = map_of("uint","uint")','\tresult.campaign_months = map_of("uint","uint")\n\tresult.market_factors = map_of("uint",market_factor())')
edit('scripts/persistence/checkpoint_schema.gd','static func sales() -> Dictionary:', '''static func market_factor() -> Dictionary:
	return {"factor_bp":"uint","snapshot_id":"text","cycle_start":"uint","genre_only":"uint","theme_only":"uint","pair":"uint","historical":"bool"}

static func market_details() -> Dictionary:
	return {"snapshot_id":"text","cycle_start":"uint","standards":array_of("uint"),"base":array_of("uint"),"recent_count":"uint","density_lift":"uint","benchmark_lifts":array_of("uint"),"historical":"bool"}

static func sales() -> Dictionary:''')
edit('scripts/persistence/checkpoint_schema.gd','\treview.competitor_target_cycle = "int"\n', '\treview.competitor_target_cycle = "int"\n\tvar market_review := review.duplicate(true)\n\tmarket_review.market = market_details()\n')
edit('scripts/persistence/checkpoint_schema.gd','"release_cycle":"uint","review":review}', '"release_cycle":"uint","review":union_of([review,market_review])}')
edit('scripts/persistence/studio_checkpoint.gd','const RULES := PRE_ROSTER_RULES + "-roster2"','const PRE_MARKET_RULES := PRE_ROSTER_RULES + "-roster2"\nconst RULES := PRE_MARKET_RULES + "-market1"')
edit('scripts/persistence/studio_checkpoint.gd','[RULES, PRE_ROSTER_RULES,','[RULES, PRE_MARKET_RULES, PRE_ROSTER_RULES,')
# New schema must never interpret an unmigrated old sales ledger as new data.
edit('scripts/persistence/studio_checkpoint.gd','if payload.get("content_revision", "") not in (_catalog_revisions(RULES) + _catalog_revisions(PRE_ROSTER_RULES) + _catalog_revisions(PRE_GAMEPLAY_TREE_RULES) + _catalog_revisions(PRE_CONE_RULES) + _catalog_revisions(PRE_CHALLENGE_RULES) + _catalog_revisions(PRE_BRANCH_RULES) + _catalog_revisions(PRE_CULT20_RULES) + _legacy_revisions(PRE_CULT_RULES) + _legacy_revisions(PRE_EDUCATION_RULES))', 'if payload.get("content_revision", "") != revision()')
edit('scripts/market/rival_world_checkpoint.gd','const Legacy := preload("res://scripts/legacy/legacy_world.gd")','const Legacy := preload("res://scripts/legacy/legacy_world.gd")\nconst Market := preload("res://scripts/market/market_transaction_trial.gd")')
p=PROJECT/'scripts/market/rival_world_checkpoint.gd';s=p.read_text(encoding='utf-8');lines=s.splitlines();lines=[('\tvar source_ok: bool = payload.get("source_identity")==Replay.source_identity()' if l.startswith('\tvar source_ok:') else l) for l in lines];p.write_text('\n'.join(lines)+'\n',encoding='utf-8')
edit('scripts/market/rival_world_checkpoint.gd','payload.size()!=(7 if payload.has("legacy") else 6)', 'payload.size()!=(8 if payload.has("legacy") else 7)')
edit('scripts/market/rival_world_checkpoint.gd','or not payload.get("history") is Array:', 'or not payload.get("history") is Array or not payload.get("market") is Dictionary:')
edit('scripts/market/rival_world_checkpoint.gd','"_market_snapshot_id":"text"}', '"_market_snapshot_id":"text","_market_details":CheckpointSchema.market_details()}')
edit('scripts/market/rival_world_checkpoint.gd','"_genre_ratios","_market_standards","_market_snapshot_id"]:', '"_genre_ratios","_market_standards","_market_snapshot_id","_market_details"]:')
edit('scripts/market/rival_world_checkpoint.gd','\t\t\tif dev.project._release_id !=', '\t\t\tif not Market.valid_details(dev.project._market_details,dev.project._genre_id) or dev.project._market_details.standards!=dev.project._market_standards or dev.project._market_details.snapshot_id!=dev.project._market_snapshot_id: error="Invalid frozen rival market target"; return {}\n\t\t\tif dev.project._release_id !=')
edit('scripts/simulation/development_replay.gd','\t_collect("res://data",paths)', '\t_collect("res://data",paths)\n\tpaths.append("res://queries/market_release_index.gd") # Now an authoritative market input.')
edit('queries/market_release_index.gd','## Derived inspection data only. Kept outside scripts/ so adding this query does\n## not invalidate the gameplay/replay identity or an existing Studio checkpoint.', '## Validated actual release facts, shared by inspection and the monthly market.\n## Explicitly included in the mechanical source identity since market adoption.')
