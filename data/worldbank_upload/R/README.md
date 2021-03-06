# Uploading WorldBank Data to the Scientific Data Warehouse

## Code description

This is a code blueprint demonstrating how to work access data from a web API in R and then consume this data into the Scientific Data Warehouse (SDW).

* Extract data from a Web API. In particular, we are using the World Bank's World Development Indicators (WDI).
* Perform basic data transformations and plotting on the results of the Web API queries.
* Insert data into the Nuvolos SDW.

### Requirements

As a first step, make sure you [activate tables](https://docs.nuvolos.cloud/data/the-table-view#activating-tables) in your space for the example to work. Once tables are activated, you need to restart your application.

Applications in Nuvolos can be extended by [installing software packages](https://docs.nuvolos.cloud/getting-started/work-with-applications/install-a-software-package). In this example we are relying on R's package management system to first install packages. Any installed packages will be retained after the application is restarted. Applications can be distributed to spare the cost of building and installing packages again and again. Distribution's other main benefit is the fact that an application can be proliferated in the exact state it was created in, changing repository layout has no effect on an application that is proliferated via distribution.

The following images are compatible with this code example:

| Image      | Compatible |
| ----------- | ----------- |
| RStudio + R 4.0.3 | Yes |
| RStudio + R 4.0.3 + Machine Learning | Yes |

In off-Nuvolos applications, you will need to make sure that you either use pre-built binary versions of the above packages or the system dependencies are satisfied. 

The libraries we are relying on:
* `WDI` - World Bank Data API query package
* `tmap` - topographical map plotting package built on the Grammar of Graphics (similar to `ggplot2`), also provides the `World` dataset used to obtain geometry objects for mapping. The example requires `tmap>=3.3`.
* `sf` - Simple Features for R: encoding spatial vector data
* `spData` - spatial datasets
* `nuvolos` - Interacting with the Nuvolos SDW, implicitly attaches `DBI`.
* `magrittr`, `dplyr` - Simplify data transformations
* `gifski` - In order for `tmap::animation` to be able to generate GIFs

### Pulling data

Pulling data can be performed with the WDI package, using the WDI method. The following code pulls??the??`BX.KLT.DINV.WD.GD.ZS` series with additional metadata from the year 2000 to 2019.

```
FDI_data <- WDI::WDI(country="all", indicator = "BX.KLT.DINV.WD.GD.ZS", start = 2000, end = 2019, extra = TRUE)
```

### Plotting the data

To smoothen the color scaling of the chart generated by `tmap`, we winsorize the variable first. Setting the `tmap_mode` to `view` enables interactive and animated maps. Finally we generate the plot and save it to a GIF animated plot.

```
merged_data <- merged_data %>% 
  dplyr::mutate(FDI = pmin(pmax(BX.KLT.DINV.WD.GD.ZS, 
                         quantile(BX.KLT.DINV.WD.GD.ZS, .05, na.rm=T)), 
                          quantile(BX.KLT.DINV.WD.GD.ZS, .95, na.rm=T)))
tmap::tmap_mode("view")
FDI_plot <- tmap::tm_shape(merged_data) + 
  tmap::tm_polygons(c("FDI"), style = "cont", title="FDI Net Inflow (GDP %)") +
  tmap::tm_facets(along = "year", free.coords = FALSE)

tmap::tmap_animation(FDI_plot, filename=paste0(getwd(), "/FDI_plot.gif"), delay = 200)
```

### Storing the data in the SDW

In order to load the data to the SDW, in an in-Nuvolos application, you only need to have the following code.

```
con <- nuvolos::get_connection()
dbWriteTable(con, "FDI_GDP_PCT", FDI_data %>% dplyr::select(iso3c, year, country, BX.KLT.DINV.WD.GD.ZS), overwrite=TRUE)
```

This bit needs to be slightly modified if you are working off-Nuvolos (you need to make sure you have the correct credentials), please consult our [documentation](https://docs.nuvolos.cloud/data/access-data-from-applications) on how to do this.

> In case you get an access denied error for the dbWriteTable command, most probably some other user created a table with the same name. You can either change the table name (second parameter in the above call) or use the Web UI to delete the existing table.

### Adding column or table comments

Adding table and column comments is a nice convenience feature to provide end-users with a light and easy-to-access quick documentation. Please refer to the [service documentation](https://docs.snowflake.com/en/sql-reference/sql/comment.html) on the details of provide object comments.

In the context of R, sending SQL statements via `DBI::dbExecute` will perform the necessary action. Please note the [escaping and quoting](https://docs.snowflake.com/en/sql-reference/identifiers-syntax.html) of the column names in the statements.

```
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT.\"BX.KLT.DINV.WD.GD.ZS\" IS 'Foreign Direct Investment as Pct of GDP'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT.\"year\" IS 'Time Period'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT.\"iso3c\" IS '3-Letter ISO Country Code'")
dbExecute(con, "COMMENT ON COLUMN FDI_GDP_PCT.\"country\" IS 'Natural English country name'")
dbExecute(con, "COMMENT ON TABLE FDI_GDP_PCT IS 'Foreign Direct Investment, Net Inflows (% of GDP)'")
```
