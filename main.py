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
    TestLattice = SpinGrid(dimensions=[20, 20, 20])

    TestLattice.site_pair_distribution(0, 0, 0)

    useful_keys = []
    total_counter = []
    for keys in TestLattice.key_list:
        useful_keys.append(keys)
        total_counter.append(
            TestLattice.up_counter[keys] + TestLattice.down_counter[keys])

    plt.plot(useful_keys, total_counter)
    plt.show()
