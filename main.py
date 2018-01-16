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

    counter = 0
    Lattices[0].correlation(0, 0, 0)
    for keys in Lattices[0].key_list:
        counter += Lattices[0].up_counter[keys]
    print counter

    total_counter = []

    for keys in Lattices[0].key_list:
        total_counter.append(Lattices[0].up_counter[keys])
        total_counter.append(why)

    counter = 0
    for items in total_counter:
        counter += items
    print 'mem', counter

    plt.plot(Lattices[0].key_list, total_counter)
    plt.show()
