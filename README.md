# Australias_Aquaculture
This repository is related to the Manuscript under review with the title:
"Mapping Australia’s aquaculture footprint: Combining Earth Observation and administrative data to map aquaculture at a national scale"

Authors: Marina Christofidis, Simon Metcher, Alexandra White, Caitlin D. Kuempel

Marina Christofidis 1,2
Simon Metcher 1
Alexandra White 1
Caitlin D. Kuempel 1

Affiliations: 1 School of Environment and Science, Australian Rivers Institute, Griffith University, Nathan, QLD, Australia
2 Ministry of Management and Innovation in Public Services (MGI), Brazilian Federal Government, Brasilia, Brazil.


Corresponding author: Marina Christofidis m.christofidis@griffith.edu.au marina.christofidis@gmail.com


The Data analysis and visualization for this project were conducted in R
## Analysis Pipeline

| # | Script | Description | Manuscript section | Output(s) |
|---|--------|--------------|----------------------|-----------|
| 0a | `00_abares_species_states_PublicationV1.Rmd` | Uploads ABARES reports, separates by state, and plots production by aquaculture species | Most plots are in the supplementary materials | `processed_data/top_species_multi_year_long.csv`<br>`processed_data/top_species_multi_year_wide.csv` |
| 0b | `00_shellfish_NSW_measure_leases_PublicationV1.Rmd` | Checks the size of NSW aquaculture farms to build similarly sized polygons for QLD marine farms (used later in `4_QLD_marine_aquaculture_PublicationV1.Rmd`) | Supplements and methods | Figure S5 |
| 1 | `01_Farm_location_open_sources_PublicationV1.Rmd` | Geocodes and plots a list of farm addresses compiled from open web sources (`raw_data/aquaculture_farms_compilation_web.csv`); the resulting KML was used in Google Earth Pro to build polygons for land-based farms in NSW, TAS, and VIC, incorporating custodian-confirmed species and farms geocoded in `2_Insights_Land_based_Leases.Rmd` | Methods section and supplementary materials | `output_data/aquaculture_farms_spatial.shp`<br>`output_data/aquaculture_farms_spatial.kml` |
| 2a | `02_Insights_Land_based_Leases_PublicationV1.Rmd` | Reviews leases across all Australian states, focusing on land-based leases, and adds species columns | — | `output_data/Australian_Aqua_sites/SA_land_sites.shp` (+ equivalent per state) |
| 2b | `02_making_land_mask_australia_PublicationV1.Rmd` | — | — | — |
| 3 | `03_ponds_Australian_Aquaculture_PublicationV1.Rmd` | Identifies and maps aquaculture ponds across Australia using GEE-derived NDWI data (2021–2022); covers land-based sites across seven states | — | — |
| 4 | `04_QLD_marine_aquaculture_PublicationV1.Rmd` | — | — | — |
| 5 | `05_AUS_Marine_Presence_infra_and_Species_PublicationV1.Rmd` | Organises marine species aquaculture data and summarises which species are raised in which state | Results of the infrastructure detection made in GEE | — |
| 6 | `06_Figures_species_by_state_PublicationV1.Rmd` | Builds matrices summarising data availability/attributes by state | Results of piecing together state data and showing custodian availability gaps; Figure 1 | — |
| 7 | `07_atribute_table_setting_land_sites_PublicationV1.Rmd` | — | — | — |
| 8 | `08_maps_active_inactive_PublicationV1.Rmd` | Maps active and inactive sites, land-based and marine | Figure 2 | — |
| 9 | `09_production_distribution_model_refactored_PublicationV1.Rmd` | Builds the production distribution allocation model | All results in the production distribution section; Figure 4 | `figures/Production_Validation_Horizontalv2.png` |
| 10 | `10_Reporting_Aquaculture_production_findings_PublicationV1.Rmd` | Summarises and reports the distribution modelling results | All production distribution summaries; Figure 4 | — |
| 11 | `11_production_distribution_map_PublicationV1.Rmd` | Maps production intensity for 5 species and species locations for most AU aquaculture | Figure 3; Figure 4 | `figures/Production_Distribution_Map_Combined.png`<br>`figures/Supplementary_AllSpecies_Distribution_Map_Combinedv2.png` |
| 12 | `12_results_marine_and_land_PublicationV1.Rmd` | Produces marine and land-based aquaculture results text (built from reading and calculating across multiple Excel spreadsheets) | Beginning of the land-based and marine aquaculture EO detection results sections | — |
| 13 | `13_v2_Build_clean_combined_dataset_and_summaries_PublicationV1.Rmd` | Builds a clean combined dataset for sharing  | — | — |
| 14 | `14_A_Prepare_Public_Infrastructure_dataset.Rmd` |  Filters the dataset from #13 to infrastructure only (leases removed) for public release | — |
| 14B| `14_B_Shiny_app_Public_Australian_Aquaculture_Infrastructure.Rmd` |feeds the infrastructure-only Shiny app | — |
| 15 | `15_Shiny_app_Combined_Australian_Aquaculture_PublicationV1.Rmd`  | Shiny app of Australian aquaculture including leases and infrastructure | Internal use only shiny app with leases and infrastructure | — |
| 16 | `16_Gini_metrics_for_aquaculture_PublicationV1.Rmd` | — |makes figures of supplements | — |
| 17 | `17_manuscript_tables_24apr26_PublicationV1.Rmd` | Builds tables supporting the manuscript Results writing | — | — |
| 18 | `18_statuscheck_SA_and_NSW_Publication.Rmd` | Checks whether state-released status matches infrastructure presence detected in this study | Results section | — |

