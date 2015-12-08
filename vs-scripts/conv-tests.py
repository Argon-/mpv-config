import vapoursynth as vs
import numpy as np

core = vs.get_core()
clip = video_in


def mat(dim=3, mid=1, rest=0):
    a = np.ones((dim, dim), np.int16) * rest
    a[len(a)//2,len(a)//2] = mid
    return a

def mat5x5(mid=1, rest=0):
    return mat(5, mid, rest)

def mat3x3(mid=1, rest=0):
    return mat(3, mid, rest)

def mean(val=1, dim=3):
    return mat(dim, val, val)

def gaussian():
    return np.matrix([[1, 2, 1],
                      [2, 4, 2],
                      [1, 2, 1]])

def sharpen(m=5):
    return np.matrix([[ 0, -1,  0],
                      [-1,  m, -1],
                      [ 0, -1,  0]])

def sharpen5x5():
    return np.matrix([[1,  4,    6,  4, 1],
                      [4, 16,   24, 16, 4],
                      [6, 24, -476, 24, 6],
                      [4, 16,   24, 16, 4],
                      [1,  4,    6,  4, 1]])

def outline(m=8):
    return np.matrix([[-1, -1, -1],
                      [-1,  m, -1],
                      [-1, -1, -1]])

def emboss1(m=0):
    return np.matrix([[-1, -1,  0],
                      [-1,  m,  1],
                      [ 0,  1,  1]])

def emboss2(m=0):
    return np.matrix([[-2, -1,  0],
                      [-1,  m,  1],
                      [ 0,  1,  2]])

def test(m=0, r=0):
    return np.matrix([[ 4, 2, 4],
                      [ 2, 1, 2],
                      [ 4, 2, 4]])


class Conv:
    def __init__(self, planes=[0, 1, 2], mult=0, mat=None, bias=0):
        self._p = planes
        self._mult = mult
        self._mat = mat
        self._bias = bias
    @property
    def matrix(self):
        return [i for e in self._mat.tolist() for i in e]
    @matrix.setter
    def matrix(self, mat):
        self._mat = mat
    @property
    def mult(self):
        return self._mult
    def div(self): # 0 = VS is using 1/sum(mat)
        return 1/self._mult if self._mult != 0 else 0
    @mult.setter
    def mult(self, mult):
        self._mult = mult
    @property
    def planes(self):
        return self._p
    @planes.setter
    def planes(self, p):
        self._p = p
    @property
    def bias(self):
        return self._bias
    @bias.setter
    def bias(self, b):
        self._bias = b


convs = []
#convs.append(Conv(planes=[0], mult=1/sharpen5x5().sum(), mat=sharpen5x5()))
#convs.append(Conv(planes=[1,2], mat=sharpen5x5()))
#convs.append(Conv(planes=[0], mat=sharpen5x5()))
#convs.append(Conv(planes=[1,2], mat=outline(9)))
#convs.append(Conv(planes=[0], mat=emboss1(1)))
convs.append(Conv(planes=[0], mat=test()))



for c in convs:
    clip = core.std.Convolution(clip, matrix=c.matrix, bias=c.bias, divisor=c.div(), planes=c.planes, saturate=True, mode="s")

clip.set_output()
