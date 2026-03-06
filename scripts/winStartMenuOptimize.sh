# DESCRIPTION
# winStartMenuOptimize.sh - Windows Start Menu Optimization Script
# Version: 1.2
# Recursively scans Windows Start Menu folders and applies optimization rules:
# - Promotes single useful items from folders to the root level
# - Deletes empty folders
# - Removes excluded items (readme files, uninstall files, .url shortcuts)
# Operates in dry-run mode by default with detailed logging and requires
# password confirmation before making actual changes.

# DEPENDENCIES
# - bash (MSYS2 environment; bash as provided by other environments may work)
# - zip (required for backup functionality - will attempt to install via pacman if missing)
# - Windows Start Menu access (appropriate permissions required)
# - For --all-users mode, Administrator privileges when you run the script

# USAGE
# With this script in your PATH, run it with the following switches:
# To run it for All Users, as an Administrator, run:
#    winStartMenuOptimize.sh --all-users        
# To run it for the current user, no switches just run:
#    winStartMenuOptimize.sh
#   
# The script always runs a dry mode first, displaying proposed changes
# and creating a log file. To apply changes, enter the password "FLUAB" when prompted.

# NOTES
# - Creates timestamped ZIP backups in ~/Desktop/StartMenuBackups/ before modifications
# - Log file: winStartMenuOptimizeDryRun.txt in current directory (overwritten each run)
# - Processes folders from deepest to shallowest level for safe directory removal
# - Excluded patterns: *readme*, *uninstall* (case insensitive), *.url files
# - All other items (especially .lnk files) are considered useful and promoted
# - Path resolution uses environment variables, cmd fallbacks, and legacy XP paths
# - Progress indicators shown during long operations (backup creation, directory scanning)
# - Color-coded output for better readability (disabled if output not to terminal)


# CODE
set -euo pipefail

# Configuration
SCRIPT_NAME="$(basename "$0")"
DRY_RUN=true
TARGET_ALL_USERS=false
LOG_FILE="$TEMP/winStartMenuOptimizeDryRun.txt"
BACKUP_DIR="$HOME/Desktop/StartMenuBackups"
CONFIRM_PASSWORD="FLUAB"
TEMP_DIR="${TMPDIR:-/tmp}/winstartmenu.$$"
PASSWORD_ATTEMPTS=3

# Colors for output - using printf for better compatibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging - use printf instead of echo -e for better compatibility
log() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
    printf "[%s] INFO: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1" >&2
    printf "[%s] WARN: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
    printf "[%s] ERROR: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
    exit 1
}

success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

progress() {
    printf "${BLUE}[PROGRESS]${NC} %s\r" "$1"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all-users)
                TARGET_ALL_USERS=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Check if running as administrator (via write test to Program Files)
check_admin() {
    local test_file="/c/Program Files/winstartmenu_test.tmp"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file"
        return 0
    else
        return 1
    fi
}

# Get Windows Start Menu path
get_start_menu_path() {
    local start_menu_path=""
    
    if $TARGET_ALL_USERS; then
        # Try different methods for All Users Start Menu
        if [[ -n "${ALLUSERSPROFILE:-}" ]]; then
            start_menu_path="${ALLUSERSPROFILE}/Microsoft/Windows/Start Menu"
        elif [[ -n "${PROGRAMDATA:-}" ]]; then
            start_menu_path="${PROGRAMDATA}/Microsoft/Windows/Start Menu"
        else
            # Fall back to cmd query
            start_menu_path=$(cmd /c "echo %ALLUSERSPROFILE%" 2>/dev/null | tr -d '\r')/Microsoft/Windows/Start\ Menu
        fi
        
        # Verify path exists
        if [[ ! -d "$start_menu_path" ]]; then
            # Try Windows XP style
            start_menu_path="/c/Documents and Settings/All Users/Start Menu"
        fi
    else
        # Try different methods for Current User Start Menu
        if [[ -n "${USERPROFILE:-}" ]]; then
            start_menu_path="${USERPROFILE}/AppData/Roaming/Microsoft/Windows/Start Menu"
        elif [[ -n "${APPDATA:-}" ]]; then
            start_menu_path="${APPDATA}/Microsoft/Windows/Start Menu"
        else
            # Fall back to cmd query
            start_menu_path=$(cmd /c "echo %APPDATA%" 2>/dev/null | tr -d '\r')/Microsoft/Windows/Start\ Menu
        fi
        
        # Verify path exists
        if [[ ! -d "$start_menu_path" ]]; then
            # Try Windows XP style
            start_menu_path="/c/Documents and Settings/$USER/Start Menu"
        fi
    fi
    
    # Convert to MSYS2 path if needed
    start_menu_path=$(cygpath -u "$start_menu_path" 2>/dev/null || echo "$start_menu_path")
    
    if [[ ! -d "$start_menu_path" ]]; then
        error "Start Menu path not found: $start_menu_path"
    fi
    
    echo "$start_menu_path"
}

