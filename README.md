# Halo-Source-Animation-Bone-Renamer

A dynamic tool for renaming nodes/bones prefix in animation source files from Halo games (H2, H3, H4, HR) to HCE format.

## Overview

This repository contains a Lua script that dynamically adds prefixes to bone names in animation files. Unlike hardcoded solutions, this tool accepts the prefix as a command-line argument, making it flexible and reusable for different bone naming conventions.

## Features

- **Dynamic Prefix Addition** - Takes prefix as a command-line argument (no hardcoded names)
- **Multiple Format Support** - Processes JMA, JMM, JMO, JMR, JMT, JMW, and JMZ files
- **Batch Processing** - Automatically processes all animation files in the `animations` folder
- **Output to Separate Folder** - Creates renamed files in a `converted` folder
- **Proper Formatting** - Adds a space after the prefix (e.g., "pelvis" → "bip01 pelvis")
- **Detailed Reporting** - Shows progress and statistics for all processed files

## Requirements

- [LuaJIT](https://luajit.org/) - Just-In-Time Compiler for Lua
- Lua modules included in `lua_modules/`:
  - `luna.lua` - Utility functions for string and file operations
  - `path.lua` - Path manipulation utilities

## Installation

1. Clone this repository
2. Ensure LuaJIT is installed and accessible from your PATH
3. The required Lua modules are already included in the `lua_modules` folder

## Usage

### Basic Usage

```bash
luajit bone_renamer.lua <prefix>
```

### Example

```bash
luajit bone_renamer.lua bip01
```

This will:
1. Read all animation files from the `animations` folder
2. Add "bip01 " prefix to all bone names (e.g., "pelvis" → "bip01 pelvis")
3. Save the renamed files to the `converted` folder

### Folder Structure

```
Halo-Source-Animation-Bone-Renamer/
├── animations/           # Place your source animation files here
├── converted/            # Renamed files will be saved here (auto-created)
├── bone_renamer.lua  # Main script
├── lua_modules/          # Required Lua modules
│   ├── luna.lua
│   └── path.lua
└── docs/                 # Documentation and examples
    ├── jma_example.JMA
    └── jma_structure.json
```

## Supported File Formats

- `.JMA` - Halo Animation (Base with XY movement)
- `.JMM` - Halo Animation (Base without movement data info)
- `.JMO` - Halo Animation (Overlay)
- `.JMR` - Halo Animation (Replacement)
- `.JMT` - Halo Animation (Turn position)
- `.JMW` - Halo Animation (World Relative)
- `.JMZ` - Halo Animation (Base with XYZ movement)

## How It Works

The script intelligently parses the animation file structure:

1. Reads the animation file header to get the node count.
2. Identifies node name lines.
3. Adds the specified prefix with a space to each bone/node name
4. Preserves all other data including:
   - Animation metadata (version, frame count, frame rate)
   - Node hierarchy (child and sibling indices)
   - Keyframe data (translations, rotations, scales)

## Output

The script provides detailed output including:
- Number of files found and processed
- Number of bones renamed per file
- Summary statistics
- Any errors encountered

### Example Output

```
========================================
Dynamic Bone Renamer for Animation Files
========================================

Prefix: 'bip01'

Creating directory: converted
  -> Successfully created: converted

Found 3 animation file(s)

Processing: animation_idle.JMO
  -> Renamed 48 bones
  -> Saved to: converted\animation_idle.JMO

Processing: animation_walk.JMA
  -> Renamed 48 bones
  -> Saved to: converted\animation_walk.JMA

Processing: animation_run.JMO
  -> Renamed 48 bones
  -> Saved to: converted\animation_run.JMO

========================================
Summary
========================================
Files processed: 3 / 3
Total bones renamed: 144

Done!
```

## Documentation

- `docs/jma_structure.json` - JSON representation of the animation file structure
- `docs/jma_example.JMA` - Example animation file for reference

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests.
