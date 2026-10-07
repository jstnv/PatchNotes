// Read-only overlay for a captured Fanbase branch route. Usage: node this-file route.json
const fs = require('fs');
const routePath = process.argv[2];
if (!routePath) throw new Error('Pass the captured route JSON path.');
const route = JSON.parse(fs.readFileSync(routePath, 'utf8'));
const candidates = [
  { label: 'quarter', numerator: 1, denominator: 4 },
  { label: 'third', numerator: 1, denominator: 3 },
  { label: 'two-fifths', numerator: 2, denominator: 5 },
  { label: 'quarter-cap150', numerator: 1, denominator: 4, cap: 150 },
  { label: 'third-cap150', numerator: 1, denominator: 3, cap: 150 },
];
function fanAwareness(fans, option) {
  const raw = Math.floor(fans * option.numerator / option.denominator);
  return option.cap === undefined ? raw : Math.min(option.cap, raw);
}
function monthOneUnits(reviewTenths, totalAwareness, marketBp) {
  return Math.floor(500 * reviewTenths * (200 + totalAwareness) * marketBp / (70 * 200 * 10000));
}
function netEntitlementCents(units) { return Math.floor(units * 999 * 7 / 10); }
const rows = [];
for (let i = 0; i < route.releases.length; i++) {
  const release = route.releases[i];
  const sales = route.sales_records.find(s => s.release_id === release.release_id);
  const cycle = route.live_cycles.find(c => c.cycle === release.cycle);
  if (!sales || !cycle) throw new Error('Missing launch sales or cycle snapshot.');
  const reviewTenths = Math.round(release.final_review * 10);
  const fans = cycle.fans;
  const oldFanAwareness = release.awareness - 100 - release.marketing;
  const replayed = monthOneUnits(reviewTenths, release.awareness, sales.market_bp);
  if (replayed !== release.month_1_units) throw new Error(`Existing sales mismatch at release ${i + 1}: ${replayed} vs ${release.month_1_units}`);
  const baselineNet = netEntitlementCents(replayed);
  if (baselineNet !== release.projected_net_cents) throw new Error(`Existing net mismatch at release ${i + 1}`);
  for (const option of candidates) {
    const newFanAwareness = fanAwareness(fans, option);
    const awareness = 100 + release.marketing + newFanAwareness;
    const units = monthOneUnits(reviewTenths, awareness, sales.market_bp);
    rows.push({ game: i + 1, fans, review: release.final_review, marketBp: sales.market_bp,
      marketing: release.marketing, branchFanAwareness: oldFanAwareness,
      branchUnits: replayed, option: option.label, fanAwareness: newFanAwareness,
      units, deltaUnits: units - replayed, netEntitlementCents: netEntitlementCents(units),
      deltaNetCents: netEntitlementCents(units) - baselineNet });
  }
}
const stressBase = route.releases[3];
const stressSales = route.sales_records.find(s => s.release_id === stressBase.release_id);
const stress = [];
for (const fans of [0, 1, 2, 3, 10, 1000, 3000]) {
  const branchFanAwareness = Math.floor(150 * fans / (fans + 300));
  const branchUnits = monthOneUnits(70, 100 + stressBase.marketing + branchFanAwareness, stressSales.market_bp);
  for (const option of candidates) {
    const newFanAwareness = fanAwareness(fans, option);
    const units = monthOneUnits(70, 100 + stressBase.marketing + newFanAwareness, stressSales.market_bp);
    stress.push({ fans, option: option.label, branchFanAwareness, branchUnits,
      fanAwareness: newFanAwareness, units, deltaUnits: units - branchUnits });
  }
}
process.stdout.write(JSON.stringify({ sourceSha: 'bd450a9e4e8d83ece1478cdf5a16526432e36cce',
  note: 'Fixed-launch overlays. Net cents are potential Month 1 entitlement, not earned or settled cash.', rows, stress }, null, 2));
