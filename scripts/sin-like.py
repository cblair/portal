import json, math, random, time

x = 0

while True:
    y = math.sin(x) + random.random() / 5
    f = open('../public/sin.json', 'w')
    json.dump({'x': x, 'y': y}, f)
    f.close()
    x += random.random()
    time.sleep(5)
