<div align=center>
  
<pre>

 ╔═════════════════════════════════════════════════════════════════════════════╗
 ║  ██████╗  █████╗ ██╗███╗   ██╗███╗   ███╗███████╗████████╗███████╗██████╗   ║
 ║  ██╔══██╗██╔══██╗██║████╗  ██║████╗ ████║██╔════╝╚══██╔══╝██╔════╝██╔══██╗  ║
 ║  ██████╔╝███████║██║██╔██╗ ██║██╔████╔██║█████╗     ██║   █████╗  ██████╔╝  ║
 ║  ██╔══██╗██╔══██║██║██║╚██╗██║██║╚██╔╝██║██╔══╝     ██║   ██╔══╝  ██╔══██╗  ║
 ║  ██║  ██║██║  ██║██║██║ ╚████║██║ ╚═╝ ██║███████╗   ██║   ███████╗██║  ██║  ║
 ║  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝  ║
 ╚═════════════════════════════════════════════════════════════════════════════╝
</pre>

</div>

---

>## *Rainmeter* is a desktop customization tool for Windows. For more information and downloads, visit [rainmeter.net](http://rainmeter.net/).

- For build instructions, see [this](https://github.com/rainmeter/rainmeter/blob/master/Docs/Building.md).

> ### Linux status

- Rainmeter's full desktop runtime is still Windows-oriented, but this repository now includes a Linux CMake build for a portable subset of core utility code in `Common/`.
The Linux changes are additive and guarded; Windows build paths and Windows-specific runtime code remain unchanged.

- This Linux path currently builds and tests:
- `StringUtil`
- `PathUtil`
- `MathParser`

- Linux quick start:
```
	chmod +x ./start.sh
	./start.sh
```
- After setup, users can launch from the app list as `Rainmeter Linux` or run:
```
	rainmeter-linux console
```
- Downloaded skins can be imported securely with:
```
	rainmeter-linux install-skin /path/to/skin.zip
```
- To remove the Linux install:
```
	chmod +x ./uninstall.sh
	./uninstall.sh
```
### See `Docs/Building.md` for Linux build commands.

### Code signing policy

- Our official releases are signed with a valid code signing certificate under the name of [SignPath Foundation].

- We appreciate the free code signing provided by [SignPath.io] and the free certificate provided by [SignPath Foundation] 🙏

### Privacy policy

- This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it.

[SignPath Foundation]:https://signpath.org
[SignPath.io]:https://signpath.io
