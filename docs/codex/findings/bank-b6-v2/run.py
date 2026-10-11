"""Execute the declared B6 routes only after source-bound exported acceptance."""
import gzip
import hashlib
from pathlib import Path
import sys
import runner_support as r
import evidence as e

H = Path(__file__).resolve().parent
r.HERE = H
r.COPY = Path(e.read(H / "source-manifest.json")["analysis_copy"])
r.PROFILES = Path(r"C:/Users/64jus/Downloads/Patch Notes Design Folder/bank-b6-v2-profiles")
r.SCRIPTS = (H / "b6_v2.gd",)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    if action == "install":
        e.need(not list(H.glob("*.result-manifest.json")), "Version a new experiment before changing completed route scripts")
        r.install_scripts()
        r.execute("import-repair", ["--editor", "--import", "--quit"], 300)
        e.source_context()
    elif action == "check":
        context = e.upstream_context(e.source_context())
        print("PASS source-bound upstream gate", context["upstream_acceptance_sha256"])
    elif action == "run":
        context = e.upstream_context(e.source_context())
        e.write(H / "route-manifest.json", e.ROUTES)
        for spec in e.ROUTES:
            c, p, b, seed = spec
            name = f"{c}-{p}-{b}-{seed}"
            out, archive = H / (name + ".json"), H / (name + ".json.gz")
            if archive.exists():
                e.validate_route(name, spec, context)
                print("Verified existing route", name, flush=True)
                continue
            e.need(not out.exists(), "Unarchived route output exists; preserve/review it before retrying: " + name)
            e.need(e.upstream_context(e.source_context()) == context, "Source or acceptance changed during study")
            r.execute(name, ["--script", "res://scripts/debug/b6_v2.gd", "--", f"--creation={c}",
                            f"--policy={p}", f"--band={b}", f"--seed={seed}", f"--out={out}"], 240)
            command_path = H / (name + ".command.json")
            command = e.read(command_path)
            command.update(provenance=context, route=list(spec))
            e.write(command_path, command)
            payload = out.read_bytes()
            archive.write_bytes(gzip.compress(payload, mtime=0))
            e.write(H / (name + ".result-manifest.json"), {
                "provenance": context, "route": list(spec), "archive_sha256": e.sha(archive),
                "command_sha256": e.sha(command_path), "log_sha256": e.sha(H / (name + ".log")),
                "output_sha256": hashlib.sha256(payload).hexdigest(),
            })
            e.validate_route(name, spec, context)
            out.unlink()
    else:
        raise SystemExit("Usage: run.py install|check|run (prepare is intentionally disabled for this pinned baseline)")


if __name__ == "__main__":
    main()
