# Load required libraries
library(tidyverse)
library(sf)
library(tidygeocoder)
library(here)

# Read the CSV file with explicit encoding handling
aqua_data <- read_csv(
  here("raw_data", "aquaculture_farms_compilation_web.csv"),
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) %>%
  # Clean up any encoding issues in the address field
  mutate(
    `Address or Location` = iconv(`Address or Location`, from = "UTF-8", to = "UTF-8", sub = ""),
    # Remove any problematic characters
    `Address or Location` = str_replace_all(`Address or Location`, "[^\x20-\x7E\x0A\x0D]", " "),
    # Clean up extra spaces
    `Address or Location` = str_squish(`Address or Location`),
    # Add ", Australia" to addresses that don't have it for better geocoding
    address_clean = if_else(
      !str_detect(`Address or Location`, "Australia"),
      paste0(`Address or Location`, ", Australia"),
      `Address or Location`
    )
  )

# View the structure
glimpse(aqua_data)

# Check which records have coordinates
cat("Records with coordinates:", sum(!is.na(aqua_data$Latitude)), "\n")
cat("Records needing geocoding:", sum(is.na(aqua_data$Latitude)), "\n")

# Filter out rows with missing or very short addresses
aqua_to_geocode <- aqua_data %>%
  filter(!is.na(`Address or Location`) & nchar(`Address or Location`) > 5)

cat("Records with valid addresses for geocoding:", nrow(aqua_to_geocode), "\n\n")

# Geocode using ArcGIS (more reliable for Australian addresses, no API key needed)
cat("Starting geocoding process using ArcGIS...\n")
cat("This may take several minutes.\n\n")

# Method 1: Batch geocoding with arcgis (more reliable)
aqua_data_geocoded <- aqua_to_geocode %>%
  geocode(
    address = address_clean,
    method = "arcgis",
    lat = lat,
    long = long,
    verbose = TRUE
  ) %>%
  mutate(
    # Use existing coordinates if available, otherwise use geocoded ones
    final_lat = ifelse(is.na(Latitude), lat, Latitude),
    final_lon = ifelse(is.na(Longitude), long, Longitude)
  )

# Report geocoding success
successful_geocodes <- sum(!is.na(aqua_data_geocoded$final_lat))
cat("\nGeocoding complete!\n")
cat("Successfully geocoded:", successful_geocodes, "out of", nrow(aqua_data_geocoded), "records\n\n")

# If ArcGIS didn't work well, try OSM for failed addresses
if(successful_geocodes < nrow(aqua_data_geocoded) * 0.5) {
  cat("ArcGIS geocoding had low success rate. Trying OSM for remaining addresses...\n\n")
  
  aqua_data_geocoded <- aqua_data_geocoded %>%
    rowwise() %>%
    mutate(
      osm_result = if(is.na(final_lat)) {
        list(tryCatch({
          Sys.sleep(1)  # Add delay to respect rate limits
          geocode_osm(address_clean, full_results = FALSE)
        },
        error = function(e) {
          data.frame(lat = NA_real_, long = NA_real_)
        }))
      } else {
        list(data.frame(lat = final_lat, long = final_lon))
      }
    ) %>%
    ungroup() %>%
    unnest_wider(osm_result, names_sep = "_") %>%
    mutate(
      final_lat = coalesce(final_lat, osm_result_lat),
      final_lon = coalesce(final_lon, osm_result_long)
    )
  
  successful_geocodes <- sum(!is.na(aqua_data_geocoded$final_lat))
  cat("After trying OSM: Successfully geocoded:", successful_geocodes, "out of", 
      nrow(aqua_data_geocoded), "records\n\n")
}

# Remove rows without valid coordinates
aqua_spatial_data <- aqua_data_geocoded %>%
  filter(!is.na(final_lat) & !is.na(final_lon))

# Check if we have any valid points
if(nrow(aqua_spatial_data) == 0) {
  cat("\n\n*** ERROR: No addresses could be geocoded! ***\n")
  cat("This might be due to:\n")
  cat("1. Network/firewall restrictions\n")
  cat("2. Geocoding service rate limits\n")
  cat("3. Address format issues\n\n")
  cat("Showing first 10 addresses that failed:\n")
  print(aqua_data_geocoded %>% 
          select(`Farm / Operator`, address_clean) %>% 
          head(10))
  stop("Cannot proceed without geocoded locations")
}

