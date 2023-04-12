# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
from pathlib import Path
from datetime import datetime
import ailist
#sys.path.append(os.path.abspath('../ailist'))
#sys.path.insert(0, os.path.abspath('.'))
#sys.path.insert(0, os.path.abspath('../'))


# -- Project information -----------------------------------------------------
project = 'ailist'
author = "Kyles Smith"
copyright = f'{datetime.now():%Y}, {author}.'
version = "2.0.0"
release = version


# -- General configuration ---------------------------------------------------

nitpicky = True  # Warn about broken links.
#needs_sphinx = '2.0'

# default settings
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
default_role = 'literal'
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
#pygments_style = 'sphinx'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = ['sphinx.ext.autodoc',
              'sphinx.ext.viewcode',
              'sphinx.ext.autosummary',
              'sphinx.ext.intersphinx',
              'sphinx.ext.napoleon',
              'sphinx_autodoc_typehints',
              'scanpydoc'
          ]

# Generate the API documentation when building
autosummary_generate = True
autodoc_member_order = 'bysource'
# autodoc_default_flags = ['members']
napoleon_google_docstring = False
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = False
napoleon_use_rtype = True  # having a separate entry generally helps readability
napoleon_use_param = True
napoleon_custom_sections = [('Params', 'Parameters')]
todo_include_todos = False

# numpydoc
#numpydoc_attributes_as_param_list = False
#numpydoc_class_members_toctree = False


intersphinx_mapping = dict(
    numpy=('https://docs.scipy.org/doc/numpy/', None),
    pandas=('https://pandas.pydata.org/pandas-docs/stable/', None),
    python=('https://docs.python.org/3', None),
    h5py=('http://docs.h5py.org/en/stable/', None),
    scipy=('https://docs.scipy.org/doc/scipy/reference/', None),
    matplotlib=('https://matplotlib.org/', None),
)


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
#html_theme = 'sphinx_rtd_theme'
html_theme = "pydata_sphinx_theme"
#html_theme = 'alabaster'
#html_theme = 'scikit-learn-modern'

html_logo = "_static/logo.svg"

html_theme_options = dict(github_url="https://github.com/kylessmith/ailist",
                          navigation_depth=4,
                          google_analytics_id="UA-170691991-1",
                          source_link_position= "footer",
                          bootswatch_theme= "cerulean",
                          navbar_title= "ailist",
                          navbar_sidebarrel= False,
                          bootstrap_version= "3",
                          nosidebar= True,
                          body_max_width= '100%',
                          external_links=[{"name":"Other tools",
                                           "url":"https://www.biosciencestack.com/documentation/"}],
                          show_prev_next=False,
                          use_edit_page_button=True,
                          search_bar_position="navbar",
                          navbar_links= [
                            ("API", "api/index"),
                            ("Benchmark", "benchmarking"),
                            ("Tutorial", "tutorial"),
                            ("BioscienceStack", "http://biosciencestack.com", True)
                          ],
                          logo = {"image_light": "_static/logo.svg",
                                  "image_dark": "_static/logo.svg"},
                        )

html_sidebars = {"**": []}

html_context = dict(
    display_github=True,  # Integrate GitHub
    github_user='kylessmith',  # Username
    github_repo='ailist',  # Repo name
    github_version='master',  # Version
    conf_py_path='/doc/',  # Path in the checkout to the docs root
    github_url="https://github.com",
)

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

def setup(app):
    # Don’t allow broken links
    # app.warningiserror = True
    app.add_css_file('css/custom.css')