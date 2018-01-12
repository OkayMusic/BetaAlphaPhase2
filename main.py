import numpy as np
import matplotlib.pyplot as plt
import sets
from spingrid import SpinGrid


def minimize_energy(spingrid, iterations):
    if iterations > 0:
        try:
            spingrid.reduce_energy()
        except:
            print "spingrid argument must be a valid instance of SpinGrid"
            exit(1)
        return minimize_energy(spingrid, iterations - 1)
    else:
        print spingrid.total_energy()
        return spingrid

if __name__ == '__main__':
    Lattices = [SpinGrid(temperature=T) for T in range(2)]

    # for lattice in Lattices:
    #     lattice = minimize_energy(lattice, 20)

    print Lattices[0].up_counter[1]

    for i in range(20):
        for j in range(20):
            for k in range(20):
                print i, j, k
                Lattices[0].correlation(i,j,k)
    print Lattices[0].down_counter
