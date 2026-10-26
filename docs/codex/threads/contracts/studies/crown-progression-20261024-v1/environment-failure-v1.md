# Initial runner invocation failed before source capture

2026-10-24. The sandbox-specific TEMP path created by the preceding command did not persist into the next exec environment. `simulate.py run` exited1 while creating its output directory, ending with PermissionError WinError5 on the vanished sandbox package parent. No source capture, import, gameplay, tape or saved player state was reached. Original location remains recorded in runtime-paths.json.

Transport-only correction declared before retry: runtime-paths-v2.json uses the persistent authorized Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-progression-20261024-v1 evidence directory. This is raw evidence storage, not a second design log. No policies, seeds, commands, releases or gameplay limits change. The one gameplay case and one replay bounds remain.
