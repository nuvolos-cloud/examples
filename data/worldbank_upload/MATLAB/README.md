# Uploading WorldBank Data to the Scientific Data Warehouse

## Code description

This is a code blueprint demonstrating how to work access data from a web API in python and then consume this data into the Scientific Data Warehouse (SDW).

* Extract data from a Web API. In particular, we are using the World Bank's World Development Indicators (WDI).
* Perform basic data transformations and plotting on the results of the Web API queries.
* Insert data into the Nuvolos SDW.
* Perform a simple query on data stored in the SDW and use the results in the example.

### Requirements

As a first step, make sure you [activate tables](https://docs.nuvolos.cloud/data/the-table-view#activating-tables) in your space for the example to work. Once tables are activated, you need to restart your application.

| Image | Compatible |
| ----- | ---------- |
| Matllab R2021a (Mathworks account) | Yes |
| Matlab R2020a (Mathworks account) | Yes |

### Running the example

Please open the `world_bank.mlx` MATLAB® live script and click `Run` to start the example.
The script will install all required add-ons from the `addon` folder.

The example performs the following steps:

1. It reads foreign direct investment data from the World Bank Data API,
2. It stages the downloaded data as the table `"FDI_GDP_PCT_MATLAB`,
3. It stages descriptive data on countries as the table `COUNTRIES`
4. It runs a query to retrieve country names, ISO3 codes and foreign investment data and plots it on a world map using the `borders` add-on.