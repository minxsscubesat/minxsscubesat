import time

while 1:
    t0 = time.time()
    #Don't do anything for a while so we don't interfere with this pass
    while time.time()-t0 < 9.65:
        time.sleep(.01)
    print("Time: ", time.time())