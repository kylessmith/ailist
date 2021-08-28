from __future__ import division, print_function, absolute_import
import numpy as np


# Python 3
MyFileNotFoundError = FileNotFoundError

# Library name
libname = "ailist"
# Build type
build_type = "optimized"
#build_type="debug"

# Descriptions of package
SHORTDESC = "Python package for Augmented Interval List"
with open("README.md", "r") as fh:
    long_description = fh.read()
#DESC = """A python package wrapper for a C implementation of an Augmented Interval List."""

# Directories (relative to the top-level directory where setup.py resides) in which to look for data files.
datadirs  = ("tests","ailist/src")
# File extensions to be considered as data files. (Literal, no wildcards.)
dataexts  = (".py",  ".pyx", ".pxd",  ".c",".h")
# Standard documentation to detect (and package if it exists).
standard_docs     = ["README", "LICENSE", "TODO", "CHANGELOG", "AUTHORS"]
standard_doc_exts = [".md", ".rst", ".txt", ""]

#########################################################
# Init
#########################################################

# check for Python 3.0 or later
import sys
if sys.version_info < (3,0):
    sys.exit('Sorry, Python < 3.0 is not supported')

import os

from setuptools import setup
from setuptools.extension import Extension

try:
    from Cython.Build import cythonize
except ImportError:
    sys.exit("Cython not found. Cython is needed to build the extension modules.")


#########################################################
# Definitions
#########################################################

# Define our base set of compiler and linker flags.
# Modules involving numerical computations
extra_compile_args_math_optimized    = ['-march=native', '-O3', '-msse', '-msse2', '-mfma', '-mfpmath=sse']
extra_compile_args_math_debug        = ['-march=native', '-O0', '-g']
extra_link_args_math_optimized       = []
extra_link_args_math_debug           = []

# Modules that do not involve numerical computations
extra_compile_args_nonmath_optimized = ['-O2']
extra_compile_args_nonmath_debug     = ['-O0', '-g']
extra_link_args_nonmath_optimized    = []
extra_link_args_nonmath_debug        = []

# Additional flags to compile/link with OpenMP
openmp_compile_args = ['-fopenmp']
openmp_link_args    = ['-fopenmp']


#########################################################
# Helpers
#########################################################

# Make absolute cimports work.
my_include_dirs = [".", np.get_include()]

# Choose the base set of compiler and linker flags.
if build_type == 'optimized':
    my_extra_compile_args_math    = extra_compile_args_math_optimized
    my_extra_compile_args_nonmath = extra_compile_args_nonmath_optimized
    my_extra_link_args_math       = extra_link_args_math_optimized
    my_extra_link_args_nonmath    = extra_link_args_nonmath_optimized
    my_debug = False
    print( "build configuration selected: optimized" )
elif build_type == 'debug':
    my_extra_compile_args_math    = extra_compile_args_math_debug
    my_extra_compile_args_nonmath = extra_compile_args_nonmath_debug
    my_extra_link_args_math       = extra_link_args_math_debug
    my_extra_link_args_nonmath    = extra_link_args_nonmath_debug
    my_debug = True
    print( "build configuration selected: debug" )
else:
    raise ValueError("Unknown build configuration '%s'; valid: 'optimized', 'debug'" % (build_type))


def declare_cython_extension(extName, use_math=False, use_openmp=False, include_dirs=None):
    """
    Declare a Cython extension module for setuptools.

    Arguments:
        extName : str
            Absolute module name, e.g. use `mylibrary.mypackage.mymodule`
            for the Cython source file `mylibrary/mypackage/mymodule.pyx`.
        use_math : bool
            If True, set math flags and link with ``libm``.
        use_openmp : bool
            If True, compile and link with OpenMP.

    Returns:
        Extension object
            that can be passed to ``setuptools.setup``.
    """
    extPath = extName.replace(".", os.path.sep)+".pyx"

    if use_math:
        compile_args = list(my_extra_compile_args_math) # copy
        link_args    = list(my_extra_link_args_math)
        libraries    = ["m"]  # link libm; this is a list of library names without the "lib" prefix
    else:
        compile_args = list(my_extra_compile_args_nonmath)
        link_args    = list(my_extra_link_args_nonmath)
        libraries    = None  # value if no libraries, see setuptools.extension._Extension

    # OpenMP
    if use_openmp:
        compile_args.insert( 0, openmp_compile_args )
        link_args.insert( 0, openmp_link_args )

    return Extension( extName,
                      [extPath],
                      extra_compile_args=compile_args,
                      extra_link_args=link_args,
                      include_dirs=include_dirs,
                      libraries=libraries
                    )


