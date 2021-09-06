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
  param (
    [switch]$NoUpgradeHint
  )

  $VirtualPy = "$env:PyVersion\Scripts\activate"
  if (Test-Path $VirtualPy -PathType leaf) {
      & $VirtualPy

      if ( $NoUpgradeHint -eq $false ) {
           Write-Host -ForeGround Yellow "Consider running 'Upgrade-PythonPackages' to update outdated packages"
      }
  }
  else {
      Write-Host -ForeGround Yellow "No virtual python environment. Maybe run 'Install-PythonEnvironment'?"
  }
}

# always install and upgrade the following python packages
$piprequired = @( 'build', 'twine', 'wheel', 'mypy', 'Sphinx',
                  'sphinxcontrib-napoleon', 'sphinx-markdown-builder' )

function Install-PythonPackages {
  # the following packages are expected not to be installed yet
  $packages = $piprequired

  # pip is already there - upgrade it
  Write-Host -ForeGround Green "Upgrading python package 'pip' (Step 1 of $( $packages.count + 2 )) ..."
  python -m pip install --upgrade pip | Out-Default

  # setuptools are already there - upgrade them
  Write-Host -ForeGround Green "Upgrading python package 'setuptools' (Step 2 of $( $packages.count + 2 )) ..."
  pip install --upgrade setuptools | Out-Default

  # now install what's missing ...
  $packages | % { $index = 0 } {
    $index++
    Write-Host -ForeGround Green "Installing python package '$PSItem' (Step $( $index + 2 ) of $( $packages.count + 2 )) ..."
    pip install $PSItem | Out-Default
  }
}

function Upgrade-PythonPackages {
  $packages = , 'setuptools' + $piprequired

  Write-Host -ForeGround Green "Upgrading python package 'pip' (Step 1 of $( $packages.count + 1 )) ..."
  python -m pip install --upgrade pip | Out-Default

  # now upgrade packages from list ...
  $packages | % { $index = 0 } {
    $index++
    Write-Host -ForeGround Green "Installing python package '$PSItem' (Step $( $index + 1 ) of $( $packages.count + 1 )) ..."
    pip install --upgrade $PSItem | Out-Default
  }
}

function Install-PythonEnvironment {
  Write-Host -ForeGround Green "Installing python virtual environment. This will take a minute ..."
  python -m venv "$env:PyVersion"
  Switch-PythonEnvironment -NoUpgradeHint
  Write-Host -ForeGround Yellow "Consider running 'Install-PythonPackages' to install missing python packages"
}
