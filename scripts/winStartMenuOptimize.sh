# DESCRIPTION
# This script analyzes and optimizes Windows Start Menu folder structure by promoting
# single useful shortcuts to the top level while removing folders containing only
# readme, uninstall, or web URL items. By default, it performs a dry run that logs
# proposed changes for user review before requiring explicit confirmation.
#
# The script automatically creates timestamped ZIP backups before making any changes,
# and checks for required utilities (zip/unzip) with installation guidance.
#
# After completion, it suggests running the complementary mode (user/all-users)
# to help clean up both Start Menu locations.
#
# The script processes folders from deepest to shallowest level, identifying folders where:
# - There is exactly one non-excluded item (shortcut, executable, etc.)
# - All other items in the folder are excluded items (readme, uninstall, web URLs)
# The non-excluded item is moved up to the base Start Menu folder, and the original
# folder is deleted along with its excluded items.

# DEPENDENCIES
# - MSYS2 bash environment on Windows
# - Standard Unix tools: find, grep, sort, awk, rev, cut
# - Windows utilities: start (for opening log files), cmd /c (for path resolution)
# - ZIP/UNZIP utilities (script will prompt to install if missing)
# - Access to Windows Start Menu directories via environment variables or known paths
# - For All Users mode: Must be run as Administrator

# USAGE
#   ./winStartMenuOptimize.sh              # Dry run only (default) - current user only
#   ./winStartMenuOptimize.sh --all-users   # Target All Users Start Menu (requires Admin)
#
# Process:
#   1. Script performs dry run, creates winStartMenuOptimizeDryRun.txt
#   2. Opens log file in default text editor for review
#   3. Prompts for confirmation password "FLUAB" to proceed with actual changes
#   4. On correct password, creates timestamped ZIP backups of target Start Menu(s)
#   5. Applies file move/delete operations
#   6. Removes dry run log file on success
#   7. Suggests running the complementary mode for complete Start Menu optimization

# NOTES
# - The script dynamically resolves Start Menu paths using multiple methods:
#   * Environment variables (USERPROFILE, ALLUSERSPROFILE, PROGRAMDATA)
#   * Windows shell commands via cmd /c
#   * Fallback to known Windows version paths if needed
# - Permission checking is explicit: the script tests write access to the target directory
#   before attempting any modifications, with clear error messages
# - Automatic backups are created in ~/Desktop/StartMenuBackups/ with timestamps
# - Items are considered "excluded" if filename (case-insensitive) contains:
#   * "readme" (anywhere in filename)
#   * "uninstall" (anywhere in filename)
#   * Or if it's a web URL shortcut (extension .url)
# - Non-excluded items include .lnk files and other file types not matching exclusion criteria
# - The script processes folders in depth-first order (deepest first)
# - Empty folders are automatically removed during processing
# - Log file includes timestamps and clearly marks proposed actions
# - Script is modular and can be run from any working directory

# CODE

# Enable strict error handling
set -euo pipefail

# Configuration
SCRIPT_NAME="winStartMenuOptimize"
LOG_FILE="${SCRIPT_NAME}DryRun.txt"
CONFIRM_PASSWORD="FLUAB"
DRY_RUN=true
ALL_USERS=false
BACKUP_DIR="${HOME}/Desktop/StartMenuBackups"

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --all-users)
            ALL_USERS=true
            shift
            ;;
        *)
            # Ignore other arguments
            ;;
    esac
done

