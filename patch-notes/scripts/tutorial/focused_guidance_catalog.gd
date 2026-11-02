extends RefCounted
## Read-only subsystem milestones. Availability is not affordability.
const IDS: Array[StringName]=[&"bank",&"engines",&"contracts",&"employees",&"implementation",&"skills",&"publishers",&"summaries",&"market"]
const LABELS={&"bank":"Bank",&"engines":"Engines",&"contracts":"Contracts",&"employees":"Employees",&"implementation":"Feature Implementation",&"skills":"Engine Skill Tree",&"publishers":"Publishers",&"summaries":"Post Game Summaries",&"market":"Daily Chart and Rivals"}
static func snapshot(run: RunState) -> Dictionary:
 var result: Dictionary={"releases":0,"public_releases":0,"bankroll_cents":0,"publishers":[],"implementation_engine":&"","skill_engine":&""}
 if run==null or run._bank_run_id.is_empty():return result
 var ids:=run.get_released_game_ids();result.releases=ids.size()
 for id: StringName in ids:
  if run.get_released_game_engine_id(id)==&"public_action":result.public_releases+=1
 var debt:=StudioFinanceLedger.get_unpaid(run._studio_finance)
 if debt>=0:result.bankroll_cents=run.get_cash_cents()-debt
 result.publishers=run.get_unlocked_publisher_ids()
 var engines:=run.get_engine_feature_state()
 var selected:=run.get_selected_engine_id()
 var ordered: Array=engines.engines.keys()
 if selected in ordered:ordered.erase(selected);ordered.push_front(selected)
 for id: StringName in ordered:
  if engines.engines[id].kind==&"proprietary":result.implementation_engine=id;break
 var owned:=run.get_proprietary_engine_state()
 for id: StringName in owned.engines:
  var row: Dictionary=owned.engines[id]
  for branch: StringName in [&"graphics",&"sound",&"technology",&"design"]:
   var next: Dictionary=RunState.ProprietaryEngines.node(branch,RunState.ProprietaryEngines.generation(row,branch)+1)
   if not next.is_empty() and int(row.challenge_progress.get(branch,0))>=int(next.threshold):
    result.skill_engine=id;return result
 return result

static func candidates(s: Dictionary) -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 if int(s.get("bankroll_cents",0))<0:result.append(offer(&"bank","Your bankroll is negative","Overdue bills are included in your bankroll. The Bank can help you inspect what is due and preview available borrowing. Would you like a tour?"))
 if int(s.get("public_releases",0))>=3:result.append(offer(&"engines","Ready to explore engines?","You have released three games with Public engines. Their fixed libraries and royalties are useful starting terms. Would you like to explore engine choices and owning your own?"))
 if int(s.get("releases",0))>=1:result.append(offer(&"contracts","Contracts unlocked!","Your first release opened Contract work. Learn how targets, hands, engine choices and payments work before accepting a job."))
 if int(s.get("releases",0))>=2:result.append(offer(&"employees","Employees unlocked!","You can now manage specialists and their training. Would you like a tour of hiring, monthly wages and planning?"))
 if not str(s.get("implementation_engine","")).is_empty():result.append(offer(&"implementation","Your engine can grow","Your owned engine can implement Features. Would you like to see prerequisites, the FIFO queue and future-game configuration?"))
 if not str(s.get("skill_engine","")).is_empty():result.append(offer(&"skills","An engine Skill challenge is ready","Your engine has earned a Skill challenge. The Skill Tree shows its requirements, purchase price and generation progress. Would you like a tour?"))
 if not s.get("publishers",[]).is_empty():result.append(offer(&"publishers","A publisher is interested","A publisher profile has unlocked. Would you like to learn how to inspect availability and compare the actual terms?"))
 if int(s.get("releases",0))>=1:
  result.append(offer(&"summaries","Your release has a report","Your game now has a Post Game Summary. Review its results, actual earnings and Promotion options with a short tour."))
  result.append(offer(&"market","Follow your game on the market","The Daily Chart includes your released games and rival studios. Would you like to learn how to read the market?"))
 return result

static func offer(id: StringName,title: String,body: String) -> Dictionary:
 return {"id":id,"label":LABELS[id],"title":title,"body":body}
static func step(title: String,body: String,target: String) -> Dictionary:
 return {"title":title,"body":body,"target":target}