# Create spatial points (sf object) with WGS84 coordinate system
aqua_spatial <- st_as_sf(
  aqua_spatial_data,
  coords = c("final_lon", "final_lat"),
  crs = 4326,  # WGS84
  remove = FALSE  # Keep the coordinate columns in the data
)

# View summary
cat("\nTotal spatial points created:", nrow(aqua_spatial), "\n\n")

# Show what columns are included in the spatial object
cat("Columns included in spatial object:\n")
print(names(aqua_spatial))
cat("\n")

# Print some sample locations with State and Species
cat("Sample of geocoded locations with State and Species:\n")
print(aqua_spatial_data %>% 
        select(State, Species, `Farm / Operator`, `Address or Location`, 
               final_lat, final_lon) %>% 
        head(10))

# Summary by State
cat("\n\nFarms by State:\n")
print(aqua_spatial %>% 
        st_drop_geometry() %>% 
        count(State, sort = TRUE))

# Summary by Species
cat("\n\nFarms by Species (top 10):\n")
print(aqua_spatial %>% 
        st_drop_geometry() %>% 
        count(Species, sort = TRUE) %>%
        head(10))

# Simple plot to visualize
plot(st_geometry(aqua_spatial), 
     main = "Aquaculture Farms in Australia",
     pch = 16, 
     col = "blue",
     axes = TRUE)

# Color by state
if("State" %in% names(aqua_spatial) && nrow(aqua_spatial) > 0) {
  states <- unique(aqua_spatial$State)
  state_colors <- rainbow(length(states))
  names(state_colors) <- states
  
  plot(st_geometry(aqua_spatial), 
       main = "Aquaculture Farms by State",
       pch = 16, 
       col = state_colors[aqua_spatial$State],
       axes = TRUE)
  legend("topright", 
         legend = states, 
         col = state_colors,
         pch = 16,
         cex = 0.8,
         title = "State")
}

# Create output_data directory if it doesn't exist
if(!dir.exists(here("output_data"))) {
  dir.create(here("output_data"), recursive = TRUE)
}

# Save the spatial object as a shapefile (includes ALL attributes: State, Species, etc.)
st_write(aqua_spatial, 
         here("output_data", "aquaculture_farms_spatial.shp"), 
         delete_dsn = TRUE)

# Save as GeoJSON (includes ALL attributes: State, Species, etc.)
st_write(aqua_spatial, 
         here("output_data", "aquaculture_farms_spatial.geojson"), 
         delete_dsn = TRUE)

# Save the geocoded data as CSV (includes ALL attributes)
write_csv(aqua_data_geocoded, 
          here("output_data", "aquaculture_farms_geocoded.csv"))

# Also save a simplified version with just key columns for easy viewing
aqua_simplified <- aqua_spatial %>%
  st_drop_geometry() %>%
  select(State, Species, `Farm / Operator`, `Address or Location`, 
         final_lat, final_lon, `Production System`, 
         `Environment (Marine / Land-based)`)

write_csv(aqua_simplified, 
          here("output_data", "aquaculture_farms_simplified.csv"))

cat("\n\nFiles saved to output_data folder:\n")
cat("- aquaculture_farms_spatial.shp (shapefile with ALL attributes)\n")
cat("- aquaculture_farms_spatial.geojson (GeoJSON with ALL attributes)\n")
cat("- aquaculture_farms_geocoded.csv (full data with coordinates)\n")
cat("- aquaculture_farms_simplified.csv (key columns only)\n")

cat("\nAll files include State, Species, and all other original columns!\n")

# Show failed geocodes (if any)
failed_geocodes <- aqua_data_geocoded %>%
  filter(is.na(final_lat)) %>%
  select(State, Species, `Farm / Operator`, `Address or Location`)

if(nrow(failed_geocodes) > 0) {
  cat("\n\nAddresses that could not be geocoded (", nrow(failed_geocodes), " total):\n")
  print(failed_geocodes)
}

# Success rate
success_rate <- round(successful_geocodes / nrow(aqua_data_geocoded) * 100, 1)
cat("\n\nGeocoding success rate:", success_rate, "%\n")
