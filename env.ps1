# source python powershell functions
. ..\..\powershell\pyshell\python.ps1

# note: this fails, if project direcotry name does not match the package name!
$env:package = split-path -leaf $PSScriptRoot

function build {
  Run-Build -DirectoryPatterns @( "dist", "src/*.egg-info" )
}

function test {
  Run-Test -RootDirectory "./src" -TestDirectory "test/unittests"
}

function upload {
  Upload-PyPI -Package $env:package
}

function install {
  pip install -e .
}

Set-PythonEnvironment -Version latest
Report-PythonEnvironment
Switch-PythonEnvironment
