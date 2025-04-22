# map-converter.py

# convert the cluj-map.txt (sample below)
# 012345678901234567890123456789012345678901234567890123
# 1RRRHHHHHHHHHHHHRHHHHHHHHHHHHHRPHHHRRHHHHHHHHHHHHRHHHH
# 2HHHRRHHHHHHHHHHRHHHHHHHHHHHHRPPHHRRHHHHHHHHHHHHHRHHHH

# into a format easy to load into netlogo
#    ; We store them in a double list (ex [[1 1 9.9999] [1 2 9.9999] ...
# sample data:
#  -17 17 9.9999 -16 17 9.9999 -15 17 9.9999  
# note there is only whitespace, no lfs

# cluj-map.txt is 53x53 plus one header row, and a key column on the left.
# so we need to skip the header row, and the key column.

# the output should be a list of lists, each containing 3 elements:
# [x y value]

# here are color mappings:
# H - brown
# R - green
# P - blue
# C - gray

# in python string to float, an enum:

mappings = {
    'H': 33.0,
    'R': 95.0,
    'P': 55.0,
    'C': 4.0
}

side = 53
half_side = (side // 2)
x_start = 0 - half_side
y_start = half_side

output_file = open('cluj-data.txt', 'w')

with open('cluj-map.txt', 'r') as f:
    y_counter = y_start
    for line in f:
        x_counter = x_start
        if line.startswith('x'):
            continue
        for i in range(1, len(line)):
            if line[i] == 'H':
                output_file.write(f"{x_counter} {y_counter} {mappings['H']} ")
            elif line[i] == 'R':
                output_file.write(f"{x_counter} {y_counter} {mappings['R']} ")
            elif line[i] == 'P':
                output_file.write(f"{x_counter} {y_counter} {mappings['P']} ")
            elif line[i] == 'C':
                output_file.write(f"{x_counter} {y_counter} {mappings['C']} ")
            x_counter += 1
        y_counter -= 1
        output_file.write("\n")
