#!/bin/bash

# =================================================================
# INSTRUCTIONS: 
# 1. REPLACE THE API_TOKEN BELOW WITH YOUR GITHUB PERSONAL ACCESS TOKEN.
# 2. Run: bash download_all_sets.sh
# =================================================================

# --- Configuration ---
API_TOKEN="GITHUB_ACCESS_TOKEN" # <<-- PUT YOUR TOKEN HERE
OUTPUT_ROOT_DIR="DOWNLOADED_SETS"            # Base directory for all downloads
BRANCH="main"                                # All provided links use the 'main' branch
# ---------------------

# --- List of all Directory URLs (Same as before) ---
#ALL_URLS="https://github.com/supergb-denny/supergb-denny.github.io/tree/main/sets/RPGM-files https://github.com/dnazangy/dnazangy.github.io/tree/main/sets/SHU-files https://github.com/schwa77/schwa77.github.io/tree/main/sets/KRK-files https://github.com/rickyrister/rickyrister.github.io/tree/main/sets/F2HU-files https://github.com/shadriarch2/shadriarch2.github.io/tree/main/sets/ELV-files https://github.com/leetwizard/leetwizard.github.io/tree/main/sets/EOR-files https://github.com/parasign-0/parasign-0.github.io/tree/main/sets/NOT-files https://github.com/curio36/curio36.github.io/tree/main/sets/TVN-files https://github.com/rrredbay/rrredbay.github.io/tree/main/sets/WGJ-files https://github.com/n3onblue/n3onblue.github.io/tree/main/sets/DHW-files https://github.com/trewqofficial/trewqofficial.github.io/tree/main/sets/HFB-files https://github.com/moxtober2025/moxtober2025.github.io/tree/main/sets/LDT-files https://github.com/bancrabs/bancrabs.github.io/tree/main/sets/WLG-files https://github.com/mattelonian/mattelonian.github.io/tree/main/sets/MVX-files https://github.com/kattalist/kattalist.github.io/tree/main/sets/SGP-files https://github.com/grapplex/grapplex.github.io/tree/main/sets/CYO-files https://github.com/drchipmunk/drchipmunk.github.io/tree/main/sets/BLV-files https://github.com/platypeople/platypeople.github.io/tree/main/sets/POP2-files https://github.com/magictheegg/magictheegg.github.io/tree/main/sets/ICO-files https://github.com/mattaurawarrior/mattaurawarrior.github.io/tree/main/sets/IWH-files https://github.com/megazumarill/megazumarill.github.io/tree/main/sets/WOO-files https://github.com/silver-parabellum/silver-parabellum.github.io/tree/main/sets/ONI-files https://github.com/provocativemtg/provocativemtg.github.io/tree/main/sets/EDR-files https://github.com/covetedpeacock/covetedpeacock.github.io/tree/main/sets/VLR-files https://github.com/ignitedxsoul/ignitedxsoul.github.io/tree/main/sets/OPZ-files https://github.com/pipsqueakmtg/pipsqueakmtg.github.io/tree/main/sets/MOV-files https://github.com/stasisbotwastaken/stasisbotwastaken.github.io/tree/main/sets/ABY-files https://github.com/kumrac/kumrac.github.io/tree/main/sets/VTK-files"
ALL_URLS="https://github.com/grapplex/grapplex.github.io/tree/main/sets/SPG-files"