# Check for zip dependency
check_zip_dependency() {
    if ! command -v zip &>/dev/null; then
        warn "zip command not found. Backup functionality requires zip."
        read -p "Install zip via pacman? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Installing zip..."
            pacman -S --noconfirm zip || error "Failed to install zip"
        else
            warn "Continuing without backup capability"
            return 1
        fi
    fi
    return 0
}

# Create backup
create_backup() {
    local start_menu_path="$1"
    local backup_file="$BACKUP_DIR/startmenu_$(date '+%Y%m%d_%H%M%S').zip"
    
    log "Creating backup in $backup_file..."
    mkdir -p "$BACKUP_DIR"
    
    # Convert to Windows path for zip
    local win_path=$(cygpath -w "$start_menu_path")
    local win_backup=$(cygpath -w "$backup_file")
    
    if command -v zip &>/dev/null; then
        # Use zip with progress indicator
        (cd "$start_menu_path" && zip -r "$win_backup" . -q) &
        local zip_pid=$!
        
        # Show spinner while zipping
        local spin='-\|/'
        local i=0
        while kill -0 $zip_pid 2>/dev/null; do
            i=$(( (i+1) % 4 ))
            progress "Creating backup... ${spin:$i:1}"
            sleep 0.1
        done
        wait $zip_pid
        echo -e "\r\033[K" # Clear progress line
        
        if [[ -f "$backup_file" ]]; then
            success "Backup created: $backup_file"
            return 0
        fi
    fi
    
    warn "Backup creation failed"
    return 1
}

# Check if file is excluded
is_excluded() {
    local file="$1"
    local filename=$(basename "$file" | tr '[:upper:]' '[:lower:]')
    
    # Check for readme or uninstall in name
    if [[ "$filename" == *"readme"* ]] || [[ "$filename" == *"uninstall"* ]]; then
        return 0
    fi
    
    # Check for .url extension
    if [[ "$file" == *.url ]]; then
        return 0
    fi
    
    return 1
}

