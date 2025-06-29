# ElectrumSV AppImage Builder

This repository contains a script to build a Linux AppImage for the ElectrumSV wallet, specifically for the v1.3.16 release.

## How to Use

1.  Download the official source code for a specific release (e.g., `electrumsv-sv-1.3.16.tar.gz`) from the ElectrumSV website or GitHub releases page.
2.  Extract the source code archive.
3.  Place the `build-appimage.sh` script from this repository into the root of the extracted source code directory (e.g., inside `electrumsv-sv-1.3.16/`).
4.  You might need to install some stuff depending on your Linux distro.
5.  Run the script from the root directory:
    ```bash
    ./contrib/build-appimage.sh
    ```
6.  The final AppImage will be located in the `build/appimage/` directory.

**Note:** This script is designed to be run from the root of the official source code release directory. It may not work correctly if run from a clone of the git repository due to differences in file structure.
