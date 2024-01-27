import math
from typing import List, Tuple

PointType = Tuple[float, float]

def compute_point(length : float, count : int, total_count : int) -> PointType: 
    angle = (360 / total_count) * (math.pi / 180)
    x = math.cos(angle * count) * length
    y = math.sin(angle * count) * length
    return x, y

def compute_points(
            length : float, 
            total_count : int, 
            start_x : float = 0.0, 
            start_y : float = 0.0
        ) -> List[PointType]: 
    current_x : float = start_x
    current_y : float = start_y
    points : List[PointType] = []
    for point_index in range(total_count): 
        new_x, new_y = compute_point(length, point_index, total_count)
        points.append((
                current_x + new_x, 
                current_y + new_y
            ))
        current_x, current_y = points[-1]
    return points

def hexagon(): 
    print(compute_points(int(input("Side Length: ")), 6))

if __name__ == "__main__": 
    hexagon()

