import sys, threading, time
sys.path.insert(0, sys.argv[1]); sys.path.insert(0, sys.argv[2])
import mari, marinp
src = "flowchart LR\n" + "\n".join(f"  n{i} --> n{i+1}" for i in range(40))
def run(f, label):
    n = [0]; stop = [False]
    def spin():
        while not stop[0]: n[0] += 1
    th = threading.Thread(target=spin); th.start()
    t = time.perf_counter()
    for _ in range(100): f(src)
    dt = time.perf_counter() - t; stop[0] = True; th.join()
    print(f"{label}: 100 draws in {dt*1000:.0f} ms, other Python thread counted to {n[0]:,}")
sys.setswitchinterval(0.005)
run(lambda s: mari.draw(s), "ctypes (lets go of the GIL)")
run(marinp.svg, "nimpy  (holds the GIL)     ")
