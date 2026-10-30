from pathlib import Path
import importlib.util
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[4]
spec = importlib.util.spec_from_file_location("exporter", ROOT / "docs/codex/findings/export-queue-v3/export.py")
exporter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(exporter)


class PresetSelection(unittest.TestCase):
    def choose(self, text):
        directory = Path(__file__).resolve().parent / "preset-fixtures"
        directory.mkdir(exist_ok=True)
        path = Path(tempfile.mkdtemp(prefix="pn-preset-", dir=directory)) / "export_presets.cfg"
        path.write_text(text, encoding="utf-8")
        return exporter.windows_export_preset(path)

    def test_current_repository_renamed_preset(self):
        self.assertEqual(exporter.windows_export_preset(ROOT / "patch-notes/export_presets.cfg"), "Patch Notes v0.01")

    def test_platform_selection_ignores_other_targets_and_alias(self):
        self.assertEqual(self.choose('[runnable_presets]\n"Windows Desktop"="Custom Build"\n[preset.0]\nname="Linux"\nplatform="Linux"\n[preset.1]\nname="Custom Build"\nplatform="Windows Desktop"\n[preset.1.options]\nfoo="bar"\n'), "Custom Build")

    def test_legacy_name(self):
        self.assertEqual(self.choose('[preset.0]\nname="Windows Desktop"\nplatform="Windows Desktop"\n'), "Windows Desktop")

    def test_missing_platform_rejects(self):
        with self.assertRaises(ValueError):
            self.choose('[preset.0]\nname="Linux"\nplatform="Linux"\n')

    def test_ambiguous_platform_rejects(self):
        with self.assertRaises(ValueError):
            self.choose('[preset.0]\nname="A"\nplatform="Windows Desktop"\n[preset.1]\nname="B"\nplatform="Windows Desktop"\n')


if __name__ == "__main__":
    unittest.main()