We downloaded the lease data to start our analysis. If you want to rerun it, you will need to contact the Data Custodians and /or use links to aquaculture lease data in each state of Australia. If you are remaking it for another Country or territory, the leases mean the farms/sites that received a permit to do aquaculture, so you can download datasets or create a polygon around a region (downloading can be better, as it could have species data, other information that is important). 
## Custodians of leased mariculture site datasets

| State | Custodian / Source | Link |
|-------|--------------------|------|
| QLD | Department of Agriculture, Fisheries and Forestry (DAFF) | List of vector points provided directly — no public link -if you need this data please get in touch with DAFF |
| NSW | Department of Primary Industries and Regional Development (DPIRD) | [Fisheries Data Portal](https://webmap.industry.nsw.gov.au/Html5Viewer/index.html?viewer=Fisheries_Data_Portal) · *Production Data Comparison* (Dept. of Primary Industries) |
| VIC | Coastkit | [Coastkit map viewer](https://mapshare.vic.gov.au/coastkit/) · *VFA Commercial Fish Production Information Bulletin 2024* (PDF) |
| TAS | The List | [Geo-metadata record](https://www.thelist.tas.gov.au/app/content/data/geo-meta-data-record?detailRecordUID=10db46db-698d-43e6-a1a7-e1bfff13aedc) |
| SA | data.sa / PIRSA / DPIRD | [Aquaculture leases and licences](https://data.sa.gov.au/data/dataset/aquaculture-leases-and-licences) |
| WA | DPIRD | [Aquaculture sites dataset](https://catalogue.data.wa.gov.au/dataset/aquaculture-sites-dpird-0) |
| NT | Department of Industry, Tourism and Trade (NT Government) | PDF with point locations provided; polygons digitised in-house (only pearls present for mariculture) if you need this data please get in touch with Dep.ITT/NT |


We also used Google Earth Engine(GEE) to find the Aquaculture Infrastructure between steps 2 and 3 of the pipeline. The GEE codes will be shared here with a mention and therefore are in JavaScript and should be used in that environment. 

We thank the multiple state and territory data custodians who shared data directly with us or made it openly accessible online, including the Department of Agriculture, Fisheries and
Forestry (Queensland), the Department of Primary Industries and Regional Development (New South Wales and Western Australia), Coastkit and the Victorian Fisheries Authority
(Victoria), The List (Tasmania), PIRSA and data.sa (South Australia), and the Depart ment of Industry, Tourism and Trade (Northern Territory). Without their invaluable
support, constraining infrastructure detection using verified lease boundaries and reducing misclassification would not have been possible. This study presents version 1 of a national
aquaculture production map for Australia. The Sustainable Seas Research Group welcomes engagement from data custodians, operators, and other stakeholders wishing to contribute
additional or updated data toward future versions of this resource
