
/*
 Copyright (C) 2000, 2001, 2002 RiskMap srl

 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it under the
 terms of the QuantLib license.  You should have received a copy of the
 license along with this program; if not, please email ferdinando@ametrano.net
 The license is also available online at http://quantlib.org/html/license.html

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

// $Id$

#ifndef quantlib_linear_algebra_i
#define quantlib_linear_algebra_i

%include common.i
%include types.i
%include stl.i

%{
using QuantLib::Array;
using QuantLib::ArrayFormatter;
using QuantLib::IndexError;
%}

#if defined(SWIGPYTHON)
%{
bool extractArray(PyObject* source, Array* target) {
    if (PyTuple_Check(source) || PyList_Check(source)) {
        int size = (PyTuple_Check(source) ?
                    PyTuple_Size(source) :
                    PyList_Size(source));
        *target = Array(size);
        for (int i=0; i<size; i++) {
            PyObject* o = PySequence_GetItem(source,i);
            if (PyFloat_Check(o)) {
                (*target)[i] = PyFloat_AsDouble(o);
                Py_DECREF(o);
            } else if (PyInt_Check(o)) {
                (*target)[i] = double(PyInt_AsLong(o));
                Py_DECREF(o);
            } else {
                Py_DECREF(o);
                return false;
            }
        }
        return true;
    } else {
        return false;
    }
}
%}

%typemap(in) Array (Array* v) {
    if (extractArray($input,&$1)) {
        ;
    } else {
        SWIG_ConvertPtr($input,(void **) &v, $&1_descriptor,1);
        $1 = *v;
    }
};

%typemap(in) const Array& (Array temp) {
    if (extractArray($input,&temp)) {
        $1 = &temp;
    } else {
        SWIG_ConvertPtr($input,(void **) &$1,$1_descriptor,1);
    }
};
#elif defined(SWIGRUBY)
%typemap(in) Array (Array* v) {
    if (rb_obj_is_kind_of($input,rb_cArray)) {
        unsigned int size = RARRAY($input)->len;
        $1 = Array(size);
        for (unsigned int i=0; i<size; i++) {
            VALUE o = RARRAY($input)->ptr[i];
            if (TYPE(o) == T_FLOAT)
                (($1_type &)$1)[i] = NUM2DBL(o);
            else if (FIXNUM_P(o))
                (($1_type &)$1)[i] = double(FIX2INT(o));
            else
                rb_raise(rb_eTypeError,
                         "wrong argument type"
                         " (expected Array)");
        }
    } else {
        #if SWIG_VERSION <= 0x010313
        $1 = *(($&1_type) SWIG_ConvertPtr($input,$&1_descriptor));
        #else
        SWIG_ConvertPtr($input,(void **) &v,$&1_descriptor,1);
        $1 = *v;
        #endif
    }
}
%typemap(in) const Array& (Array temp),
             const Array* (Array temp) {
    if (rb_obj_is_kind_of($input,rb_cArray)) {
        unsigned int size = RARRAY($input)->len;
        temp = Array(size);
        $1 = &temp;
        for (unsigned int i=0; i<size; i++) {
            VALUE o = RARRAY($input)->ptr[i];
            if (TYPE(o) == T_FLOAT)
                temp[i] = NUM2DBL(o);
            else if (FIXNUM_P(o))
                temp[i] = double(FIX2INT(o));
            else
                rb_raise(rb_eTypeError,
                         "wrong argument type"
                         " (expected Array)");
        }
    } else {
        #if SWIG_VERSION <= 0x010313
        $1 = ($1_ltype) SWIG_ConvertPtr($input,$1_descriptor);
        #else
        SWIG_ConvertPtr($input,(void **) &$1,$1_descriptor,1);
        #endif
    }
}
#elif defined(SWIGMZSCHEME)
%typemap(in) Array {
    if (SCHEME_VECTORP($input)) {
        unsigned int size = SCHEME_VEC_SIZE($input);
        $1 = Array(size);
        Scheme_Object** items = SCHEME_VEC_ELS($input);
        for (unsigned int i=0; i<size; i++) {
            Scheme_Object* o = items[i];
            if (SCHEME_REALP(o))
                (($1_type &)$1)[i] = scheme_real_to_double(o);
            else
                scheme_wrong_type(FUNC_NAME, "Array", 
                                  $argnum, argc, argv);
        }
    } else {
        $1 = *(($&1_type)
               SWIG_MustGetPtr($input,$&1_descriptor,$argnum));
    }
}
%typemap(in) const Array& (Array temp),
             const Array* (Array temp) {
    if (SCHEME_VECTORP($input)) {
        unsigned int size = SCHEME_VEC_SIZE($input);
        temp = Array(size);
        $1 = &temp;
        Scheme_Object** items = SCHEME_VEC_ELS($input);
        for (unsigned int i=0; i<size; i++) {
            Scheme_Object* o = items[i];
            if (SCHEME_REALP(o))
                temp[i] = scheme_real_to_double(o);
            else
                scheme_wrong_type(FUNC_NAME, "Array", 
                                  $argnum, argc, argv);
        }
    } else {
        $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum);
    }
}
#elif defined(SWIGGUILE)
%typemap(in) Array {
    if (gh_vector_p($input)) {
        unsigned long size = gh_vector_length($input);
        $1 = Array(size);
        double* data = gh_scm2doubles($input,NULL);
        std::copy(data,data+size,$1.begin());
        free(data);
    } else {
        $1 = *(($&1_type)
               SWIG_MustGetPtr($input,$&1_descriptor,$argnum));
    }
}
%typemap(in) const Array& (Array temp),
             const Array* (Array temp) {
    if (gh_vector_p($input)) {
        unsigned long size = gh_vector_length($input);
        temp = Array(size);
        $1 = &temp;
        double* data = gh_scm2doubles($input,NULL);
        std::copy(data,data+size,temp.begin());
        free(data);
    } else {
        $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum);
    }
}
#endif

#if defined(SWIGPYTHON) || defined(SWIGRUBY)
%rename(__len__) Array::size;
#endif

#if defined(SWIGMZSCHEME) || defined(SWIGGUILE)
%rename("length")  Array::size;
%rename("add")     Array::__add__;
%rename("sub")     Array::__sub__;
%rename("div")     Array::__div__;
%rename(">string") Array::__str__;
%rename("set!")    Array::set;
// aliases
#if defined(SWIGGUILE)
%scheme %{
    (define Array+ Array-add)
    (define Array- Array-sub)
    (define (Array* a x)
      (if (number? x)
          (Array-mul-d a x)
          (Array-mul-a a x)))
    (define Array/ Array-div)
    (export Array+
            Array-
            Array*
            Array/)
%}
#endif
#endif
ReturnByValue(Array);

class Array {
  public:
    Array(Size n, double fill = 0);
    Size size() const;
};

%extend Array {
    std::string __str__() {
        return ArrayFormatter::toString(*self);
    }

    Array __add__(const Array& a) {
        return Array(*self+a);
    }
    Array __sub__(const Array& a) {
        return Array(*self-a);
    }
    Array mul_d(double a) {
        return Array(*self*a);
    }
    double mul_a(const Array& a) {
        return QuantLib::DotProduct(*self,a);
    }
    Array __div__(double a) {
        return Array(*self/a);
    }

    #if defined(SWIGPYTHON)
    Array __getslice__(int i, int j) {
        int size_ = static_cast<int>(self->size());
        if (i<0)
            i = size_+i;
        if (j<0)
            j = size_+j;
        i = QL_MAX(0,i);
        j = QL_MIN(size_,j);
        Array tmp(j-i);
        std::copy(self->begin()+i,self->begin()+j,tmp.begin());
        return tmp;
    }
    void __setslice__(int i, int j, const Array& rhs) {
        int size_ = static_cast<int>(self->size());
        if (i<0)
            i = size_+i;
        if (j<0)
            j = size_+j;
        i = QL_MAX(0,i);
        j = QL_MIN(size_,j);
        QL_ENSURE(static_cast<int>(rhs.size()) == j-i,
            "Arrays are not resizable");
        std::copy(rhs.begin(),rhs.end(),self->begin()+i);
    }
    bool __nonzero__() {
        return (self->size() != 0);
    }
    #endif

    #if defined(SWIGRUBY)
    void each() {
        for (unsigned int i=0; i<self->size(); i++)
            rb_yield(rb_float_new((*self)[i]));
    }
    #endif

    #if defined(SWIGPYTHON) || defined(SWIGRUBY)
    double __getitem__(int i) {
        int size_ = static_cast<int>(self->size());
        if (i>=0 && i<size_) {
            return (*self)[i];
        } else if (i<0 && -i<=size_) {
            return (*self)[size_+i];
        } else {
            throw IndexError("Array index out of range");
        }
        QL_DUMMY_RETURN(0.0)
    }
    void __setitem__(int i, double x) {
        int size_ = static_cast<int>(self->size());
        if (i>=0 && i<size_) {
            (*self)[i] = x;
        } else if (i<0 && -i<=size_) {
            (*self)[size_+i] = x;
        } else {
            throw IndexError("Array index out of range");
        }
    }
    #endif

    #if defined(SWIGMZSCHEME) || defined(SWIGGUILE)
    double ref(Size i) {
        if (i<self->size())
            return (*self)[i];
        else
            throw IndexError("Array index out of range");
        QL_DUMMY_RETURN(0.0)
    }
    void set(Size i, double x) {
        if (i<self->size())
            (*self)[i] = x;
        else
            throw IndexError("Array index out of range");
    }
    #endif

};



// 2-D view

%{
typedef QuantLib::Math::LexicographicalView<Array::iterator>  
    LexicographicalView;
typedef QuantLib::Math::LexicographicalView<Array::iterator>::y_iterator 
    LexicographicalViewColumn;
%}

#if defined(SWIGPYTHON) || defined(SWIGRUBY)
class LexicographicalViewColumn {
  private:
    // access control - no constructor exported
    LexicographicalViewColumn();
};

%extend LexicographicalViewColumn {
    double __getitem__(int i) {
        return (*self)[i];
    }
    void __setitem__(int i, double x) {
        (*self)[i] = x;
    }
};
#endif

#if defined(SWIGMZSCHEME) || defined(SWIGGUILE)
%rename(">string") LexicographicalView::__str__;
%rename("set!")    LexicographicalView::set;
#endif

class LexicographicalView {
  public:
    Size xSize() const;
    Size ySize() const;
};

%extend LexicographicalView {
    LexicographicalView(Array& a, Size xSize) {
        return new LexicographicalView(a.begin(),a.end(),xSize);
    }
    std::string __str__() {
        std::string s;
        for (int j=0; j<static_cast<int>(self->ySize()); j++) {
    	    s += "\n";
            for (int i=0; i<static_cast<int>(self->xSize()); i++) {
                if (i != 0)
                    s += ",";
                s += DoubleFormatter::toString((*self)[i][j]);
            }
        }
        s += "\n";
        return s;
    }

    #if defined(SWIGPYTHON) || defined(SWIGRUBY)
    LexicographicalViewColumn __getitem__(Size i) {
        return (*self)[i];
    }
    #endif
    
    #if defined(SWIGMZSCHEME) || defined(SWIGGUILE)
    double ref(Size i, Size j) {
        return (*self)[i][j];
    }
    void set(Size i, Size j, double x) {
        (*self)[i][j] = x;
    }
    #endif

};


// matrix class
%{
using QuantLib::Math::Matrix;
typedef QuantLib::Math::Matrix::row_iterator MatrixRow;
using QuantLib::Math::outerProduct;
using QuantLib::Math::transpose;
using QuantLib::Math::matrixSqrt;
%}

#if defined(SWIGPYTHON) || defined(SWIGRUBY)
class MatrixRow {
  private:
    MatrixRow();
  public:
    %extend {
        double __getitem__(int i) {
            return (*self)[i];
        }
        void __setitem__(int i, double x) {
            (*self)[i] = x;
        }
    }
};
#endif


#if defined(SWIGPYTHON)
// typemap Python list of lists of numbers to Matrix
%typemap(in) Matrix (Matrix* m) {
    if (PyTuple_Check($input) || PyList_Check($input)) {
        Size rows, cols;
        rows = (PyTuple_Check($input) ?
                PyTuple_Size($input) :
                PyList_Size($input));
        if (rows > 0) {
            // look ahead
            PyObject* o = PySequence_GetItem($input,0);
            if (PyTuple_Check(o) || PyList_Check(o)) {
                cols = (PyTuple_Check(o) ?
                        PyTuple_Size(o) :
                        PyList_Size(o));
                Py_DECREF(o);
            } else {
                PyErr_SetString(PyExc_TypeError, "Matrix expected");
                Py_DECREF(o);
                return NULL;
            }
        } else {
            cols = 0;
        }
        $1 = Matrix(rows,cols);
        for (Size i=0; i<rows; i++) {
            PyObject* o = PySequence_GetItem($input,i);
            if (PyTuple_Check(o) || PyList_Check(o)) {
                Size items = (PyTuple_Check(o) ?
                                        PyTuple_Size(o) :
                                        PyList_Size(o));
                if (items != cols) {
                    PyErr_SetString(PyExc_TypeError, 
                        "Matrix must have equal-length rows");
                    Py_DECREF(o);
                    return NULL;
                }
                for (Size j=0; j<cols; j++) {
                    PyObject* d = PySequence_GetItem(o,j);
                    if (PyFloat_Check(d)) {
                        $1[i][j] = PyFloat_AsDouble(d);
                        Py_DECREF(d);
                    } else if (PyInt_Check(d)) {
                        $1[i][j] = double(PyInt_AsLong(d));
                        Py_DECREF(d);
                    } else {
                        PyErr_SetString(PyExc_TypeError,"doubles expected");
                        Py_DECREF(d);
                        Py_DECREF(o);
                        return NULL;
                    }
                }
                Py_DECREF(o);
            } else {
                PyErr_SetString(PyExc_TypeError, "Matrix expected");
                Py_DECREF(o);
                return NULL;
            }
        }
    } else {
        SWIG_ConvertPtr($input,(void **) &m,$&1_descriptor,1);
        $1 = *m;
    }
};
%typemap(in) const Matrix & (Matrix temp) {
    if (PyTuple_Check($input) || PyList_Check($input)) {
        Size rows, cols;
        rows = (PyTuple_Check($input) ?
                PyTuple_Size($input) :
                PyList_Size($input));
        if (rows > 0) {
            // look ahead
            PyObject* o = PySequence_GetItem($input,0);
            if (PyTuple_Check(o) || PyList_Check(o)) {
                cols = (PyTuple_Check(o) ?
                        PyTuple_Size(o) :
                        PyList_Size(o));
                Py_DECREF(o);
            } else {
                PyErr_SetString(PyExc_TypeError, "Matrix expected");
                Py_DECREF(o);
                return NULL;
            }
        } else {
            cols = 0;
        }

        temp = Matrix(rows,cols);
        for (Size i=0; i<rows; i++) {
            PyObject* o = PySequence_GetItem($input,i);
            if (PyTuple_Check(o) || PyList_Check(o)) {
                Size items = (PyTuple_Check(o) ?
                                        PyTuple_Size(o) :
                                        PyList_Size(o));
                if (items != cols) {
                    PyErr_SetString(PyExc_TypeError, 
                        "Matrix must have equal-length rows");
                    Py_DECREF(o);
                    return NULL;
                }
                for (Size j=0; j<cols; j++) {
                    PyObject* d = PySequence_GetItem(o,j);
                    if (PyFloat_Check(d)) {
                        temp[i][j] = PyFloat_AsDouble(d);
                        Py_DECREF(d);
                    } else if (PyInt_Check(d)) {
                        temp[i][j] = double(PyInt_AsLong(d));
                        Py_DECREF(d);
                    } else {
                        PyErr_SetString(PyExc_TypeError,"doubles expected");
                        Py_DECREF(d);
                        Py_DECREF(o);
                        return NULL;
                    }
                }
                Py_DECREF(o);
            } else {
                PyErr_SetString(PyExc_TypeError, "Matrix expected");
                Py_DECREF(o);
                return NULL;
            }
        }
        $1 = &temp;
    } else {
        SWIG_ConvertPtr($input,(void **) &$1,$1_descriptor,1);
    }
};
#elif defined(SWIGRUBY)
%typemap(in) Matrix (Matrix* m) {
    if (rb_obj_is_kind_of($input,rb_cArray)) {
        Size rows, cols;
        rows = RARRAY($input)->len;
        if (rows > 0) {
            VALUE o = RARRAY($input)->ptr[0];
            if (rb_obj_is_kind_of(o,rb_cArray)) {
                cols = RARRAY(o)->len;
            } else {
                rb_raise(rb_eTypeError,
                         "wrong argument type (expected Matrix)");
            }
        } else {
            cols = 0;
        }
        $1 = Matrix(rows,cols);
        for (Size i=0; i<rows; i++) {
            VALUE o = RARRAY($input)->ptr[i];
            if (rb_obj_is_kind_of(o,rb_cArray)) {
                if (RARRAY(o)->len != cols) {
                    rb_raise(rb_eTypeError,
                             "Matrix must have equal-length rows");
                }
                for (Size j=0; j<cols; j++) {
                    VALUE x = RARRAY(o)->ptr[j];
                    if (SWIG_FLOAT_P(x))
                        $1[i][j] = SWIG_NUM2DBL(x);
                    else
                        rb_raise(rb_eTypeError,
                                 "wrong argument type (expected Matrix)");
                }
            } else {
                rb_raise(rb_eTypeError,
                         "wrong argument type (expected Matrix)");
            }
        }
    } else {
        #if SWIG_VERSION <= 0x010313
        $1 = *(($&1_type) SWIG_ConvertPtr($input,$&1_descriptor));
        #else
        SWIG_ConvertPtr($input,(void **) &m,$&1_descriptor,1);
        $1 = *m;
        #endif
    }
}
%typemap(in) const Matrix& (Matrix temp),
             const Matrix* (Matrix temp) {
    if (rb_obj_is_kind_of($input,rb_cArray)) {
        Size rows, cols;
        rows = RARRAY($input)->len;
        if (rows > 0) {
            VALUE o = RARRAY($input)->ptr[0];
            if (rb_obj_is_kind_of(o,rb_cArray)) {
                cols = RARRAY(o)->len;
            } else {
                rb_raise(rb_eTypeError,
                         "wrong argument type (expected Matrix)");
            }
        } else {
            cols = 0;
        }
        temp = Matrix(rows,cols);
        $1 = &temp;
        for (Size i=0; i<rows; i++) {
            VALUE o = RARRAY($input)->ptr[i];
            if (rb_obj_is_kind_of(o,rb_cArray)) {
                if (RARRAY(o)->len != cols) {
                    rb_raise(rb_eTypeError,
                             "Matrix must have equal-length rows");
                }
                for (Size j=0; j<cols; j++) {
                    VALUE x = RARRAY(o)->ptr[j];
                    if (SWIG_FLOAT_P(x))
                        temp[i][j] = SWIG_NUM2DBL(x);
                    else
                        rb_raise(rb_eTypeError,
                                 "wrong argument type (expected Matrix)");
                }
            } else {
                rb_raise(rb_eTypeError,
                         "wrong argument type (expected Matrix)");
            }
        }
    } else {
        #if SWIG_VERSION <= 0x010313
        $1 = ($1_ltype) SWIG_ConvertPtr($input,$1_descriptor);
        #else
        SWIG_ConvertPtr($input,(void **) &$1,$1_descriptor,1);
        #endif
    }
}
#elif defined(SWIGMZSCHEME)
%typemap(in) Matrix {
    if (SCHEME_VECTORP($input)) {
        Size rows, cols;
        rows = SCHEME_VEC_SIZE($input);
        Scheme_Object** items = SCHEME_VEC_ELS($input);
        if (rows > 0) {
            if (SCHEME_VECTORP(items[0])) {
                cols = SCHEME_VEC_SIZE(items[0]);
            } else {
                cols = 0;
            }
        }
        $1 = Matrix(rows,cols);
        for (Size i=0; i<rows; i++) {
            Scheme_Object* o = items[i];
            if (SCHEME_VECTORP(o)) {
                if (SCHEME_VEC_SIZE(o) != cols) {
                    scheme_wrong_type(FUNC_NAME, "Matrix", 
                                      $argnum, argc, argv);
                }
                Scheme_Object** els = SCHEME_VEC_ELS(o);
                for (Size j=0; j<cols; j++) {
                    Scheme_Object* x = els[j];
                    if (SCHEME_REALP(x))
                        $1[i][j] = scheme_real_to_double(x);
                    else
                        scheme_wrong_type(FUNC_NAME, "Matrix", 
                                          $argnum, argc, argv);
                }
            } else {
                scheme_wrong_type(FUNC_NAME, "Matrix", 
                                  $argnum, argc, argv);
            }
        }
    } else {
        $1 = *(($&1_type)
               SWIG_MustGetPtr($input,$&1_descriptor,$argnum));
    }
}
%typemap(in) const Matrix& (Matrix temp),
             const Matrix* (Matrix temp) {
    if (SCHEME_VECTORP($input)) {
        Size rows, cols;
        rows = SCHEME_VEC_SIZE($input);
        Scheme_Object** items = SCHEME_VEC_ELS($input);
        if (rows > 0) {
            if (SCHEME_VECTORP(items[0])) {
                cols = SCHEME_VEC_SIZE(items[0]);
            } else {
                cols = 0;
            }
        }
        temp = Matrix(rows,cols);
        $1 = &temp;
        for (Size i=0; i<rows; i++) {
            Scheme_Object* o = items[i];
            if (SCHEME_VECTORP(o)) {
                if (SCHEME_VEC_SIZE(o) != cols) {
                    scheme_wrong_type(FUNC_NAME, "Matrix", 
                                      $argnum, argc, argv);
                }
                Scheme_Object** els = SCHEME_VEC_ELS(o);
                for (Size j=0; j<cols; j++) {
                    Scheme_Object* x = els[j];
                    if (SCHEME_REALP(x))
                        temp[i][j] = scheme_real_to_double(x);
                    else
                        scheme_wrong_type(FUNC_NAME, "Matrix", 
                                          $argnum, argc, argv);
                }
            } else {
                scheme_wrong_type(FUNC_NAME, "Matrix", 
                                  $argnum, argc, argv);
            }
        }
    } else {
        $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum);
    }
}
#elif defined(SWIGGUILE)
%typemap(in) Matrix {
    if (gh_vector_p($input)) {
        Size rows, cols;
        rows = gh_vector_length($input);
        if (rows > 0) {
            SCM o = gh_vector_ref($input,gh_long2scm(0));
            if (gh_vector_p(o)) {
                cols = gh_vector_length($input);
            } else {
                scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
            }
        } else {
            cols = 0;
        }
        $1 = Matrix(rows,cols);
        for (Size i=0; i<rows; i++) {
            SCM o = gh_vector_ref($input,gh_long2scm(i));
            if (gh_vector_p(o)) {
                if (gh_vector_length(o) != cols)
                    scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
                double* data = gh_scm2doubles(o,NULL);
                std::copy(data,data+cols,$1.row_begin(i));
                free(data);
            } else {
                scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
            }
        }
    } else {
        $1 = *(($&1_type) SWIG_MustGetPtr($input,$&1_descriptor,$argnum));
    }
}
%typemap(in) const Matrix& (Matrix temp),
             const Matrix* (Matrix temp) {
    if (gh_vector_p($input)) {
        Size rows, cols;
        rows = gh_vector_length($input);
        if (rows > 0) {
            SCM o = gh_vector_ref($input,gh_long2scm(0));
            if (gh_vector_p(o)) {
                cols = gh_vector_length($input);
            } else {
                scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
            }
        } else {
            cols = 0;
        }
        temp = Matrix(rows,cols);
        $1 = &temp;
        for (Size i=0; i<rows; i++) {
            SCM o = gh_vector_ref($input,gh_long2scm(i));
            if (gh_vector_p(o)) {
                if (gh_vector_length(o) != cols)
                    scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
                double* data = gh_scm2doubles(o,NULL);
                std::copy(data,data+cols,temp.row_begin(i));
                free(data);
            } else {
                scm_wrong_type_arg((char *) FUNC_NAME, $argnum, $input);
            }
        }
    } else {
        $1 = ($1_ltype) SWIG_MustGetPtr($input,$1_descriptor,$argnum);
    }
}
#endif

#if defined(SWIGMZSCHEME) || defined(SWIGGUILE)
%rename("set!")     Matrix::setitem;
%rename(">string")  Matrix::__str__;
%rename("add")      Matrix::__add__;
%rename("sub")      Matrix::__sub__;
%rename("mul")      Matrix::__mul__;
%rename("div")      Matrix::__div__;
%rename("Matrix-transpose")    transpose;
%rename("Array-outer-product") outerProduct;
%rename("Array-inner-product") innerProduct;
%rename("Matrix-product")      matrixProduct;
%rename("Matrix-sqrt")         matrixSqrt;
// aliases
#if defined(SWIGGUILE)
%scheme %{
    (define Matrix+ Matrix-add)
    (define Matrix- Matrix-sub)
    (define Matrix* Matrix-mul)
    (define Matrix/ Matrix-div)
    (export Matrix+
            Matrix-
            Matrix*
            Matrix/)
%}
#endif
#endif
ReturnByValue(Matrix);

class Matrix {
  public:
    Matrix(Size rows, Size columns, double fill = 0.0);
    Size rows() const;
    Size columns() const;
};

%extend Matrix {
    std::string __str__() {
        std::string s;
        for (Size j=0; j<self->rows(); j++) {
    	    s += "\n";
            s += QuantLib::DoubleFormatter::toString((*self)[j][0]);
            for (Size i=1; i<self->columns(); i++) {
                s += ",";
                s += QuantLib::DoubleFormatter::toString((*self)[j][i]);
            }
        }
        s += "\n";
        return s;
    }
    Matrix __add__(const Matrix& m) {
        return *self+m;
    }
    Matrix __sub__(const Matrix& m) {
        return *self-m;
    }
    Matrix __mul__(double x) {
        return *self*x;
    }
    Matrix __div__(double x) {
        return *self/x;
    }
    #if defined(SWIGPYTHON) || defined(SWIGRUBY)
    MatrixRow __getitem__(Size i) {
        return (*self)[i];
    }
    #elif defined(SWIGMZSCHEME) || defined(SWIGGUILE)
    double ref(Size i, Size j) {
        return (*self)[i][j];
    }
    void setitem(Size i, Size j, double x) {
        (*self)[i][j] = x;
    }
    #endif
    #if defined(SWIGPYTHON)
    Matrix __rmul__(double x) {
        return *self*x;
    }
    #endif
};


// functions
Matrix transpose(const Matrix& m);
Matrix outerProduct(const Array& v1, const Array& v2);
%inline %{
    Matrix matrixProduct(const Matrix& m1, const Matrix& m2) {
        return m1*m2;
    }
    Array innerProduct(const Array& a, const Matrix& m) {
        return a*m;
    }
%}
Matrix matrixSqrt(const Matrix& m);



#endif