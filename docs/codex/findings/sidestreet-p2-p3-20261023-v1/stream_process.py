"""Bounded engine runner with live log and early fatal-script termination."""
from pathlib import Path
import subprocess,time,datetime

def bind(sim):
    def run(label,argv,output,environment,timeout):
        command={'argv':argv,'cwd':str(output),'timeout_seconds':timeout,'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'headless':'--headless' in argv}
        path=output/(label+'.log');started=time.monotonic()
        with path.open('wb') as log:
            process=subprocess.Popen(argv,cwd=output,env=environment,stdout=log,stderr=subprocess.STDOUT,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            command['pid']=process.pid;sim.write_json(output/(label+'.command.json'),command)
            while process.poll() is None:
                if time.monotonic()-started>timeout:
                    command['termination']='declared timeout';process.kill();break
                text=path.read_text(encoding='utf8',errors='replace')
                if 'SCRIPT ERROR' in text:
                    command['termination']='fatal script error; do not leave an idle engine';process.kill();break
                time.sleep(.25)
            process.wait()
        text=path.read_text(encoding='utf8',errors='replace')
        errors=[line for line in text.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line) and 'root certificate store' not in line]
        command.update(exit=process.returncode,elapsed_seconds=time.monotonic()-started,errors=errors)
        sim.write_json(output/(label+'.command.json'),command)
        if process.returncode or errors:raise RuntimeError(label+' failed; see live log '+str(path))
        return command
    sim.run_process=run