# Function to suggest complementary run
suggest_complementary_run() {
    local current_mode="$1"
    local admin_status="$([ -w "/c/Program Files" ] 2>/dev/null && echo "admin" || echo "non-admin")"
    
    echo ""
    echo "=== PRO TIP: Complete Start Menu Optimization ==="
    echo ""
    
    if [[ "$current_mode" == "user" ]]; then
        echo "You've just optimized your personal Start Menu."
        echo ""
        echo "The All Users Start Menu (affecting all accounts on this PC)"
        echo "may also benefit from cleaning, but requires Administrator privileges."
        echo ""
        echo "To optimize the All Users Start Menu:"
        echo "  1. Restart your MSYS2 terminal AS ADMINISTRATOR"
        echo "  2. Run the same script with the --all-users flag:"
        echo "     ./winStartMenuOptimize.sh --all-users"
        echo ""
        echo "This will give you the same dry-run -> review -> confirm workflow"
        echo "for the system-wide Start Menu location."
        
    else  # all-users mode
        echo "You've just optimized the All Users (system-wide) Start Menu."
        echo ""
        echo "Your personal Start Menu may still have folders that need cleaning."
        echo ""
        if [[ "$admin_status" == "admin" ]]; then
            echo "Since you're currently running as Administrator, you can either:"
            echo "  1. Run the script in a regular (non-admin) MSYS2 terminal:"
            echo "     ./winStartMenuOptimize.sh"
            echo "  2. Or stay here and run it without --all-users (will target your profile):"
            echo "     ./winStartMenuOptimize.sh"
        else
            echo "To optimize your personal Start Menu:"
            echo "  Run the script without the --all-users flag:"
            echo "  ./winStartMenuOptimize.sh"
        fi
        echo ""
        echo "For maximum Start Menu minimalism, run BOTH modes!"
    fi
}

# Function to check for required utilities
check_dependencies() {
    local missing_deps=()
    
    # Check for zip
    if ! command -v zip &> /dev/null; then
        missing_deps+=("zip")
    fi
    
    # Check for unzip (optional but nice to have for verification)
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "WARNING: Missing required utilities: ${missing_deps[*]}"
        echo ""
        echo "These can be installed easily with MSYS2's package manager:"
        echo "  pacman -S ${missing_deps[*]}"
        echo ""
        echo "Would you like to install them now?"
        select install_choice in "Yes" "No (exit script)"; do
            case $install_choice in
                "Yes")
                    echo "Installing ${missing_deps[*]}..."
                    pacman -S --noconfirm "${missing_deps[@]}"
                    if [[ $? -eq 0 ]]; then
                        echo "Installation successful!"
                        break
                    else
                        echo "Installation failed. Please install manually and rerun."
                        exit 1
                    fi
                    ;;
                "No (exit script)")
                    echo "Exiting. Please install required utilities and rerun."
                    exit 1
                    ;;
            esac
        done
    fi
    
    # Verify zip is now available
    if ! command -v zip &> /dev/null; then
        echo "ERROR: zip utility is required but not available. Exiting."
        exit 1
    fi
}

# Function to create backup of Start Menu folder
create_backup() {
    local source_path="$1"
    local backup_type="$2"  # "User" or "AllUsers"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/${SCRIPT_NAME}_${backup_type}_${timestamp}.zip"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    echo "  Creating backup of ${backup_type} Start Menu..."
    echo "  Source: $source_path"
    echo "  Backup: $backup_file"
    
    # Get the parent directory and folder name for zip
    local parent_dir=$(dirname "$source_path")
    local folder_name=$(basename "$source_path")
    
    # Create zip archive
    (cd "$parent_dir" && zip -r "$backup_file" "$folder_name" > /dev/null)
    
    if [[ $? -eq 0 && -f "$backup_file" ]]; then
        echo "  Backup created successfully: $(basename "$backup_file")"
        echo "$backup_file"  # Return the backup file path
        return 0
    else
        echo "  Backup failed!"
        return 1
    fi
}

# Function to check if we have write access to a directory
check_write_access() {
    local dir="$1"
    local test_file="${dir}/.write_test_$$"
    
    # Try to create a test file
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file" 2>/dev/null
        return 0  # Have write access
    else
        return 1  # No write access
    fi
}

