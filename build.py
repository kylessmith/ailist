import os
import shutil
#from distutils.command.build_ext import build_ext
#from distutils.core import Distribution, Extension

#from setuptools.command.build_ext import build_ext
from setuptools.extension import Extension
from setuptools.dist import Distribution
import numpy as np

from Cython.Build import build_ext, cythonize


include_dirs = [".", np.get_include()]


def declare_cython_extension(extName, use_openmp=False, include_dirs=None):
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

    compile_args = ["-march=native", "-O3", "-msse", "-msse2", "-mfma", "-mfpmath=sse"]
    compile_args = ["-O3"]
    link_args    = []
    libraries    = None  # value if no libraries, see setuptools.extension._Extension

    # OpenMP
    if use_openmp:
        compile_args.insert( 0, ['-fopenmp'] )
        link_args.insert( 0, ['-fopenmp'] )

    return Extension( extName,
                      [extPath],
                      extra_compile_args=compile_args,
                      extra_link_args=link_args,
                      include_dirs=include_dirs,
                      libraries=libraries
                    )


def build():
    # declare Cython extension modules here
    ext_module_interval = declare_cython_extension( "ailist.Interval_core", use_openmp=False , include_dirs=include_dirs )
    ext_module_ailist = declare_cython_extension( "ailist.AIList_core", use_openmp=False , include_dirs=include_dirs )
    ext_module_aiarray_labeled = declare_cython_extension( "ailist.LabeledIntervalArray_core", use_openmp=False , include_dirs=include_dirs )
    ext_module_array_query = declare_cython_extension( "ailist.array_query_core", use_openmp=False , include_dirs=include_dirs )

    # this is mainly to allow a manual logical ordering of the declared modules
    cython_ext_modules = [ext_module_interval, ext_module_ailist, ext_module_aiarray_labeled, ext_module_array_query]

    # Call cythonize() explicitly, as recommended in the Cython documentation. See
    # This will favor Cython's own handling of '.pyx' sources over that provided by setuptools.
    # cythonize() just performs the Cython-level processing, and returns a list of Extension objects.
    ext_modules = cythonize(cython_ext_modules, include_path=include_dirs, gdb_debug=False, language_level=3)

    distribution = Distribution({"name": "extended", "ext_modules": ext_modules})
    distribution.package_dir = "extended"

    cmd = build_ext(distribution)
    cmd.ensure_finalized()
    cmd.run()

    # Copy built extensions back to the project
    #files = os.listdir(cmd.build_lib)
    #print(files)
    for output in cmd.get_outputs():
        relative_extension = os.path.relpath(output, cmd.build_lib)
        shutil.copyfile(output, relative_extension)
    #    mode = os.stat(relative_extension).st_mode
    #    mode |= (mode & 0o444) >> 2
    #    os.chmod(relative_extension, mode)


if __name__ == "__main__":
    build()