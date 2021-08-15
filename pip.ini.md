
# pip #

pip ist der package installer (for) python.  
* [Dokumentation](https://pip.pypa.io/en/stable/)

## Konfiguration ##
 pip kann eine Konfigurationsdatei
<code>pip.ini</code> verwenden, wenn sie an einem der
[vorgegebenen Orte](https://pip.pypa.io/en/stable/cli/pip_config/) existiert:  
* --global  
  Use the system-wide configuration file only
* --user  
  Use the user configuration file only
* --site  
  Use the current environment configuration file only

Wenn ein python virtual environment verwendet wird, entspricht der Wert von
<code>--site</code> automatisch dem root des virtuellen python environments.  

Die pip.ini befindet sich deshalb in allen Projekten im Verzeichnis für das
virtuelle python environment. Das Verzeichnis wird nicht nach gitlab/github
hochgeladen, weshalb die userid/usertoken Einträge in der Datei unproblematisch
sind.

```pip.ini
[install]
extra-index-url =
    http://<user>:<token>@gitlab.dmz.slashlib.org/api/v4/projects/<projectid>/packages/pypi/simple

trusted-host =
    gitlab.dmz.slashlib.org
```

## Projektids ##
<table style="border: 0">
  <tr><th style="text-align: center">ID</th>
      <th>root</th>
      <th>name</th>
  </tr>
  <tr><td style="text-align: right">89</td>
      <td>org.slashlib.py.eos</td>
      <td></td>
  </tr>
  <tr><td style="text-align: right">91</td>
      <td>org.slashlib.py.eos</td>
      <td>core.exception</td>
  </tr>
  <tr><td style="text-align: right">93</td>
      <td>org.slashlib.py.eos</td>
      <td></td>
  </tr>
  <tr><td style="text-align: right">99</td>
      <td>org.slashlib.py.eos</td>
      <td>core.inspect</td>
  </tr>
  <tr><td style="text-align: right">101</td>
      <td>org.slashlib.py.eos</td>
      <td>core.typing</td>
  </tr>
</table>
