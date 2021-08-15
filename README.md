# Powershell for python projects #

A collection of functions to setup a python development environment and run
a few basic commands.

## prerequisites ##

Requires powershell v5.x to be installed.  
Requires python to be installed.

## getting started ##

This guide assumes, that you are familiar with the use of python venv, pip,
twine, wheel and mypy  

1. Follow the recommendated folderstructure below:  
```ps
# folder structure
<some folder>
  +-- <folder for python projects>
  |     +-- <python project (see: project folder names!)>
  |     +-- ...
  |
  +-- powershell
        +-- pyshell (clone of this git repository)
```

2. Clone powershell.py into <code>&lt;some folder&gt;\\powershell\\pyshell</code><br />
3. Copy <code>env.ps1</code> from folder <code>pyshell</code> into the root folder of your python project.
4. If you did not follow the recommended folder structure, you should adjust <code>line 1: . ..\\..\\powershell\\pyshell\\python.ps1</code> of the copied <code>env.ps1</code> file.
5. Link powershell into your project and adjust the the parameters such that <code>env.ps1</code> is called.
6. Setup a [pip.ini](pip.ini.md) file to enable installing packges from other sources than pip or piptest  
7. Setup a [.pypirc](pypirc.md) direcorty to enable uploading packages to other package repositories than pip or piptest  

## commands ##
* <b style="color: orange">Install-PythonEnvironment</b>  
  Run this (first) to install the python virtual environment.
* <b style="color: orange">Upgrade-PythonEnvironment</b>  
  Run this (second) if you want to:
  * get the <code>pip</code> package updated
  * get the <code>setuptools</code> package updated
  * get the package <code>build</code> installed
  * get the package <code>twine</code> installed
  * get the package <code>wheel</code> installed
  * get the package <code>mypy</code> installed
* <b style="color: orange">install</b>  
  Run this to install the project with its packages to enable self referencing (required for running tests)
* <b style="color: orange">build</b>  
  Runs python build to create a package from the current project
* <b style="color: orange">test</b>  
  Runs python unittest(s)
* <b style="color: orange">upload</b>  
  Uploads packages found in <code>&lt;project&gt;/dist</code> to a package repository.