# Function to resolve Windows paths reliably across different Windows versions
resolve_start_menu_path() {
    local target_all_users=$1
    local resolved_path=""
    
    if [[ "$target_all_users" == true ]]; then
        # Method 1: Try ALLUSERSPROFILE environment variable (works on most Windows versions)
        if [[ -n "${ALLUSERSPROFILE:-}" ]]; then
            local candidate="${ALLUSERSPROFILE}/Microsoft/Windows/Start Menu/Programs"
            candidate=$(echo "$candidate" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 2: Try PROGRAMDATA (Windows Vista/7/8/10/11)
        if [[ -n "${PROGRAMDATA:-}" ]]; then
            local candidate="${PROGRAMDATA}/Microsoft/Windows/Start Menu/Programs"
            candidate=$(echo "$candidate" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 3: Use cmd /c to query known folder path via shell command
        local win_path
        win_path=$(cmd.exe /c "echo %ProgramData%\Microsoft\Windows\Start Menu\Programs" 2>/dev/null | tr -d '\r')
        if [[ -n "$win_path" ]]; then
            local candidate=$(echo "$win_path" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 4: Fallback to known Windows XP/2003 path for older systems
        local fallback="/c/Documents and Settings/All Users/Start Menu/Programs"
        if [[ -d "$fallback" ]]; then
            echo "$fallback"
            return 0
        fi
        
        echo "ERROR: Could not locate All Users Start Menu path" >&2
        return 1
    else
        # Current user Start Menu
        # Method 1: Use USERPROFILE (most reliable)
        if [[ -n "${USERPROFILE:-}" ]]; then
            local candidate="${USERPROFILE}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs"
            candidate=$(echo "$candidate" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 2: Use APPDATA (also reliable)
        if [[ -n "${APPDATA:-}" ]]; then
            local candidate="${APPDATA}/Microsoft/Windows/Start Menu/Programs"
            candidate=$(echo "$candidate" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 3: Use cmd /c with shell: command
        local win_path
        win_path=$(cmd.exe /c "echo %APPDATA%\Microsoft\Windows\Start Menu\Programs" 2>/dev/null | tr -d '\r')
        if [[ -n "$win_path" ]]; then
            local candidate=$(echo "$win_path" | sed 's|\\|/|g' | sed 's|C:|/c|')
            if [[ -d "$candidate" ]]; then
                echo "$candidate"
                return 0
            fi
        fi
        
        # Method 4: Fallback for older Windows (XP/2003)
        local username=$(whoami | sed 's/.*\\//')
        local fallback="/c/Documents and Settings/${username}/Start Menu/Programs"
        if [[ -d "$fallback" ]]; then
            echo "$fallback"
            return 0
        fi
        
        echo "ERROR: Could not locate current user Start Menu path" >&2
        return 1
    fi
}

# Determine target Start Menu directory using robust resolution
START_MENU_BASE=$(resolve_start_menu_path "$ALL_USERS")
if [[ $? -ne 0 || -z "$START_MENU_BASE" ]]; then
    echo "Failed to resolve Start Menu path. Exiting." >&2
    exit 1
fi

# Display target information
echo "winStartMenuOptimize - Windows Start Menu Optimizer"
echo "=================================================="
echo "Target: $START_MENU_BASE"
echo ""

# Check for required dependencies first
check_dependencies

# Check write access to the target directory
if check_write_access "$START_MENU_BASE"; then
    echo "Write access confirmed for target directory"
else
    echo ""
    echo "WARNING: Cannot write to target directory!"
    echo ""
    if [[ "$ALL_USERS" == true ]]; then
        echo "The All Users Start Menu requires Administrator privileges."
        echo ""
        echo "SOLUTIONS:"
        echo "  1. Restart your MSYS2 terminal AS ADMINISTRATOR and try again"
        echo "  2. Run without --all-users to modify your personal Start Menu only"
        echo "  3. Continue with dry run only (no changes will be possible)"
        echo ""
        echo "Note: Dry run will still work to show you what WOULD be changed"
        echo "      if you had proper permissions."
    else
        echo "This is unexpected - your personal Start Menu should be writable."
        echo "You may have permission issues with your user profile."
        echo ""
        echo "SOLUTIONS:"
        echo "  1. Check if you're running in a restricted environment"
        echo "  2. Try running MSYS2 as Administrator (not typically needed)"
        echo "  3. Continue with dry run only (no changes will be possible)"
    fi
    echo ""
    
    # In dry run mode, we continue (since dry run doesn't need write access)
    if [[ "$DRY_RUN" == true ]]; then
        echo "Continuing with dry run only (no write access needed for analysis)..."
        echo ""
    fi
fi

# Function to check if an item is excluded (readme, uninstall, or web URL)
is_excluded_item() {
    local item_path="$1"
    local item_name=$(basename "$item_path" | tr '[:upper:]' '[:lower:]')
    
    # Check if it's a web URL shortcut (.url extension)
    if [[ "$item_path" == *.url ]]; then
        return 0  # True (excluded)
    fi
    
    # Check if filename contains "readme" or "uninstall" (case-insensitive)
    if [[ "$item_name" == *"readme"* ]] || [[ "$item_name" == *"uninstall"* ]]; then
        return 0  # True (excluded)
    fi
    
    return 1  # False (not excluded)
}

# Function to get all folders in the Start Menu, sorted by depth (deepest first)
get_folders_by_depth() {
    # Find all directories, count depth by number of slashes, sort by depth descending
    find "$START_MENU_BASE" -type d -not -path "$START_MENU_BASE" 2>/dev/null | \
        awk '{depth=gsub(/\//,"/"); print depth " " $0}' | \
        sort -rn | \
        cut -d' ' -f2- || true
}

# Function to initialize log file
init_log() {
    echo "winStartMenuOptimize Dry Run Log - $(date)" > "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
    echo "Target directory: $START_MENU_BASE" >> "$LOG_FILE"
    echo "Write access: $([ -w "$START_MENU_BASE" ] && echo "Yes" || echo "No")" >> "$LOG_FILE"
    echo "Windows version: $(cmd.exe /c ver 2>/dev/null | tr -d '\r' | head -1)" >> "$LOG_FILE"
    echo "Running as Admin: $([ -w "/c/Program Files" ] 2>/dev/null && echo "Yes" || echo "No")" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Function to log a message
log_message() {
    echo "$1" >> "$LOG_FILE"
}

# Function to process a single folder (dry run mode)
process_folder_dry() {
    local folder="$1"
    
    # Skip if folder doesn't exist
    [[ ! -d "$folder" ]] && return
    
    # Get all items in the folder (excluding . and ..)
    local items=()
    while IFS= read -r -d '' item; do
        items+=("$item")
    done < <(find "$folder" -maxdepth 1 -type f -print0 2>/dev/null || true)
    
    # Skip if no items in folder
    [[ ${#items[@]} -eq 0 ]] && return
    
    # Categorize items into excluded and non-excluded
    local excluded=()
    local non_excluded=()
    
    for item in "${items[@]}"; do
        if is_excluded_item "$item"; then
            excluded+=("$item")
        else
            non_excluded+=("$item")
        fi
    done
    
    # Check if this folder meets our criteria
    if [[ ${#non_excluded[@]} -eq 1 ]] && [[ ${#excluded[@]} -ge 0 ]]; then
        local item_to_move="${non_excluded[0]}"
        local item_name=$(basename "$item_to_move")
        
        log_message "Folder: $folder"
        log_message "  Would move: $item_name -> $START_MENU_BASE/"
        log_message "  Would delete folder containing:"
        for excl in "${excluded[@]}"; do
            log_message "    - $(basename "$excl")"
        done
        log_message "---"
    fi
}

# Function to process a single folder (live mode)
process_folder_live() {
    local folder="$1"
    
    # Skip if folder doesn't exist (might have been deleted in previous iteration)
    [[ ! -d "$folder" ]] && return
    
    # Get all items in the folder (excluding . and ..)
    local items=()
    while IFS= read -r -d '' item; do
        items+=("$item")
    done < <(find "$folder" -maxdepth 1 -type f -print0 2>/dev/null || true)
    
    # Skip if no items in folder
    [[ ${#items[@]} -eq 0 ]] && return
    
    # Categorize items into excluded and non-excluded
    local excluded=()
    local non_excluded=()
    
    for item in "${items[@]}"; do
        if is_excluded_item "$item"; then
            excluded+=("$item")
        else
            non_excluded+=("$item")
        fi
    done
    
    # Check if this folder meets our criteria
    if [[ ${#non_excluded[@]} -eq 1 ]] && [[ ${#excluded[@]} -ge 0 ]]; then
        local item_to_move="${non_excluded[0]}"
        local item_name=$(basename "$item_to_move")
        
        # Move the non-excluded item to base Start Menu
        if mv -v "$item_to_move" "$START_MENU_BASE/"; then
            echo "  Moved: $item_name to Start Menu base"
            
            # Delete the now-empty or excluded-items-only folder
            if rm -rf "$folder"; then
                echo "  Deleted folder: $folder"
            else
                echo "  Warning: Failed to delete folder: $folder" >&2
            fi
        else
            echo "  Error: Failed to move $item_name" >&2
        fi
    fi
}

# Function to perform dry run
do_dry_run() {
    echo "Performing dry run analysis..."
    init_log
    
    local folders=()
    while IFS= read -r folder; do
        folders+=("$folder")
    done < <(get_folders_by_depth)
    
    local processed=0
    for folder in "${folders[@]}"; do
        if [[ -d "$folder" ]]; then
            process_folder_dry "$folder"
            ((processed++))
        fi
    done
    
    log_message "Dry run complete! Analyzed $processed folders."
    echo "Dry run complete. Log file created: $LOG_FILE"
}

# Function to perform live modifications with backup
do_live_modifications() {
    # Double-check write access before proceeding
    if ! check_write_access "$START_MENU_BASE"; then
        echo ""
        echo "ERROR: Cannot write to target directory!"
        echo "Live modifications aborted."
        echo ""
        if [[ "$ALL_USERS" == true ]]; then
            echo "The All Users Start Menu requires Administrator privileges."
            echo "Please restart your MSYS2 terminal as Administrator and try again."
        else
            echo "Your personal Start Menu appears to be unwritable."
            echo "This is unusual - please check your permissions."
        fi
        echo "Log file preserved at: $LOG_FILE"
        exit 1
    fi
    
    echo ""
    echo "Creating backups before proceeding..."
    echo "======================================"
    
    # Determine backup type based on context
    local backup_type="User"
    [[ "$ALL_USERS" == true ]] && backup_type="AllUsers"
    
    # Create backup of target directory
    local backup_file=$(create_backup "$START_MENU_BASE" "$backup_type")
    
    if [[ $? -ne 0 ]]; then
        echo ""
        echo "Backup failed! Aborting to protect your data."
        echo "Please check disk space and permissions in $BACKUP_DIR"
        echo "Log file preserved at: $LOG_FILE"
        exit 1
    fi
    
    # If we're in All Users mode but also have access to user Start Menu,
    # offer to back that up too
    if [[ "$ALL_USERS" == true ]] && [[ -d "${USERPROFILE}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs" ]]; then
        echo ""
        echo "Would you also like to backup your personal Start Menu?"
        select backup_choice in "Yes" "No"; do
            case $backup_choice in
                "Yes")
                    local user_path=$(echo "${USERPROFILE}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs" | sed 's|\\|/|g' | sed 's|C:|/c|')
                    create_backup "$user_path" "User"
                    break
                    ;;
                "No")
                    echo "  Skipping personal Start Menu backup."
                    break
                    ;;
            esac
        done
    fi
    
    echo ""
    echo "Backups complete. Applying changes to Start Menu..."
    echo "===================================================="
    
    local folders=()
    while IFS= read -r folder; do
        folders+=("$folder")
    done < <(get_folders_by_depth)
    
    local processed=0
    for folder in "${folders[@]}"; do
        if [[ -d "$folder" ]]; then
            process_folder_live "$folder"
            ((processed++))
        fi
    done
    
    # Final pass: remove any empty directories that might have been left
    find "$START_MENU_BASE" -type d -empty -delete 2>/dev/null || true
    
    echo ""
    echo "Live modification complete! Processed $processed folders."
    echo "Backups saved in: $BACKUP_DIR"
    
    # Clean up log file
    if [[ -f "$LOG_FILE" ]]; then
        rm "$LOG_FILE"
        echo "Removed dry run log file."
    fi
}

# Main execution
main() {
    # Always perform dry run first
    do_dry_run
    
    # Open the log file for review
    echo ""
    echo "Opening log file for review..."
    if [[ -f "$LOG_FILE" ]]; then
        # MSYS2 handles path conversion automatically
        start "$LOG_FILE" 2>/dev/null || echo "Please open $LOG_FILE manually to review."
    fi
    
    # Prompt for confirmation
    echo ""
    echo "Please review the proposed changes in the log file."
    echo "If you approve these changes, type the confirmation password: $CONFIRM_PASSWORD"
    echo "Press Ctrl+C to abort."
    echo ""
    read -sp "Confirmation password: " user_input
    echo ""
    
    if [[ "$user_input" == "$CONFIRM_PASSWORD" ]]; then
        echo "Confirmation accepted."
        do_live_modifications
        echo ""
        echo "Start Menu optimization complete!"
        
        # Suggest complementary run based on current mode
        if [[ "$ALL_USERS" == true ]]; then
            suggest_complementary_run "all-users"
        else
            suggest_complementary_run "user"
        fi
    else
        echo "Incorrect password. Exiting without changes."
        echo "Log file preserved at: $LOG_FILE"
        exit 1
    fi
}

# Run the main function
main