# Gather user-defined data files
datafiles = []
getext = lambda filename: os.path.splitext(filename)[1]
for datadir in datadirs:
    datafiles.extend( [(root, [os.path.join(root, f) for f in files if getext(f) in dataexts])
                       for root, dirs, files in os.walk(datadir)] )

# Add standard documentation (README et al.), if any, to data files
detected_docs = []
for docname in standard_docs:
    for ext in standard_doc_exts:
        filename = "".join( (docname, ext) )  # relative to the directory in which setup.py resides
        if os.path.isfile(filename):
            detected_docs.append(filename)
datafiles.append( ('.', detected_docs) )


# Extract __version__ from the package __init__.py
import ast
init_py_path = os.path.join(libname, '__init__.py')
version = '0.0.0'
try:
    with open(init_py_path) as f:
        for line in f:
            if line.startswith('__version__'):
                version = ast.parse(line).body[0].value.s
                break
        else:
            print( "WARNING: Version information not found in '%s', using placeholder '%s'" % (init_py_path, version), file=sys.stderr )
except MyFileNotFoundError:
    print( "WARNING: Could not find file '%s', using placeholder version information '%s'" % (init_py_path, version), file=sys.stderr )


#########################################################
# Set up modules
#########################################################

# declare Cython extension modules here
ext_module_interval = declare_cython_extension( "ailist.Interval_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )
ext_module_labeled_interval = declare_cython_extension( "ailist.LabeledInterval_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )
ext_module_ailist = declare_cython_extension( "ailist.AIList_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )
ext_module_aiarray = declare_cython_extension( "ailist.IntervalArray_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )
ext_module_aiarray_labeled = declare_cython_extension( "ailist.LabeledIntervalArray_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )
ext_module_array_query = declare_cython_extension( "ailist.array_query_core", use_math=False, use_openmp=False , include_dirs=my_include_dirs )

# this is mainly to allow a manual logical ordering of the declared modules
cython_ext_modules = [ext_module_interval, ext_module_ailist, ext_module_aiarray, ext_module_aiarray_labeled,
                      ext_module_labeled_interval, ext_module_array_query]

# Call cythonize() explicitly, as recommended in the Cython documentation. See
# This will favor Cython's own handling of '.pyx' sources over that provided by setuptools.
# cythonize() just performs the Cython-level processing, and returns a list of Extension objects.
my_ext_modules = cythonize(cython_ext_modules, include_path=my_include_dirs, gdb_debug=my_debug, language_level=3)

#########################################################
# Call setup()
#########################################################

setup(
    name = "ailist",
    version = version,
    author = "Kyle S. Smith",
    author_email = "kyle.smith@stjude.org",
    url = "https://github.com/kylessmith/ailist",
    project_urls = {"Documentation": "https://www.biosciencestack.com/static/ailist/docs/index.html"},
    description = SHORTDESC,
    long_description = long_description,
    long_description_content_type = "text/markdown",
    # CHANGE THIS
    license = "GPL2",
    # free-form text field
    platforms = ["Linux"],
    classifiers = [ "Development Status :: 4 - Beta",
                    "Environment :: Console",
                    "Intended Audience :: Developers",
                    "Intended Audience :: Science/Research",
                    "Operating System :: POSIX :: Linux",
                    "Programming Language :: Cython",
                    "Programming Language :: Python",
                    "Programming Language :: Python :: 3",
                    "Programming Language :: Python :: 3.6",
                    "Topic :: Scientific/Engineering",
                    "Topic :: Scientific/Engineering :: Mathematics",
                    "Topic :: Software Development :: Libraries",
                    "Topic :: Software Development :: Libraries :: Python Modules",
                    "Topic :: Scientific/Engineering :: Bio-Informatics"
                  ],
    setup_requires = ["cython", "numpy"],
    install_requires = ["numpy", "pandas"],
    provides = ["ailist"],
    keywords = ["cython interval ailist c"],
    ext_modules = my_ext_modules,
    packages = ["ailist"],
    package_data={'ailist': ['*.pxd', '*.pyx', '*.c', '*.h']},
    # Disable zip_safe
    zip_safe = False,
    # Custom data files not inside a Python package
    data_files = datafiles
)