# -----------------------------------------------------------
# NEW RECURSIVE FUNCTION
# Arguments: $1 = Repository Path, $2 = Current Folder Path, $3 = Local Output Directory
# -----------------------------------------------------------
process_directory() {
  local REPO_PATH="$1"
  local FOLDER_PATH="$2"
  local TARGET_DIR="$3"
  local API_URL="https://api.github.com/repos/$REPO_PATH/contents/$FOLDER_PATH?ref=$BRANCH"

  # 1. Fetch content list from the API
  API_RESPONSE=$(curl -sL -H "Authorization: token $API_TOKEN" "$API_URL")

  if [[ "$API_RESPONSE" == *'"message": "Not Found"'* ]]; then
    echo "    -> ERROR: Path $FOLDER_PATH not found in $REPO_PATH. Skipping."
    return 1
  fi

  # Create local directory if it doesn't exist
  mkdir -p "$TARGET_DIR"

  # 2. Extract data using awk and write to a temporary file.
  local TEMP_FILE=$(mktemp)

  # Using classic AWK match() function (supported by all versions)
  echo "$API_RESPONSE" | awk '
  BEGIN { RS="}" } # Process one JSON object (file/dir) per record
  {
      name=""; type=""; path=""; url="";
      
      # Use simple match() and the resulting RSTART/RLENGTH variables
      
      # Extract Name
      if (match($0, /"name": *"[^"]+"/)) {
          name = substr($0, RSTART, RLENGTH);
          gsub(/"name": *"|"/, "", name);
      }
      
      # Extract Type
      if (match($0, /"type": *"[^"]+"/)) {
          type = substr($0, RSTART, RLENGTH);
          gsub(/"type": *"|"/, "", type);
      }
      
      # Extract Path
      if (match($0, /"path": *"[^"]+"/)) {
          path = substr($0, RSTART, RLENGTH);
          gsub(/"path": *"|"/, "", path);
      }
      
      # Extract Download URL
      if (match($0, /"download_url": *"[^"]+"/)) {
          url = substr($0, RSTART, RLENGTH);
          gsub(/"download_url": *"|"/, "", url);
      }
      
      # If we successfully found a type, print a clean, pipe-separated record
      if (type != "") {
          print name "|" type "|" path "|" url
      }
  }' | sed '/^[[:space:]]*$/d' > "$TEMP_FILE" # Final sed filter removes blank lines

  # 3. Loop through the clean data from the temporary file
  while IFS="|" read -r ITEM_NAME ITEM_TYPE ITEM_PATH DOWNLOAD_URL; do

    if [ -z "$ITEM_NAME" ]; then
      continue
    fi
    
    if [ "$ITEM_TYPE" == "file" ]; then
      # Found a file, download it
      echo "    -> Downloading file: $ITEM_PATH"
      
      # Only download if the URL is not empty 
      if [ -n "$DOWNLOAD_URL" ]; then
        local OUTPUT_PATH="$TARGET_DIR/$ITEM_NAME"
        curl -sL -o "$OUTPUT_PATH" "$DOWNLOAD_URL"
        sleep 0.05 
      else
         echo "    -> WARNING: File $ITEM_NAME has no download URL. Skipping."
      fi

    elif [ "$ITEM_TYPE" == "dir" ]; then
      # Found a directory, recurse into it
      echo "    -> Entering directory: $ITEM_PATH"
      # Call this function recursively with the new path
      process_directory "$REPO_PATH" "$ITEM_PATH" "$TARGET_DIR/$ITEM_NAME"
    fi

  done < "$TEMP_FILE"

  # 4. Clean up the temporary file
  rm "$TEMP_FILE"
}
# -----------------------------------------------------------
# END OF NEW RECURSIVE FUNCTION
# -----------------------------------------------------------


# --- Main Logic ---

# Validation check for the token
if [ "$API_TOKEN" == "YOUR_GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ -z "$API_TOKEN" ]; then
    echo "ERROR: Please replace 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN' with your actual token in the script."
    exit 1
fi

# Create root output directory
mkdir -p "$OUTPUT_ROOT_DIR"
echo "--- Starting Batch Download into $OUTPUT_ROOT_DIR ---"

# Loop through each URL in the list
for URL in $ALL_URLS; do
    
    # 1. Parse the URL to extract components
    # Extract everything between 'github.com/' and '/tree/main/' -> OWNER/REPO
    REPO_PATH=$(echo "$URL" | sed -E 's|https://github.com/([^/]+/[^/]+).*|\1|')
    
    # Extract everything after '/tree/main/' -> FOLDER_PATH (e.g., sets/F2HU-files)
    FOLDER_PATH=$(echo "$URL" | sed -E 's|.*\/tree\/main\/(.*)|\1|')
    
    # Use the last part of the FOLDER_PATH (e.g., F2HU-files) for the local folder name
    LOCAL_FOLDER_NAME=$(basename "$FOLDER_PATH")
    
    TARGET_DIR="$OUTPUT_ROOT_DIR/$LOCAL_FOLDER_NAME"
    
    echo -e "\n--- Processing Set: $LOCAL_FOLDER_NAME ---"
    echo "  -> Repository: $REPO_PATH"
    echo "  -> Target Folder: $FOLDER_PATH"
    
    # 2. Call the new recursive function to start the download for this set
    process_directory "$REPO_PATH" "$FOLDER_PATH" "$TARGET_DIR"
    
    echo "  -> Download complete for $LOCAL_FOLDER_NAME."
    
done

echo -e "\n--- All Batch Downloads Complete ---"