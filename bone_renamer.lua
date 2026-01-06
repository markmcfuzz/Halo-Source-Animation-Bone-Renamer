-- Dynamic Bone Renamer for Animation Files
-- This script processes all animation files (JMA, JMM, JMO, JMR, JMT, JMW, JMZ)
-- in the 'animations' folder and adds a prefix to bone names,
-- saving the results in the 'converted' folder.
--
-- Usage: luajit dynamic_bone_renamer.lua <prefix>
-- Example: luajit dynamic_bone_renamer.lua "bip01"
-- Add lua_modules to package path
package.path = package.path .. ";lua_modules/?.lua;lua_modules/?/?.lua"

-- Load modules
local luna = require("luna")
local path = require("path")

-- Configuration
local ANIMATIONS_FOLDER = "animations"
local OUTPUT_FOLDER = "converted"
local SUPPORTED_EXTENSIONS = {".JMA", ".JMM", ".JMO", ".JMR", ".JMT", ".JMW", ".JMZ"}

-- Function to print usage information
local function print_usage()
    print("Dynamic Bone Renamer for Animation Files")
    print("Usage: luajit dynamic_bone_renamer.lua <prefix>")
    print("")
    print("Arguments:")
    print("  <prefix>  The prefix to add to all bone names (e.g., 'bip01')")
    print("")
    print("Example:")
    print("  luajit dynamic_bone_renamer.lua bip01")
    print("")
    print("This will rename 'pelvis' to 'bip01 pelvis'")
end

-- Function to check if a file extension is supported
local function is_supported_extension(ext)
    local upper_ext = ext:upper()
    for _, supported in ipairs(SUPPORTED_EXTENSIONS) do
        if upper_ext == supported then
            return true
        end
    end
    return false
end

-- Function to check if directory exists
local function directory_exists(dirname)
    local testpath = dirname .. "/test.tmp"
    local file = io.open(testpath, "w")
    if file then
        file:close()
        os.remove(testpath)
        return true
    end
    return false
end

-- Function to create directory
local function create_directory(dirname)
    if not directory_exists(dirname) then
        print("Creating directory: " .. dirname)
        local result = os.execute("mkdir \"" .. dirname .. "\" 2>NUL")

        -- Validate creation
        local testpath = dirname .. "/test.tmp"
        local file = io.open(testpath, "w")
        if file then
            file:close()
            os.remove(testpath)
            print("  -> Successfully created: " .. dirname)
            return true
        else
            print("  -> Error: Could not create directory: " .. dirname)
            return false
        end
    else
        print("Directory already exists: " .. dirname)
    end
    return true
end

-- Function to get all animation files in a directory
local function get_animation_files(directory)
    local files = {}

    -- Check if directory exists
    if not directory_exists(directory) then
        return files
    end

    -- Get all supported file types
    for _, ext in ipairs(SUPPORTED_EXTENSIONS) do
        local command = "dir \"" .. directory .. "\\*" .. ext .. "\" /b 2>nul"
        local pipe = io.popen(command)
        if pipe then
            for filename in pipe:lines() do
                if filename and filename ~= "" then
                    local filepath = directory .. "\\" .. filename
                    -- Verify file exists
                    if luna.file.exists(filepath) then
                        table.insert(files, filepath)
                    end
                end
            end
            pipe:close()
        end
    end

    -- Sort files for consistent processing order
    table.sort(files)
    return files
end

