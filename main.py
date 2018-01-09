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

    Lattices[0].correlation(1, 1, 1)

    print Lattices[0].down_counter[4]
