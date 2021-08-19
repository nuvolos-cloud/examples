# Uploading WorldBank Data to the Scientific Data Warehouse

## Code Description

This is a code blueprint demonstrating how to work access data from a web API in python and then consume this data into the Scientific Data Warehouse (SDW).

* Extract data from a Web API. In particular, we are using the World Bank's World Development Indicators (WDI).
* Perform basic data transformations and plotting on the results of the Web API queries.
* Insert data into the Nuvolos SDW.

## Requirements

As a first step, make sure you activate tables in your space for the example to work. Once tables are activated, you need to restart your application.

**All versions of the Stata application are supported.**

We rely on certain standard external `ado` libraries available in Boston College Statistical Software Components (SSC).

| External library | Functionality provided | Available in SSC |
| ---------------- | ---------------------- | ---------------- |
| `spmap` | Create map visualizations in Stata | Yes |
| `shp2dta` | Create `dta` file format from regular `shp` file format | Yes |
| `geo2xy` | Geographical coordinate transformations | Yes |
| `wbopendata` | Harvest World Bank Open Data | Yes |

In order to install the above scripts, you can use the usual `ssc install package` syntax. The packages will be retained after you stop your application.

### Obtaining the data

We obtain data from two sources:

* The map data is taken from a public [repository](https://www.naturalearthdata.com/downloads/110m-cultural-vectors/110m-admin-0-countries/).
* The World Bank Data is pulled via the `wbopendata` package.

The particular call to obtain the World bank data is, to obtain the Net FDI Inflow in percentage of GDP per country:

```
wbopendata, indicator(bx.klt.dinv.wd.gd.zs) long clear
```

If you are interested in other series `help wbopendata` contains all series codes that are available to pull.

### Uploading to a database

In order to upload to a database, we do the following two calls:

```
odbc exec("DROP TABLE IF EXISTS FDI_GDP_PCT_STATA;"), connectionstring($conn_str)
odbc insert, table("FDI_GDP_PCT_STATA") connectionstring($conn_str) sqlshow create block
```

The first statement makes sure that the table does not exist before uploading to it. In case you receive an access denied error, it means probably some other user has created the table with the same name. Use the Web UI to delete the existing table or pick another name. 

The second statement creates the `FDI_GDP_PCT_STATA` table and uploads all the variables in the memory to this table. It is very important to use the `block` modifier as this will greatly increase data writing performance to the database.

### Country codes

The format of the data provided by `wbopendata` has changed compared to more aged documentations. We suggest to use the `countrycode` column as ISO A3 format and merge on this with the shape data.

Geographical data is corrected in the beginning of the script, in particular, missing information is always denoted via `-99` values in the shape file. Records with missing ISO A3 codes are dropped, we suggest to issue the `isid` Stata command to confirm that there are no duplicates of the `ISO_A3` field before merging.

Once geographical data is also prepared, we execute the merge as

```
merge 1:1 ISO_A3 using world_shape_fixed
```

where `world_shape_fixed` is the adjusted `dta`-based version of the downloaded, referenced geographical dataset.

### Plotting

The plot is generated via the `spmap` package with the following syntax. The `_merge == 3` filter will make sure that only matched data is used, the `id` field on which the merge is based is contained in `world_shape_fixed` and this is the basis of merging the actual shape coordinates with the descriptive data.

```
spmap FDI_INDICATOR if _merge == 3 using world_shape_coord_fixed , ///
	id(id) ///
        fcolor(RdBu) osize(.1) ocolor(black) ///
        clmethod(custom)  clbreaks(-100 0 2.5 5 10 50 100)  ///
        legend(position(8) ///
               region(lcolor(black)) ///
               label(1 "No data") ///
	       label(2 "Negative") ///
               label(3 "0% to 2.5%") ///
               label(4 "2.5% to 5%") ///
               label(5 "5% to 10%") ///
               label(6 "10% to 50%") /// 
               label(7 "50% to 100%")) ///
        legend(region(color(white))) ///
        plotregion(icolor(bluishgray)) ///
        title("Foreign Direct Investment net inflows (% of GDP)") ///
        subtitle("Year 2014") ///
        note("Source: World Bank Open Data")
```
