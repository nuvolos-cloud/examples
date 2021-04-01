# Uploading WorldBank Data to the Nuvolos Scientific Data Warehouse

## Code description

This is a code blueprint demonstrating how to work access data from a web API in python and then consume this data into the Nuvolos Scientific Data Warehouse (SDW).

* Extract data from a Web API. In particular, we are using the World Bank's World Development Indicators (WDI).
* Perform basic data transformations and plotting on the results of the Web API queries.
* Insert data into the Nuvolos SDW.

### Requirements

Applications in Nuvolos can be extended by [installing software packages](https://docs.nuvolos.cloud/getting-started/work-with-applications/install-a-software-package). Application in Nuvolos come equipped with `conda` as the package manager. In order for this particular example to work, one needs to install via `conda` the following packages (sub-dependencies will be installed):

* `wbgapi` - World Bank Data API query package
* `geopandas` - Pandas\-compliant library for working with geographical data
* `descartes` - Plotting support for drawing maps with `geopandas`
* `pycountry` - Mapping and correcting data issues in maps
* `ffmpeg` - GIF writer engine to be used in conjunction with `imagemagick`.

The first cell in the notebook installs these packages via a terminal call.

### Pulling data

Pulling the data from the World Bank database can be done by executing a call such as:

```
FDI_GDP_PCT_data = wb.data.DataFrame('BX.KLT.DINV.WD.GD.ZS', time=range(2000, 2019,), labels=True)
```

In this particular example, we are pulling the Net FDI Inflow in percentage of GDP per country for the 2000 to 2019 period. In order to get information on the data, one needs only to call `FDI_GDP_PCT_info = wb.series.metadata.get('BX.KLT.DINV.WD.GD.ZS')`, which collects the metadata information from the World Bank on the `BX.KLT.DINV.WD.GD.ZS` series.

### Plotting the data

As the data has been pulled for all countries, we merge with a world map provided in the geopandas package.

Once the map is available, we merge the map with the data that we want to plot, by executing for example:

```
data_mapped = pd.merge(FDI_GDP_PCT_data, worldmap, left_on = 'economy', right_on = 'iso_a3')
```

Once this step is performed, plotting can be achieved via the GeoPandas `plot` method which is a smart wrapper around MatPlotLib's plotting infrastructure.

### Storing the data in the SDW

The `wbgapi`package downloads data in a wide format, each series corresponding to a particular year is stored in a separate column. Using the melt method of the DataFrame class, we transform the table to a longer format:

```
FDI_GDP_PCT_data_melt = FDI_GDP_PCT_data.melt(id_vars = ['economy', 'Country'])
FDI_GDP_PCT_data_melt['variable'] = FDI_GDP_PCT_data_melt['variable'].apply(lambda x: x.replace('YR', '')).apply(lambda x: np.int_(x))
```

Finally, after transforming the data, we load the table into the database with the following call:

```
nuvolos.to_sql(df = FDI_GDP_PCT_data_melt, name = "FDI_GDP_PCT", con = con, if_exists='replace', index=False)
```

### Adding column or table comments

Adding table and column comments is a nice convenience feature to provide end-users with a light and easy-to-access quick documentation. Please refer to the [service documentation](https://docs.snowflake.com/en/sql-reference/sql/comment.html) on the details of provide object comments.

In the context of python, sending SQL statements via a `pyodbc` cursor object's `execute` method will perform the necessary action. Please note the [escaping and quoting](https://docs.snowflake.com/en/sql-reference/identifiers-syntax.html) of the column names in the statements.

```
cur = con.cursor()
cur.execute("COMMENT ON COLUMN FDI_GDP_PCT.value IS 'Foreign Direct Investment as Pct of GDP'")
cur.execute("COMMENT ON COLUMN FDI_GDP_PCT.variable IS 'Time Period'")
cur.execute("COMMENT ON COLUMN FDI_GDP_PCT.economy IS 'ISO A3 Country Code'")
cur.commit()
```
