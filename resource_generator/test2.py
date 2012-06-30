#!/usr/bin/env python3.2
d = {'1': '-', '3': '1', '2': '3', '4' : '5', '0' : '6', '6' : '9'}

print(d)
def walk(d, val):
    while val in d:
        val = d[val]
    return None if val == '-' else val

d = {k: walk(d, k) for k in d}
print(d)
