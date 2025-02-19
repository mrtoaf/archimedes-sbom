# Archimedes SBOM

This repository provides a tutorial for generating a Software Bill of Materials (SBOM) for the Loop Firmware using Anchore Syft and viewing it with the SBOM File Viewer.

## Prerequisites

- Git (https://git-scm.com/)
- Anchore Syft (https://github.com/anchore/syft)
- A web browser

## Steps

### 1. Clone the Repository

Clone the repository to your local machine:

    git clone https://github.com/mrtoaf/archimedes-sbom.git

### 2. Change Directory to the Loop Firmware Folder

Navigate into the Loop Firmware folder:

    cd archimedes-sbom/Loop Firmware

> **Note:** Adjust the folder path if your directory structure is different.

### 3. Download and Install Anchore Syft

There are multiple ways to install Anchore Syft. You can follow the instructions on the [Anchore Syft GitHub page](https://github.com/anchore/syft).

#### Recommended Installation

Run the following command to install Syft and place the binary in `/usr/local/bin`:

    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

**Install script options:**

- **-b**: Specify a custom installation directory (defaults to `./bin`)
- **-d**: More verbose logging levels (`-d` for debug, `-dd` for trace)
- **-v**: Verify the signature of the downloaded artifact before installation (requires cosign to be installed)

### 4. Generate the SBOM

Run the following command to generate an SBOM in CycloneDX JSON format from the Loop Firmware folder:

    syft . -o cyclonedx-json > sbom.json

This command scans the current directory and saves the SBOM as `sbom.json`.

### 5. View the SBOM

Open your web browser and navigate to the SBOM File Viewer (https://mrtoaf.github.io/archimedes-sbom/).

Click on the **"Choose CycloneDX SBOM"** button to upload your `sbom.json` file and view the parsed SBOM details.

## Summary

1. **Clone** the repository.
2. **CD** into the Loop Firmware folder.
3. **Download & Install** Anchore Syft.
4. **Generate** the SBOM with the provided Syft command.
5. **View** the SBOM using the online SBOM File Viewer.

Happy SBOM-ing!
