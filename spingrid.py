import numpy as np
import matplotlib.pyplot as plt
import sets


class SpinGrid(object):

    def __init__(self, dimensions=[20, 20, 20], temperature=0, hist_steps=20):
        self.dimensions = dimensions
        self.temperature = temperature
        self.hist_steps = hist_steps
        self.radii = np.linspace(0, 10, num=self.hist_steps)
        self.spins = np.random.choice(a=[1, -1],
                                      size=[self.dimensions[0],
                                            self.dimensions[1],
                                            self.dimensions[2]])

        # the keys for the up and down counter dicts need to be generated

        up, down = self.get_distances(5, 5, 5)
        for items in down:
            up.append(items)

        self.__key_list = np.sort(list(sets.Set(up)))
        self.key_list = [x for x in self.__key_list if x <= 10]

        # these guys keep track of the partial pair distribution
        self.up_up = {x: 0 for x in self.key_list if x <= 10}
        self.down_down = self.up_up.copy()
        self.up_down = self.up_up.copy()
        # print self.up_up

        self.norm_up_up = [0 for x in range(hist_steps)]
        self.norm_down_down = [0 for x in range(hist_steps)]
        self.norm_up_down = [0 for x in range(hist_steps)]

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

    def normalize_total_dist(self):
        """
        Take the crappy n_ij correlation functions determined by the total pair
        distribution function and turns it into a proper pair distribution
        function, as described by David Keen.
        """
        print self.hist_steps
        step_size = 10. / (self.hist_steps - 1.)

        for i in range(len(self.radii) - 1):
            # these -1's come from the definition of the total pair dist fn
            self.norm_up_up -= 1
            self.norm_up_down -= 1
            self.norm_up_down -= 1
            for keys in self.up_up:
                if keys >= self.radii[i] and keys < self.radii[i + 1]:
                    # here I set rho_j = 1, which is true in my units

                    r_sq = ((self.radii[i] - self.radii[i + 1]) / 2.)**2.
                    prefactor = 1. / (4. * np.pi * r_sq * step_size)

                    self.norm_up_up[i] += prefactor * self.up_up[keys]
                    self.norm_down_down[i] += prefactor * self.down_down[keys]
                    self.norm_up_down[i] += prefactor * self.up_down[keys]

    def total_pair_distribution(self):
        # first, calculate all the sulphur-iodine pdfs
        for i in range(self.spins.shape[0] / 4):
            for j in range(self.spins.shape[1] / 4):
                for k in range(self.spins.shape[2] / 4):
                    self.site_pair_distribution(i, j, k)

    def site_pair_distribution(self, x, y, z):
        site_type = self.spins[x, y, z]
        # get distances from get_distances()
        up_distances, down_distances = self.get_distances(
            x, y, z, truncate=True)

        if site_type == 1:
            n = 0
            for keys in self.up_up:
                # print keys, n
                # print type(self.up_up)
                self.up_up[keys] += up_distances.count(keys)
                self.up_down[keys] += down_distances.count(keys)
        elif site_type == -1:
            for keys in self.key_list:
                # print type(self.up_down)
                self.up_down[keys] += up_distances.count(keys)
                self.down_down[keys] += down_distances.count(keys)
        else:
            print "error! Check SpinGrid.spins!"
            return(1)

    def get_distances(self, x, y, z, truncate=False):
        # gets distances for use in correlation
        print x, y, z
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

                    # The lattice does funny things depending on z odd or even
                    if (z - k) % 2 == 0:
                        D = np.sqrt((x - i)**2 + (y - j) **
                                    2 + ((z - k) / 2.)**2)
                    else:
                        D = np.sqrt((x - i + 0.5)**2 + (y - j + 0.5)
                                    ** 2 + ((z - k) / 2.)**2)
                    if D == np.sqrt(0.5):
                        print x, y, z, i, j, k

                        A = (x - i + 0.5) ** 2
                        B = (y - j + 0.5) ** 2
                        C = ((z - k) / 2)**2
                        print A, B, C

                    if truncate == True:
                        if D > 10:
                            continue

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

        # print up_distances, down_distances

        return up_distances, down_distances