# Scan and process directories
process_start_menu() {
    local start_menu_path="$1"
    local temp_file="$TEMP_DIR/dirtree.txt"
    local moves_file="$TEMP_DIR/moves.txt"
    local rmdirs_file="$TEMP_DIR/rmdirs.txt"
    
    mkdir -p "$TEMP_DIR"
    
    log "Scanning Start Menu directory: $start_menu_path"
    echo "Start Menu Optimization - $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Step 1: Get complete directory tree
    progress "Building directory tree..."
    cd "$start_menu_path"
    find . -type d | sort -r > "$temp_file"
    echo -e "\r\033[K" # Clear progress line
    
    local total_dirs=$(wc -l < "$temp_file")
    log "Found $total_dirs directories to process"
    
    # Step 2: Analyze each directory
    local current=0
    > "$moves_file"
    > "$rmdirs_file"
    
    while IFS= read -r dir; do
        # Remove leading ./ if present
        dir="${dir#./}"
        [[ -z "$dir" ]] && continue
        
        current=$((current + 1))
        progress "Analyzing directory $current/$total_dirs: $dir"
        
        # Get all items in this directory (files and subdirs)
        local dir_path="$start_menu_path/$dir"
        
        # Skip if directory doesn't exist anymore
        [[ ! -d "$dir_path" ]] && continue
        
        # Check if directory is empty
        if [[ -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
            echo "$dir" >> "$rmdirs_file"
            continue
        fi
        
        # Count items in directory
        local useful_items=0
        local useful_item=""
        local has_subdirs=false
        
        while IFS= read -r item; do
            local item_path="$dir_path/$item"
            
            if [[ -d "$item_path" ]]; then
                has_subdirs=true
                break
            elif [[ -f "$item_path" ]]; then
                if ! is_excluded "$item"; then
                    useful_items=$((useful_items + 1))
                    useful_item="$item"
                fi
            fi
        done < <(ls -A "$dir_path" 2>/dev/null)
        
        # Apply rule: Single useful item, no subdirs
        if [[ $useful_items -eq 1 ]] && [[ "$has_subdirs" == "false" ]]; then
            echo "$dir|$useful_item" >> "$moves_file"
        fi
        
    done < "$temp_file"
    
    echo -e "\r\033[K" # Clear progress line
    
    # Step 3: Process moves (from deepest to shallowest)
	if [[ -s "$moves_file" ]]; then
		log "Processing folder promotions..."
		while IFS='|' read -r dir item; do
			local source="$start_menu_path/$dir/$item"
			local target="$start_menu_path/$item"
			
			# Ensure target doesn't exist
			if [[ -e "$target" ]]; then
				target="$start_menu_path/$(basename "$dir")_$item"
			fi
			
			if $DRY_RUN; then
				echo "[DRY RUN] Would promote to Start Menu root: $dir/$item" >> "$LOG_FILE"
				echo "[DRY RUN] Would delete folder: $dir" >> "$LOG_FILE"
			else
				if [[ -f "$source" ]]; then
					mv -v "$source" "$target" >> "$LOG_FILE" 2>&1
					echo "Promoted to Start Menu root: $dir/$item" >> "$LOG_FILE"
				fi
			fi
		done < "$moves_file"
	fi
    
    # Step 4: Remove empty directories (deepest first)
    if [[ -s "$rmdirs_file" ]]; then
        log "Processing empty directory removal..."
        while IFS= read -r dir; do
            local dir_path="$start_menu_path/$dir"
            
            # Double-check directory is empty
            if [[ -d "$dir_path" ]] && [[ -z "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
                if $DRY_RUN; then
                    echo "[DRY RUN] Would delete empty folder: $dir" >> "$LOG_FILE"
                else
                    rmdir -v "$dir_path" >> "$LOG_FILE" 2>&1
                fi
            fi
        done < "$rmdirs_file"
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    # Show banner
    echo "========================================="
    echo "   Windows Start Menu Optimizer"
    echo "========================================="
    
    # Check permissions if targeting all users
    if $TARGET_ALL_USERS; then
        log "Targeting All Users Start Menu"
        if ! check_admin; then
            error "All Users mode requires Administrator privileges.\nPlease run as Administrator or use without --all-users for current user."
        fi
    else
        log "Targeting Current User Start Menu"
    fi
    
    # Get Start Menu path
    local start_menu_path=$(get_start_menu_path)
    log "Start Menu path: $start_menu_path"
    
    # Verify write access
    if [[ ! -w "$start_menu_path" ]]; then
        error "No write access to Start Menu folder.\nPlease check permissions or run as Administrator."
    fi
    
    # Initialize log
    > "$LOG_FILE"
    
    # Perform dry run
    log "Performing dry run..."
    process_start_menu "$start_menu_path"
    
    # Open log file
    if [[ -f "$LOG_FILE" ]]; then
        log "Opening dry run log..."
        start "$(cygpath -w "$LOG_FILE")" 2>/dev/null || cat "$LOG_FILE"
    fi
    
    # Show summary
    echo
    echo "========================================="
    if [[ -s "$LOG_FILE" ]]; then
        local changes=$(grep -c "^\[DRY RUN\]" "$LOG_FILE" || true)
        echo "Dry run completed: $changes changes would be made"
        grep "^\[DRY RUN\]" "$LOG_FILE" | sed 's/\[DRY RUN\]/  →/g'
    else
        echo "Dry run completed: No changes needed"
    fi
    echo "========================================="
    
    # Ask for confirmation
    if [[ -s "$LOG_FILE" ]]; then
        echo
		echo "A dry run log file was opened in the default handler program for the .txt"
		echo "extension, and a summary of the same was also printed above. Examine it for"
		echo "accuracy, and if desired, continue to apply the changes."
        echo -e "${YELLOW}To apply these changes, enter the word 'FLUAB' (without quote marks)."
        
        for ((attempt=1; attempt<=PASSWORD_ATTEMPTS; attempt++)); do
            read -s -p "Password: " entered_password
            echo
            
            if [[ "$entered_password" == "$CONFIRM_PASSWORD" ]]; then
                echo -e "${GREEN}Password accepted.${NC}"
                
                # Create backup if possible
                if check_zip_dependency; then
                    create_backup "$start_menu_path"
                fi
                
                # Perform live changes
                DRY_RUN=false
                log "Applying changes..."
                process_start_menu "$start_menu_path"
                
                success "Optimization complete!"
                break
            else
                remaining=$((PASSWORD_ATTEMPTS - attempt))
                if [[ $remaining -gt 0 ]]; then
                    warn "Incorrect password. $remaining attempts remaining."
                else
                    error "Maximum attempts exceeded. Exiting."
                fi
            fi
        done
    else
        log "No changes needed. Exiting."
    fi
    
    # Suggestions
    echo
    echo "========================================="
    echo "Suggestions:"
    if $TARGET_ALL_USERS; then
        echo "- Run without --all-users to optimize your personal Start Menu"
    else
        echo "- Run with --all-users as Administrator to optimize All Users Start Menu"
    fi
	echo "NOTE that you may end up with an inconsistent state (pointelessly empty start menu folders) if you do not to both.)
    echo "========================================="
}

# Run main function with all arguments
main "$@"