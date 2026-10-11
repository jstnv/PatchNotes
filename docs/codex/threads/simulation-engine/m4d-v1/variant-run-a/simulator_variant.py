"""Create editable, isolated candidate simulators and reviewable adoption handoffs.

Standard library only. Candidate project code is trusted local executable code,
not a security sandbox. Only project/ is editable; baseline and metadata are
hash-fenced. Nothing applies changes to canonical source, TODO, or player saves.
"""
from __future__ import annotations

import argparse
import datetime as dt
import difflib
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import sys
import zipfile

SPEC = importlib.util.spec_from_file_location("variant_simulate_support", Path(__file__).with_name("simulate.py"))
sim = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sim)
FORMAT = "patch-notes-simulator-variant-v1"
PROTECTED = ("variant.json", "base-manifest.json", "base-source.zip", "creation-manifest.json")


def identity(hashes: dict) -> str:
    return hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()


def valid_manifest(value: object) -> dict[str, str]:
    if not isinstance(value, dict) or "project.godot" not in value:
        raise ValueError("Missing source manifest")
    normalized = set()
    for name, digest in value.items():
        sim.safe_relative(name)
        if name.casefold() in normalized or not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError("Invalid or conflicting source manifest entry: " + str(name))
        normalized.add(name.casefold())
    return value


def delta(base: dict, current: dict) -> list[dict]:
    return [{"path": path, "change": "added" if path not in base else "deleted" if path not in current else "modified", "before_sha256": base.get(path), "after_sha256": current.get(path)}
            for path in sorted(base.keys() | current.keys()) if base.get(path) != current.get(path)]


def checked_file(path: Path) -> Path:
    sim.reject_links(path)
    if not path.is_file():
        raise ValueError("Missing protected variant file: " + str(path))
    return path


def archive(project: Path, destination: Path, hashes: dict) -> None:
    with zipfile.ZipFile(destination, "x", compression=zipfile.ZIP_DEFLATED) as output:
        for relative, digest in sorted(hashes.items()):
            path = project / sim.safe_relative(relative)
            if sim.sha(path) != digest:
                raise RuntimeError("Source changed before archiving: " + relative)
            output.write(path, relative)
    verify_archive(destination, hashes)
    sim.check_snapshot(project, hashes)


def verify_archive(path: Path, hashes: dict) -> None:
    with zipfile.ZipFile(checked_file(path)) as source:
        if len(source.namelist()) != len(hashes) or set(source.namelist()) != set(hashes):
            raise ValueError("Baseline archive inventory differs from manifest")
        for name, expected in hashes.items():
            sim.safe_relative(name)
            if hashlib.sha256(source.read(name)).hexdigest() != expected:
                raise ValueError("Baseline archive hash mismatch: " + name)


def load_variant(path: Path) -> tuple[dict, dict, dict, dict]:
    sim.reject_links(path)
    path = path.resolve()
    integrity = sim.read_json(checked_file(path / "integrity.json"))
    if not isinstance(integrity, dict) or set(integrity) != set(PROTECTED):
        raise ValueError("Variant integrity manifest has unexpected fields")
    for name, digest in integrity.items():
        if sim.sha(checked_file(path / name)) != digest:
            raise ValueError("Protected variant metadata/baseline changed: " + name)
    metadata = sim.read_json(path / "variant.json")
    if not isinstance(metadata, dict) or metadata.get("format") != FORMAT or metadata.get("status") != "CANDIDATE":
        raise ValueError("Unsupported variant metadata")
    if not isinstance(metadata.get("id"), str) or not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}", metadata["id"]):
        raise ValueError("Invalid variant id")
    if not isinstance(metadata.get("owner"), str) or not metadata["owner"].strip() or not isinstance(metadata.get("lineage"), list):
        raise ValueError("Variant owner and lineage are required")
    base = valid_manifest(sim.read_json(path / "base-manifest.json"))
    creation = valid_manifest(sim.read_json(path / "creation-manifest.json"))
    if metadata.get("base_identity") != identity(base) or metadata.get("creation_identity") != identity(creation):
        raise ValueError("Variant baseline/creation identity mismatch")
    verify_archive(path / "base-source.zip", base)
    current = sim.source_hashes(path / "project")
    valid_manifest(current)
    return metadata, base, current, integrity


