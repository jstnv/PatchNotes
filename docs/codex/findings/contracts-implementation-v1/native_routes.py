from run_checks import run
for creation,policy in [("current","ordinary"),("legacy","synergy"),("lease","synergy")]:
    for arm in ["trial","sidestreet","none"]:
        run(f"native-{creation}-{policy}-{arm}",["--script","res://scripts/debug/publisher_native_route.gd","--",f"--creation={creation}",f"--policy={policy}",f"--arm={arm}"],timeout=240)
