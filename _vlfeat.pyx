cdef extern from "<armadillo>" namespace "arma":
    cdef cppclass Mat[T]:
        unsigned int n_rows
        unsigned int n_cols
        unsigned int n_elem
        Mat()
        Mat(T*, unsigned int, unsigned int, bool, bool)
        Mat(T*, unsigned int, unsigned int)
        T *memptr()

import numpy as np

cimport cython
cimport numpy as np
from libcpp cimport bool
from cython.operator cimport dereference as deref

# datatypes:
# double, cython.double, np.double_t, np.float64_t
# float, cython.float, np.float32_t
# dtype:
# np.float, np.double, np.float64 # python float is 64 bit

cdef Mat[double] dToArmaMat(np.ndarray[double, ndim=2] X):
    if not X.flags.f_contiguous:
        X = X.copy(order="F")
    return Mat[double](<double*> X.data, X.shape[0], X.shape[1], 0, 1)

cdef Mat[float] fToArmaMat(np.ndarray[float, ndim=2] X):
    if not X.flags.f_contiguous:
        X = X.copy(order="F")
    return Mat[float](<float*> X.data, X.shape[0], X.shape[1], 0, 1)

@cython.boundscheck(False)
cdef np.ndarray[double, ndim=2] dToNdarray(Mat[double] &m):
    cdef np.ndarray[double, ndim=2] arr
    cdef double *pArr
    cdef double *pM
    arr = np.ndarray((m.n_rows, m.n_cols), dtype=np.float64, order='F')
    pArr = <double *>arr.data
    pM = m.memptr()
    for i in range(m.n_rows*m.n_cols):
        pArr[i] = pM[i]
    return arr

@cython.boundscheck(False)
cdef np.ndarray[float, ndim=2] fToNdarray(Mat[float] &m):
    cdef np.ndarray[float, ndim=2] arr
    cdef float *pArr
    cdef float *pM
    arr = np.ndarray((m.n_rows, m.n_cols), dtype=np.float32, order='F')
    pArr = <float *>arr.data
    pM = m.memptr()
    for i in range(m.n_rows*m.n_cols):
        pArr[i] = pM[i]
    return arr

      
cdef extern from "vlfeat.hpp":
    cdef void c_vl_sift "vl_sift" (Mat[float] &, Mat[double] &, Mat[float] &, \
                      int, int, int, double, double, double, double, double, \
                      bool, bool, int)
    cdef void c_vl_dsift "vl_dsift" (Mat[float] &, Mat[double] &, Mat[float] &, \
                                     Mat[double] &, Mat[double] &, Mat[double] &, \
                                     Mat[double] &, bool, bool, double, bool, int)

def vl_sift(np.ndarray[np.float32_t, ndim=2] data, 
            frames=None,
            int octaves = -1,
            int levels = -1,
            int firstOctave = -1,
            double peakThresh = -1,
            double edgeThresh = -1,
            double normThresh = -1,
            double magnif = -1,
            double windowSize = -1,
            bool orientations = False,
            bool floatDescriptors = False,
            int verbose = 0):

    cdef np.ndarray[double, ndim=2] f
    cdef np.ndarray[float, ndim=2] d
    cdef Mat[float] _I
    cdef Mat[double] _f
    cdef Mat[float] _d
    
    _I = fToArmaMat(data)
    if frames == None:
        _f = Mat[double]()
    else:
        _f = dToArmaMat(frames)
    _d = Mat[float]()

    c_vl_sift(<const Mat[float] &>_I, _f, _d, 
              octaves, levels, firstOctave, peakThresh,
              edgeThresh, normThresh, magnif, windowSize, orientations,
              floatDescriptors, verbose)
    if frames == None:
        f = dToNdarray(_f)
    else:
        f = frames
    d = fToNdarray(_d)
    
    return f, d
    
def vl_dsift(np.ndarray[float, ndim=2] data,
             bounds = None,
             step = None,
             size = None,
             geometry = None,
             bool fast = True,
             bool norm = False,
             double windowSize = -1.0,
             bool floatDescriptors = False,
             int verbose = 0):

    cdef np.ndarray[double, ndim=2] f
    cdef np.ndarray[float, ndim=2] d
    
    cdef Mat[float] _I
    cdef Mat[double] _f
    cdef Mat[float] _d
    cdef Mat[double] _bounds
    cdef Mat[double] _step
    cdef Mat[double] _size
    cdef Mat[double] _geometry
    
    _I = fToArmaMat(data)
    _f = Mat[double]()
    _d = Mat[float]()
    
    if bounds == None:
        _bounds = Mat[double]()
    else:
        _bounds = dToArmaMat(np.float64(bounds, order='F').reshape((-1,1)))
        
    if step == None:
        _step = Mat[double]()
    else:
        _step = dToArmaMat(np.float64(step, order='F').reshape((-1,1)))

    if size == None:
        _size = Mat[double]()
    else:
        _size = dToArmaMat(np.float64(size, order='F').reshape((-1,1)))
        
    if geometry == None:
        _geometry = Mat[double]()
    else:
        _geometry = dToArmaMat(np.float64(geometry, order='F').reshape((-1,1)))

    c_vl_dsift(<const Mat[float] &>_I, _f, _d,
               _bounds, _step, _size, _geometry, 
               fast, norm, windowSize, floatDescriptors, verbose)
               
    f = dToNdarray(_f)
    d = fToNdarray(_d)
    
    return f, d