def new_output(path: Path, forbidden: list[Path]) -> Path:
    sim.reject_links(path)
    path = path.resolve()
    for source in forbidden:
        sim.reject_links(source)
        if path.is_relative_to(source.resolve()):
            raise ValueError("Output must be outside source, existing variants and evidence bundles")
    path.mkdir(parents=True, exist_ok=False)
    (path / ".gdignore").touch()
    return path


def copy_checked(source: Path, target: Path) -> None:
    digest = sim.sha(checked_file(source))
    shutil.copy2(source, target)
    if sim.sha(source) != digest or sim.sha(target) != digest:
        raise RuntimeError("Protected artifact changed while copying: " + str(source))


def create(args: argparse.Namespace) -> dict:
    if not re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}", args.id) or not args.owner.strip():
        raise ValueError("Use a safe variant id and nonempty owner")
    canonical = args.repo / "patch-notes"
    sim.reject_links(canonical)
    canonical = canonical.resolve()
    parent = args.from_variant
    loaded = load_variant(parent) if parent else None
    output = new_output(args.output, [canonical] + ([parent] if parent else []))
    source = parent / "project" if parent else canonical
    creation = sim.copy_snapshot(source, output / "project")
    lineage = []
    if loaded:
        parent_metadata, base, parent_current, parent_integrity = loaded
        if creation != parent_current:
            raise RuntimeError("Parent variant changed while forking")
        for name in ("base-source.zip", "base-manifest.json"):
            copy_checked(parent / name, output / name)
        lineage = parent_metadata["lineage"] + [{"id": parent_metadata["id"], "owner": parent_metadata["owner"], "variant_path": str(parent.resolve()), "metadata_sha256": parent_integrity["variant.json"], "source_identity": identity(creation)}]
        if any(entry.get("id") == args.id for entry in lineage):
            raise ValueError("A fork must have a new id")
        if load_variant(parent)[3] != parent_integrity:
            raise RuntimeError("Parent metadata changed while forking")
    else:
        base = creation
        sim.write_json(output / "base-manifest.json", base)
        archive(output / "project", output / "base-source.zip", base)
    sim.write_json(output / "creation-manifest.json", creation)
    provenance = sim.git_provenance(args.repo)
    metadata = {"format": FORMAT, "status": "CANDIDATE", "id": args.id, "owner": args.owner.strip(), "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "canonical_project": str(canonical), "base_identity": identity(base), "creation_identity": identity(creation), "lineage": lineage, "canonical_git": {key: provenance[key] for key in ("branch", "head", "dirty")}, "scope": "Editable proposal only; canonical adoption requires implementation review through the internal TODO"}
    sim.write_json(output / "variant.json", metadata)
    sim.write_json(output / "integrity.json", {name: sim.sha(output / name) for name in PROTECTED})
    (output / "README.md").write_text("# Candidate simulator: " + args.id + "\n\nOwner: " + args.owner.strip() + "\n\nEdit only `project/`. Baseline, creation manifest and metadata are hash-fenced; preserve them. Fork into a new version with `simulator_variant.py create --from-variant <this-folder>`. No Git commit is required.\n\nRun through canonical `tools/simulate.py run --variant <this-folder> --config <experiment.json> --output <new-run-folder>`. Each run freezes its source and receives private cache/profile paths, so different threads can run concurrently. Keep run outputs outside this version. Never point candidate code at live saves or canonical paths. Trusted local GDScript can access the filesystem; isolation is not a security sandbox.\n\nBefore proposing adoption, run focused checks and exact replay, then use `simulator_variant.py handoff --variant <this-folder> --evidence <run-bundle> --output <new-handoff-folder>`. Reference that handoff and the design decision in an internal TODO entry for the implementation thread. Handoff generation never edits TODO or applies changes. A successful simulation is evidence, not design approval. Studio-only Continue remains the canonical boundary.\n", encoding="utf-8")
    with (output / "README.md").open("a", encoding="utf-8") as text:
        text.write("\nThe handoff command also requires `--design-record <decision.md> --summary <concrete-addition> --acceptance <criterion>` (repeat acceptance as needed). It retains a hashed copy of the design decision for review.\n")
    load_variant(output)
    return {"ok": True, "mode": "create", "output": str(output), "id": args.id, "base_identity": metadata["base_identity"], "creation_identity": metadata["creation_identity"]}


def freeze_for_run(variant: Path, canonical: Path, destination: Path, output: Path) -> tuple[dict, dict]:
    metadata, base, current, integrity = load_variant(variant)
    canonical_hashes = sim.source_hashes(canonical)
    copied = sim.copy_snapshot(variant / "project", destination)
    if copied != current:
        raise RuntimeError("Variant changed during snapshot capture")
    if load_variant(variant)[3] != integrity:
        raise RuntimeError("Variant metadata changed during snapshot capture")
    if sim.source_hashes(canonical) != canonical_hashes:
        raise RuntimeError("Canonical source changed while recording drift; retry in a new output")
    report = {"id": metadata["id"], "owner": metadata["owner"], "status": "CANDIDATE", "path": str(variant.resolve()), "metadata_sha256": integrity["variant.json"], "base_identity": identity(base), "creation_identity": metadata["creation_identity"], "candidate_identity": identity(copied), "canonical_identity": identity(canonical_hashes), "canonical_path": str(canonical.resolve()), "baseline_drift": base != canonical_hashes, "delta": delta(base, copied), "canonical_delta": delta(base, canonical_hashes), "lineage": metadata["lineage"]}
    sim.write_json(output / "variant-provenance.json", report)
    for name in ("variant.json", "integrity.json", "base-manifest.json", "creation-manifest.json"):
        copy_checked(variant / name, output / ("variant-" + name))
    sim.write_json(output / "canonical-source-manifest.json", canonical_hashes)
    # The run already retains the complete candidate project and pre-import manifest.
    return copied, report


def evidence_reference(bundle: Path, candidate: dict, metadata_digest: str) -> dict:
    sim.reject_links(bundle)
    bundle = bundle.resolve()
    report = sim.read_json(checked_file(bundle / "run-report.json"))
    if not isinstance(report, dict) or report.get("mode") != "run" or not isinstance(report.get("variant"), dict) or report["variant"].get("metadata_sha256") != metadata_digest:
        raise ValueError("Evidence must be a run from this candidate version")
    if report["variant"].get("candidate_identity") != identity(candidate) or sim.read_json(checked_file(bundle / "workspace-source-manifest.json")) != candidate:
        raise ValueError("Evidence predates candidate edits; run the current version again")
    frozen = valid_manifest(sim.read_json(checked_file(bundle / "snapshot-manifest.json")))
    sim.check_snapshot(bundle / "project", frozen)
    # Preserve failed experiments too. The handoff records their actual status.
    hashes = {}
    for path in sorted(bundle.rglob("*")):
        relative = path.relative_to(bundle)
        if relative.parts[0] in {"project", "profile"}:
            continue
        sim.reject_links(path)
        if path.is_file():
            hashes[relative.as_posix()] = sim.sha(path)
    if not hashes or "run-report.json" not in hashes:
        raise ValueError("Incomplete evidence bundle")
    return {"bundle": str(bundle), "ok": report.get("ok") is True, "error": report.get("error"), "source_identity": identity(candidate), "files": hashes, "preserve_bundle": True}


def handoff(args: argparse.Namespace) -> dict:
    variant = args.variant
    metadata, base, candidate, integrity = load_variant(variant)
    canonical = args.repo / "patch-notes"
    current_canonical = sim.source_hashes(canonical)
    decision = checked_file(args.design_record)
    decision_hash = sim.sha(decision)
    if not args.summary.strip() or not args.acceptance or any(not item.strip() for item in args.acceptance):
        raise ValueError("A concrete change summary and acceptance criteria are required")
    references = [evidence_reference(path, candidate, integrity["variant.json"]) for path in args.evidence]
    output = new_output(args.output, [canonical, variant, *args.evidence])
    copy_checked(decision, output / "design-decision.md")
    frozen = sim.copy_snapshot(variant / "project", output / "project")
    if frozen != candidate:
        raise RuntimeError("Candidate changed during handoff capture")
    for name in PROTECTED + ("integrity.json",):
        copy_checked(variant / name, output / name)
    changes = delta(base, candidate)
    drift = delta(base, current_canonical)
    conflicts = [item["path"] for item in changes if current_canonical.get(item["path"]) != base.get(item["path"]) and current_canonical.get(item["path"]) != candidate.get(item["path"])]
    sim.write_json(output / "candidate-manifest.json", candidate)
    sim.write_json(output / "canonical-manifest.json", current_canonical)
    archive(output / "project", output / "candidate-source.zip", candidate)
    patch = []
    with zipfile.ZipFile(output / "base-source.zip") as baseline, zipfile.ZipFile(output / "delta-files.zip", "x", compression=zipfile.ZIP_DEFLATED) as changed_files:
        for item in changes:
            name = item["path"]
            old = baseline.read(name) if name in base else b""
            new = (output / "project" / name).read_bytes() if name in candidate else b""
            if name in candidate:
                changed_files.writestr(name, new)
            try:
                if b"\0" in old or b"\0" in new:
                    raise UnicodeError()
                # Human review only; delta manifest + exact bytes handle binary/deleted files.
                patch.extend(difflib.unified_diff(old.decode("utf-8").splitlines(keepends=True), new.decode("utf-8").splitlines(keepends=True), fromfile="base/" + name, tofile="candidate/" + name))
            except UnicodeError:
                patch.append("Binary source changed: " + name + "\n")
    (output / "source-review.patch").write_bytes("".join(patch).encode("utf-8"))
    record = {"format": "patch-notes-simulator-handoff-v1", "status": "READY_FOR_IMPLEMENTATION_REVIEW", "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "variant": metadata, "summary": args.summary.strip(), "design_record": {"path": str(decision.resolve()), "sha256": decision_hash, "copy": "design-decision.md"}, "acceptance": args.acceptance, "base_identity": identity(base), "candidate_identity": identity(candidate), "canonical_identity": identity(current_canonical), "baseline_drift": base != current_canonical, "changes": changes, "canonical_changes_since_base": drift, "conflicts_requiring_review": conflicts, "evidence": references, "adopted": False, "todo_updated": False}
    sim.write_json(output / "handoff.json", record)
    (output / "HANDOFF.md").write_text(f"# Simulator candidate {metadata['id']}\n\nOwner: {metadata['owner']}\n\n**READY FOR IMPLEMENTATION REVIEW — not adopted.**\n\nBase: `{identity(base)}`\n\nCandidate: `{identity(candidate)}`\n\nCanonical now: `{identity(current_canonical)}`\n\nBaseline drift: **{record['baseline_drift']}**. Conflicting changed paths: **{len(conflicts)}**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.\n\n`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.\n\n## Internal TODO handoff\n\nAdd a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.\n\nCandidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.\n", encoding="utf-8")
    with (output / "HANDOFF.md").open("a", encoding="utf-8") as text:
        text.write("\n## Proposed addition\n\n" + args.summary.strip() + "\n\nDesign record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.\n\n## Acceptance criteria\n\n" + "".join("- " + item.strip() + "\n" for item in args.acceptance))
    if sim.source_hashes(canonical) != current_canonical or load_variant(variant)[2:] != (candidate, integrity):
        raise RuntimeError("Source or metadata changed while producing handoff")
    # A handoff is a new sealed record, never updated in place. Local trusted users
    # can rewrite hashes; this detects accidental drift, not hostile tampering.
    sim.write_json(output / "handoff-integrity.json", {path.name: sim.sha(path) for path in sorted(output.iterdir()) if path.is_file() and path.name != ".gdignore"})
    return {"ok": True, "mode": "handoff", "output": str(output), "changes": len(changes), "baseline_drift": record["baseline_drift"], "conflicts": conflicts, "evidence_count": len(references)}


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    modes = result.add_subparsers(dest="mode", required=True)
    for name in ("create", "handoff"):
        mode = modes.add_parser(name)
        mode.add_argument("--repo", type=Path, default=sim.ROOT)
        mode.add_argument("--output", type=Path, required=True, help="New directory outside source/variants/evidence")
        if name == "create":
            mode.add_argument("--id", required=True)
            mode.add_argument("--owner", required=True)
            mode.add_argument("--from-variant", type=Path)
        else:
            mode.add_argument("--variant", type=Path, required=True)
            mode.add_argument("--evidence", type=Path, action="append", required=True, help="Current-candidate run bundle; repeat for more evidence, including failures")
            mode.add_argument("--design-record", type=Path, required=True, help="Existing accepted-design record; copied and hashed for review")
            mode.add_argument("--summary", required=True, help="Concrete addition proposed for canonical adoption")
            mode.add_argument("--acceptance", action="append", required=True, help="Acceptance criterion; repeat as needed")
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        report = create(args) if args.mode == "create" else handoff(args)
    except (OSError, ValueError, RuntimeError, KeyError, zipfile.BadZipFile) as error:
        report = {"ok": False, "mode": args.mode, "output": str(args.output), "error": str(error)}
    print(json.dumps(report, ensure_ascii=False))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
