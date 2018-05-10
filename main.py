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
        if iterations % 5 == 0:
            if spingrid.total_energy() == -64000:
                return spingrid
        return minimize_energy(spingrid, iterations - 1)
    else:
        print spingrid.total_energy()
        return spingrid


if __name__ == '__main__':
    TestLattice = SpinGrid(
        dimensions=[20, 20, 20], temperature=0.01, hist_steps=1000)

    minimize_energy(TestLattice, 100)
    TestLattice.total_pair_distribution()

    useful_keys = []
    total_counter_parallel = []
    total_counter_antiparallel = []
    for keys in TestLattice.key_list:
        useful_keys.append(keys)
        total_counter_parallel.append(
            TestLattice.up_up[keys] + TestLattice.down_down[keys])
        total_counter_antiparallel.append(TestLattice.up_down[keys])

    TestLattice.normalize_total_dist()

    print TestLattice.radii

    print TestLattice.norm_up_up

    plt.bar(TestLattice.radii, TestLattice.norm_up_up, width=0.01)
    # plt.plot(useful_keys, total_counter_parallel)
    # plt.plot(useful_keys, total_counter_antiparallel)

    plt.show()
