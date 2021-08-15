#REQUIRES -Version 2.0

function Remove-Directories {
  <#
  .SYNOPSIS
    Clean the project directory - remove temporary directories.
  .DESCRIPTION
    Iterates over the list of directory patterns, for removing each of them
    recursively from the project.
  .NOTES
    File Name    : python.ps1
    Author       : db developer, db.developer@gmx.de
    Prerequisite : PowerShell V2
    Copyright 2021 slashlib.org
  #>

  param (
   [Parameter(Mandatory)]
   [string[]]$DirectoryPatterns
  )
  foreach($directory in $DirectoryPatterns) {
    Remove-Item -Recurse -Force $directory -ErrorAction SilentlyContinue
  }
}

function Run-PythonBuild {
  <#
    .SYNOPSIS
      Run a python build
  #>
  python -m build
}

function Run-Clean {
  <#
    .SYNOPSIS
      Clean the project directory.
  #>

  param (
   [Parameter(Mandatory)]
   [string[]]$DirectoryPatterns
  )
  Remove-Directories $DirectoryPatterns
}

function Run-Build {
  <#
    .SYNOPSIS
      Build the project.
  #>

  param (
   [Parameter(Mandatory)]
   [string[]]$DirectoryPatterns
  )
  Run-Clean $DirectoryPatterns
  Run-PythonBuild
}

function Run-Test {
  <#
    .SYNOPSIS
      Run python tests.
  #>

  param (
    [Parameter(Mandatory)]
    [string]$RootDirectory,
    [Parameter(Mandatory)]
    [string]$TestDirectory
    # [switch]$Verbose = $False
  )

  $TestDirectory = "$RootDirectory/$TestDirectory"
  $TestPattern   = "*.test.py"
  # $BeVerbose     = $( if ($Verbose) { "-v" } Else { "" })

  python -m unittest discover -t $RootDirectory -s $TestDirectory -p $TestPattern
}

function Upload-PyPI {
  <#
  .SYNOPSIS
    Upload python package to git repository
  .DESCRIPTION
    Depending on $Package the git repository is chosen for uploading the python
    package. A twine configfile is used, to make sure, credentials required for
    git stay outside the projects git add/commit/push range.
  .NOTES
    File Name    : env.ps1
    Author       : db developer, db.developer@gmx.de
    Prerequisite : PowerShell V2
    Copyright 2021 slashlib.org
  #>

  param (
    [Parameter(Mandatory)]
    [string]$Package
  )

  # luckily python supports "~" (user home directory) on any os
  $filename = "~\.pypirc\$Package"
  if (Test-Path $filename -PathType leaf) {
      python -m twine upload --config-file $filename --repository gitlab dist/*
  }
  else {
      [Console]::ForegroundColor = "red"
      [Console]::Error.WriteLine( "Package upload canceled: Missing file '$filename'" )
      [Console]::ResetColor()
  }
}

function Install-Dependencies {
  <#
  .SYNOPSIS
    Installs package dependencies of the current project.
  .DESCRIPTION
    While setup.py dependency settings cannot directly be used to install the
    required packages, it is possible to build a package for the project and
    afterwards use the generated *.egg-info files for installing the
    dependencies.
    Be aware of pip install depends on pip.ini, which means installs will fail,
    if the packages can neither be found on pipy nor in any registry found in
    pip.ini
    The file pip.ini should be located within the projects virtual python
    environment (read about pip config --site).
  .NOTES
    File Name    : env.ps1
    Author       : db developer, db.developer@gmx.de
    Prerequisite : PowerShell V2
    Copyright 2021 slashlib.org
  #>

  $filename = ".\src\$env:package.egg-info\requires.txt"
  if (Test-Path $filename -PathType leaf) {
      pip install -r $filename
  }
  else {
      [Console]::ForegroundColor = "red"
      [Console]::Error.WriteLine( "Installing dependencies canceled: Missing file '$filename'" )
      [Console]::ResetColor()
  }
}


function Set-PythonEnvironment {
  <#
  .SYNOPSIS
    Set the python environment to be used.
  .DESCRIPTION
    Depending on $Version a matching python environment is set.
  .NOTES
    File Name    : env.ps1
    Author       : db developer, db.developer@gmx.de
    Prerequisite : PowerShell V2
    Copyright 2021 slashlib.org
  #>

  param (
    # fallback to latest python version
    [ValidateNotNullOrEmpty()]
    [string]$Version = "latest"
  )

  # Suppress __pycache__ files
  $env:PYTHONDONTWRITEBYTECODE = $true

  $PyVersion = "<unknown>"
  if ( $Version -eq "2"  ) {
       $PyVersion = "python27"
  }
  elseif (( $Version -eq "3" ) -or ( $Version -eq "latest" )) {
       $PyVersion = "python39"
  }

  $PyPATH   = "$env:SystemDrive\Development\python\$PyVersion;" +
              "$env:SystemDrive\Development\python\$PyVersion\Scripts"
  $GitPath  = "$env:SystemDrive\Program Files\Git\cmd"
  $WinSys32 = "$env:SystemRoot\System32"

  $env:Path      = "$WinSys32;$PyPath;$GitPath"
  $env:PyVersion = $PyVersion
}

function Report-PythonEnvironment {
  <#
  .SYNOPSIS
    Report the python environment being used.
  .DESCRIPTION
    Lists powershell, python and git version, available for use.
  .NOTES
    File Name    : env.ps1
    Author       : db developer, db.developer@gmx.de
    Prerequisite : PowerShell V2
    Copyright 2021 slashlib.org
  #>

  $PySemVer  = python --version 2>&1
  $PySemVer  = $PySemVer -split " "

  $GitSemVer = git --version 2>&1
  $GitSemVer = $GitSemVer -split " "

  Write-Host "Powershell version:  " $PSVersionTable.PSVersion
  Write-Host "Python version:      " $PySemVer[1]
  Write-Host "Git version:         " $GitSemVer[2]
}

function Switch-PythonEnvironment {
  $VirtualPy = "$env:PyVersion\Scripts\activate"
  if (Test-Path $VirtualPy -PathType leaf) {
      & $VirtualPy
  }
  else {
      [Console]::ForegroundColor = "yellow"
      [Console]::Error.WriteLine( "No virtual python environment. Maybe run 'Install-PythonEnvironment'?" )
      [Console]::ResetColor()
  }
}

# python -m pip install --upgrade pip
# pip install --upgrade setuptools
# pip install build
# pip install twine
# pip install wheel
# pip install mypy
function Upgrade-PythonEnvironment {
  python -m pip install --upgrade pip | Out-Default
  pip install --upgrade setuptools | Out-Default
  pip install build | Out-Default
  pip install twine | Out-Default
  pip install wheel | Out-Default
  pip install mypy | Out-Default
}

function Install-PythonEnvironment {
  python -m venv "$env:PyVersion"
  Switch-PythonEnvironment
  [Console]::ForegroundColor = "yellow"
  [Console]::Error.WriteLine( "Consider running 'Upgrade-PythonEnvironment' to update outdated packages (build, twine, pip, setuptools)" )
  [Console]::ResetColor()
}
