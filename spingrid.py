import numpy as np
import matplotlib.pyplot as plt
import sets


class SpinGrid(object):

    def __init__(self, dimensions=[20, 20, 20], temperature=0):
        self.dimensions = dimensions
        self.temperature = temperature
        self.spins = np.random.choice(a=[1, -1],
                                      size=[self.dimensions[0],
                                            self.dimensions[1],
                                            self.dimensions[2]])

        # the keys for the up and down counter dicts need to be generated

        up, down = self.get_distances(5, 5, 5)
        for items in down:
            up.append(items)

        self.key_list = np.sort(list(sets.Set(up)))

        self.up_counter = {x: 0 for x in self.key_list}
        self.down_counter = {x: 0 for x in self.key_list}

    def reduce_energy(self):
        for trials in range(self.spins.size):

            x, y, z = np.random.randint(self.dimensions[0]), np.random.randint(
                self.dimensions[1]), np.random.randint(self.dimensions[2])
            self.wiggle(x, y, z)

    def wiggle(self, x, y, z):
        E_init = self.local_energy(x, y, z)
        self.spins[x, y, z] = -self.spins[x, y, z]

        E_final = self.local_energy(x, y, z)

        if (E_init <= E_final and
            np.exp((E_init - E_final) / float(self.temperature)) <
                np.random.random()):

            self.spins[x, y, z] = -self.spins[x, y, z]

    def local_energy(self, x, y, z):
        x1, y1, z1 = x + 1, y + 1, z + 1

        # take care of periodic boundary conditions
        if x == self.spins.shape[0] - 1:
            x1 = 0
        if y == self.spins.shape[1] - 1:
            y1 = 0
        if z == self.spins.shape[2] - 1:
            z1 = 0

        E = self.spins[x, y, z] * (
            self.spins[x, y, z1] + self.spins[x, y, z - 1] +
            self.spins[x1, y, z1] + self.spins[x1, y, z - 1] +
            self.spins[x, y1, z1] + self.spins[x, y1, z - 1] +
            self.spins[x1, y1, z1] + self.spins[x1, y1, z - 1])

        return E

    def total_energy(self):
        energy = 0
        for i in range(self.spins.shape[0]):
            for j in range(self.spins.shape[1]):
                for k in range(self.spins.shape[2]):
                    energy += self.local_energy(i, j, k)
        return energy

    def correlation(self, x, y, z):
        # get distances from get_distances()
        up_distances, down_distances = self.get_distances(x, y, z)

        # print up_distances, len(up_distances)
        for distances in up_distances:
            self.up_counter[distances] += 1
        counter = 0
        for keys in self.key_list:
            counter += self.up_counter[keys]
        print 'number of up distances counted = ', counter

        for distances in down_distances:
            self.down_counter[distances] += 1
        counter = 0
        for keys in self.key_list:
            counter += self.down_counter[keys]
        print 'number of down distances counted = ', counter

    def get_distances(self, x, y, z):
        # gets distances for use in correlation
        up_distances = []
        down_distances = []
        for i in range(self.spins.shape[0]):
            for j in range(self.spins.shape[1]):
                for k in range(self.spins.shape[2]):
                    # dont include distance to self
                    if i == x and j == y and k == z:
                        continue
                    # periodic boundary conditions:
                    if abs(x - i) > self.spins.shape[0] / 2:
                        if x < self.spins.shape[0] / 2:
                            i = -self.spins.shape[0] + i
                        elif x > self.spins.shape[0] / 2:
                            i = self.spins.shape[0] + i
                    if abs(y - j) > self.spins.shape[1] / 2:
                        if y < self.spins.shape[1] / 2:
                            j = -self.spins.shape[1] + j
                        elif y > self.spins.shape[1] / 2:
                            j = self.spins.shape[1] + j
                    if abs(k - z) > self.spins.shape[2] / 2:
                        if z < self.spins.shape[2] / 2:
                            k = -self.spins.shape[2] + k
                        elif z > self.spins.shape[2] / 2:
                            k = self.spins.shape[2] + k

                    D = np.sqrt((x - i)**2 + (y - j)**2 + (z - k)**2)

                    # python will be sad if we try to access out of range array
                    # elements, so here we undo periodic boundary conditions iff
                    # the lattice site was shifted 'up', as python is happy with
                    # negative array indices
                    if i > self.spins.shape[0] - 1:
                        i = i - self.spins.shape[0]
                    if j > self.spins.shape[1] - 1:
                        j = j - self.spins.shape[1]
                    if k > self.spins.shape[2] - 1:
                        k = k - self.spins.shape[2]
                    try:
                        if self.spins[i, j, k] == 1:
                            up_distances.append(D)
                        elif self.spins[i, j, k] == -1:
                            down_distances.append(D)
                    except:
                        print "spin index out of bounds, check get_distances"
                        print self.spins.shape, '\n\n'
                        print i, j, k
                        exit(1)
        print ('Number of spin up particles for temperature:',
               self.temperature, len(up_distances))
        return up_distances, down_distances
