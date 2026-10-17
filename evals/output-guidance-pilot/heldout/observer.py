"""Host-only fixture observation. Bytes retained locally; portable reports contain paths/deltas."""
import difflib, hashlib, threading, time

class Observer:
    def __init__(self, root, paths):
        self.root=root;self.paths=paths;self.last={p:self.read(p) for p in paths};self.events=[];self.stop=threading.Event();self.started=time.time_ns()
        self.thread=threading.Thread(target=self.run,daemon=True)
    def read(self,p):
        try:return (self.root/p).read_bytes()
        except OSError:return None
    def sample(self):
        now=time.time_ns()
        for p in self.paths:
            value=self.read(p);old=self.last[p]
            if value==old:continue
            before=(old or b'').decode(errors='replace').splitlines();after=(value or b'').decode(errors='replace').splitlines()
            diff=list(difflib.ndiff(before,after))
            self.events.append({'elapsed_ms':round((now-self.started)/1e6),'path':p,'before_sha256':hashlib.sha256(old).hexdigest() if old is not None else None,'after_sha256':hashlib.sha256(value).hexdigest() if value is not None else None,'added_lines':sum(x.startswith('+ ') for x in diff),'removed_lines':sum(x.startswith('- ') for x in diff)})
            self.last[p]=value
    def run(self):
        while not self.stop.wait(.002):self.sample()
    def start(self):self.thread.start()
    def finish(self):self.stop.set();self.thread.join();self.sample();return self.events
