/*
  In VSCode open a terminal window:
    Keyboard shortcut: Press Ctrl + ` (backtick)
    or
    Menu option: Click Terminal → New Terminal
    or
    Command palette: Press Ctrl+Shift+P, type "Terminal: Create New Terminal", and press Enter

  First encrypt the source with:
    xcode.exe -d ./encrypted loadschema.p
    xcode.exe -d ./encrypted createdomain.p

  Then compile with:
    _progres -b -p xcode.p
*/

var character pcLoaderFile = "loadschema.p".
var character pcDomainFile = "createdomain.p".
var character cOutputDir = "./encrypted".
var character[2] cEncryptedSource.

assign
    cEncryptedSource[1] = cOutputDir + "/" + pcLoaderFile
    cEncryptedSource[2] = cOutputDir + "/" + pcDomainFile
    .

os-create-dir value(cOutputDir).

os-command silent value(
  substitute('xcode.exe -d &1 &2', quoter(cOutputDir), quoter(pcLoaderFile))
).
os-command silent value(
  substitute('xcode.exe -d &1 &2', quoter(cOutputDir), quoter(pcDomainFile))
).

compile value(cEncryptedSource[1]) save into value(cOutputDir) no-error.
compile value(cEncryptedSource[2]) save into value(cOutputDir) no-error.