static func steps(id: StringName) -> Array:
 match id:
  &"bank":return [step("Read your bankroll","Your bankroll is cash minus overdue obligations. Forecast sales and unpaid earnings are not spendable cash. This tour never borrows or pays anything.","FinanceTotals"),step("Preview before accepting","Enter an amount and term when you are ready to borrow. Preview quote shows the actual offer, debt deductions, interest and repayment schedule. A quote is not an accepted loan.","BankAmount"),step("Inspect repayments","Previous/next payments and financial history explain what has been paid and what is still due. Productive cycles reach the next bill on the game's central calendar.","LoanSelector"),step("Keep room for bills","Check upcoming rent, wages and debt before spending. Close this tour to use the Bank normally; accepting or paying a loan is always your own action.","BankQuote")]
  &"engines":return [step("Compare engine choices","The list separates Public access, licensed engines, your own engines and market offerings. Inspecting an engine is free and does not select it for a project.","EngineChoices"),step("Read the actual terms","An engine supplies a Feature library, capacity, specialty and any royalties. Public libraries are fixed. The project's frozen engine identity and terms survive through release.","EngineDetails"),step("Create separately","Creating your own engine is a separate paid action. Its library grows through implementation; its Skill Tree supports earned upgrades. This tour never creates, licenses or selects an engine.","DevelopNewEngine")]
  &"contracts":return [step("Compare the job","Check the offer's Core and Scope targets, required hands and engine choices. Browsing is free; accepting starts that specific job.","ContractDetailText"),step("Understand payment","Read guaranteed upfront and completion/challenge terms. A short hand is legal but still consumes a required hand. Feature plays in Contracts are free; ordinary bills still apply.","ContractDetailText"),step("Commit only when ready","Choose your engine and priorities before accepting. Accepted work cannot be abandoned, and Continue still returns to the last Studio checkpoint. This tour accepts nothing.","AcceptContractButton")]
  &"employees":return [step("Meet your specialists","Employees unlock after two releases. Roster, Courses and Progress explain candidates, plans and experience. This preview does not activate or hire anyone.","EmployeePanel"),step("Read cost and department","Hiring and recurring wages are separate costs. Specialists contribute through their departments and actual plans; inspect all terms before confirming a hire.","EmployeePanel"),step("Plan and train","Courses and progress depend on their stated requirements. Finish this preview to return to Studio Management; open Employees yourself to manage the roster.","EmployeePanel")]
  &"implementation":return [step("Follow prerequisites","Your engine's tree distinguishes implemented, held and available Features. Missing-prerequisite controls lead to the necessary nodes. Public and licensed libraries cannot be expanded.","EngineTitle"),step("Queue, then implement","An eligible admission pays its stated down payment without a cycle. The Implement action completes the FIFO head for one productive cycle and the displayed remaining payment. This tour queues and pays nothing.","ImplementFeature"),step("Plan future games","Completed Features affect games begun later with that engine. Existing project pools remain frozen. Familiarity comes from use, and engine capacity/configuration still applies.","ImplementationQueue")]
  &"skills":return [step("Earn each challenge","Each branch shows its own earned challenge and purchase requirement. Earning a challenge is different from having enough money to buy the Skill.","EngineSkillTree"),step("Inspect the upgrade","Only available generations can be purchased. Read the actual quote, branch effects and automatic capacity milestones; no Feature cards are granted by this tour.","EngineSkillTree"),step("Keep engines distinct","Progress belongs to the particular engine you are inspecting. This tour never buys a Skill, and existing projects keep their frozen engine terms.","BackToEngine")]
  &"publishers":return [step("Profiles and availability","Profiles can unlock at different milestones. The browser tells you which work and terms are actually available; a new profile is not guaranteed funding.","PublisherList"),step("Compare terms","Inspect work, standing and conditions before choosing. Support and commissions are distinct from ordinary cash Contracts. Existing accepted terms stay frozen.","PublisherBrowser"),step("Decide yourself","Opening the browser is free. Only your own explicit acceptance can commit work or money. Finish this tour to inspect the profiles normally.","PublisherBrowser")]
  &"summaries":return [step("Choose a released game","Your summaries remain available after the first release. Select a game to inspect its frozen Review, Core and Scope results.","GameList"),step("Actual versus projected","Forecasts are estimates. Monthly sales and earned/paid totals show what really happened; unpaid proceeds are not cash you can spend.","SummaryPanel"),step("Promotion is optional","A campaign uses its displayed money and cycle cost. Detailed Review and Monthly Sales explain more. This tour runs no campaign.","CampaignButton")]
  &"market":return [step("Read the Daily Chart","Rows include actual games from your Studio and AI rivals. Newest releases appear first; units are actual sales rather than forecasts.","MarketBrowser"),step("Compare carefully","Filters separate studios. Historical records are labelled and may have unavailable sales. Inspect the selected game's details before comparing.","MarketBrowser"),step("Meet the rivals","Market Info also contains Rival Info: live games, Fans and bankroll by Studio. Opening these pages costs no productive cycle.","MarketBrowser")]
 return []
