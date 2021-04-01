# Please note that in order to install the sf package, your system needs the libudunits2-dev library to be installed.
if (!require("tmap", quietly = TRUE)) install.packages("tmap")
if (!require("sf", quietly = TRUE)) install.packages("sf")
if (!require("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!require("spData", quietly = TRUE)) install.packages("spData")
if (!require("WDI", quietly = TRUE)) install.packages("WDI") 
if (!require("magrittr", quietly = TRUE)) install.packages("magrittr");library(magrittr)
if (!require("gifski", quietly = TRUE)) install.packages("gifski")


FDI_data <- WDI::WDI(country="all", indicator = "BX.KLT.DINV.WD.GD.ZS", start = 2000, end = 2019, extra = TRUE)
data("World", package=c("tmap"))
merged_data <- merge(World[,c('iso_a3', 'geometry')], 
                                FDI_data, 
                                by.x = "iso_a3",
                                by.y = "iso3c")
merged_data <- merged_data %>% 
  dplyr::mutate(FDI = pmin(pmax(BX.KLT.DINV.WD.GD.ZS, 
                         quantile(BX.KLT.DINV.WD.GD.ZS, .05, na.rm=T)), 
                          quantile(BX.KLT.DINV.WD.GD.ZS, .95, na.rm=T)))
tmap::tmap_mode("view")
FDI_plot <- tmap::tm_shape(merged_data) + 
  tmap::tm_polygons(c("FDI"), style = "cont", title="FDI Net Inflow (GDP %)") +
  tmap::tm_facets(along = "year", free.coords = FALSE)


tmap::tmap_animation(FDI_plot, filename=paste0(getwd(), "/FDI_plot.gif"), delay = 200)

con <- nuvolos::get_connection()
dbWriteTable(con, "FDI_GDP_PCT_R", FDI_data %>% dplyr::select(iso3c, year, country, BX.KLT.DINV.WD.GD.ZS), overwrite=TRUE)
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT_R.\"BX.KLT.DINV.WD.GD.ZS\" IS 'Foreign Direct Investment as Pct of GDP'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT_R.\"year\" IS 'Time Period'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT_R.\"iso3c\" IS '3-Letter ISO Country Code'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT_R.\"country\" IS 'Natural English country name'")
dbExecute(con, "COMMENT ON TABLE FDI_GDP_PCT_R IS 'Foreign Direct Investment, Net Inflows (% of GDP)'")
