## Building Rainmeter

### Get the source code

Use <a href="http://git-scm.com">Git</a> to clone the repository:

    git clone https://github.com/rainmeter/rainmeter.git

Alternatively, download the repository contents as a [ZIP archive](https://github.com/rainmeter/rainmeter/archive/master.zip).


### Building with Visual Studio

Rainmeter can be built using any version of Visual Studio 2022. If you don't already have VS2022, you can download [Visual Studio Community 2022](https://www.visualstudio.com/downloads/) for free.


### Building portable core on Linux

The full Rainmeter app is Windows-specific today, but a Linux-compatible portable core build is available for selected shared modules under `Common/`.
This Linux path does not remove or replace existing Visual Studio / Windows build support.

Quick bootstrap (build + install + desktop app entry):

    chmod +x ./start.sh
    ./start.sh

Uninstall:

    chmod +x ./uninstall.sh
    ./uninstall.sh

Optional uninstall flags:

    ./uninstall.sh --dry-run
    ./uninstall.sh --remove-build

What `./start.sh` does:

- Builds Linux-compatible targets with CMake.
- Installs a user-local launcher into `~/.local/share/rainmeter-linux`.
- Creates a desktop app entry (`Rainmeter Linux`) in `~/.local/share/applications`.
- Installs a command wrapper at `~/.local/bin/rainmeter-linux`.
- Copies bundled skins and enables secure import of downloaded skin archives.

Skin management:

    rainmeter-linux list-skins
    rainmeter-linux install-skin /path/to/skin.zip

Desktop launch behavior:

- The app menu icon opens a terminal and runs `rainmeter-linux.sh console`.
- Users can configure and use Rainmeter from that terminal menu.
- Runtime launch output can be viewed from menu option `Show recent launch log`.

Security notes for skin imports:

- Archive extraction blocks absolute paths.
- Archive extraction blocks path traversal patterns like `../`.
- Skins are installed into the user-local skin folder only.

Requirements:

- CMake 3.16+
- GCC or Clang with C++17 support

Build commands:

    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j

Run smoke test:

    ./build/Common/rainmeter_common_smoke

Current Linux portable targets:

- `StringUtil`
- `PathUtil`
- `MathParser`

This is the first step in a larger Linux port and does not yet include the Windows UI / plugin runtime layers.


### Building the installer manually

First, download and install [NSIS 3](http://nsis.sourceforge.net) or later.

Then, in the Build directory, run e.g. `Build.bat pre 1.2.3.4` to build the pre-release 1.2.3 r4.

If you see any "not found" errors, check that the paths in the `set` commands at the top of the file match your environment.

To build a release installer, use `Build.bat release 1.2.3.4`.