-- Function to parse animation file structure
-- Based on the JMA structure:
-- Line 1: jma_version
-- Line 2: frame_count
-- Line 3: frame_rate
-- Line 4: actor_names_index
-- Line 5: actor_names
-- Line 6: node_count
-- Line 7: node_checksum
-- Lines 8+: nodes (node_name, first_child_node_index, next_sibling_node_index)
-- After nodes: keyframes data
local function parse_animation_file(content, prefix)
    local lines = {}
    local renamed_count = 0
    local in_nodes_section = false
    local line_number = 0
    local node_count = nil
    -- Nodes start at line 8 (after header)
    local nodes_start_line = 8
    local nodes_processed = 0

    -- Split content into lines
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Get node count from line 6
    if #lines >= 6 then
        node_count = tonumber(lines[6])
    end

    if not node_count or node_count <= 0 then
        print("  Warning: Could not read node count or invalid count")
        return content, 0
    end

    -- Process lines
    for i = 1, #lines do
        -- Check if we're in the nodes section
        -- Nodes section: every 3 lines starting from line 8
        -- Line 1: node_name
        -- Line 2: first_child_node_index
        -- Line 3: next_sibling_node_index
        if i >= nodes_start_line then
            local relative_line = i - nodes_start_line + 1

            -- Check if this is a node name line (every 3 lines, starting with line 1, 4, 7, etc.)
            if (relative_line - 1) % 3 == 0 then
                local node_index = math.floor((relative_line - 1) / 3) + 1

                if node_index <= node_count then
                    -- This is a node name line - add prefix
                    local trimmed_line = lines[i]:trim()
                    if trimmed_line and trimmed_line ~= "" then
                        lines[i] = prefix .. " " .. trimmed_line
                        renamed_count = renamed_count + 1
                    end
                    nodes_processed = nodes_processed + 1
                end
            end
        end
    end

    return table.concat(lines, "\n"), renamed_count
end

-- Function to process a single file
local function process_file(input_path, output_path, prefix)
    local filename = path.file(input_path)
    print("Processing: " .. filename)

    -- Read the original file
    local content = luna.file.read(input_path)
    if not content then
        print("  Error: Could not read file")
        return false, 0
    end

    -- Parse and rename bones
    local new_content, renamed_count = parse_animation_file(content, prefix)

    -- Write the modified content
    local success = luna.file.write(output_path, new_content)
    if not success then
        print("  Error: Could not write output file")
        return false, 0
    end

    print("  -> Renamed " .. renamed_count .. " bones")
    print("  -> Saved to: " .. output_path)
    return true, renamed_count
end

-- Main function
local function main()
    print("========================================")
    print("Dynamic Bone Renamer for Animation Files")
    print("========================================")
    print("")

    -- Check command line arguments
    if #arg < 1 then
        print("Error: Missing required argument <prefix>")
        print("")
        print_usage()
        os.exit(1)
    end

    local prefix = arg[1]
    print("Prefix: '" .. prefix .. "'")
    print("")

    -- Check if animations folder exists
    if not directory_exists(ANIMATIONS_FOLDER) then
        print("Error: 'animations' folder not found")
        print("Please create an 'animations' folder and place your animation files there.")
        os.exit(1)
    end

    -- Create output folder
    if not create_directory(OUTPUT_FOLDER) then
        print("Error: Could not create 'converted' folder")
        os.exit(1)
    end
    print("")

    -- Get all animation files
    local files = get_animation_files(ANIMATIONS_FOLDER)

    if #files == 0 then
        print("No animation files found in '" .. ANIMATIONS_FOLDER .. "' folder")
        print("Supported formats: " .. table.concat(SUPPORTED_EXTENSIONS, ", "))
        os.exit(0)
    end

    print("Found " .. #files .. " animation file(s)")
    print("")

    -- Process each file
    local total_processed = 0
    local total_renamed = 0
    local failed_files = {}

    for _, input_path in ipairs(files) do
        local filename = path.file(input_path)
        local output_path = OUTPUT_FOLDER .. "\\" .. filename

        local success, renamed_count = process_file(input_path, output_path, prefix)
        if success then
            total_processed = total_processed + 1
            total_renamed = total_renamed + renamed_count
        else
            table.insert(failed_files, filename)
        end
        print("")
    end

    -- Print summary
    print("========================================")
    print("Summary")
    print("========================================")
    print("Files processed: " .. total_processed .. " / " .. #files)
    print("Total bones renamed: " .. total_renamed)

    if #failed_files > 0 then
        print("")
        print("Failed files:")
        for _, filename in ipairs(failed_files) do
            print("  - " .. filename)
        end
    end

    print("")
    print("Done!")
end

-- Run the main function
main()
