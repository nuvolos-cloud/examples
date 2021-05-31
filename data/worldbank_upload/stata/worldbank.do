clear
* ------------------------------------------------------------------------------
*    Packages
* ------------------------------------------------------------------------------

ssc install spmap
ssc install shp2dta
ssc install geo2xy
scc install wbopendata
* ------------------------------------------------------------------------------
*     Data
* ------------------------------------------------------------------------------

cd ~/files/data

cap erase world_shape.dta
cap erase world_shape_coord.dta

* Obtain a world map and turn it into a Stata dataset format
copy https://github.com/nvkelso/natural-earth-vector/raw/master/110m_cultural/ne_110m_admin_0_countries.shp ne_110m_admin_0_countries.shp
shp2dta using "ne_110m_admin_0_countries.shp", database(world_shape) coordinates(world_shape_coord) genid(id) replace

* Correct iso_a2
use  world_shape, clear
drop if ISO_A2=="-99"
drop if ISO_A3=="-99"
save "world_shape_fixed.dta", replace

* Convert to projected (Cartesian) coordinates, so visualization is similar to what you see on Google Maps
use world_shape_coord, clear
replace _Y = -90 if _Y < -90    // fix invalid coordinates
replace _X = 180 if _X > 180    // fix invalid coordinates

geo2xy _Y _X, replace
save "world_shape_coord_fixed.dta", replace

* Obtain world bank data via the wbopendata script 
* The Net FDI inflow as percentage of GDP is under the code BX.KLT.DINV.WD.GD.ZS

wbopendata, indicator(bx.klt.dinv.wd.gd.zs) long clear
rename countrycode ISO_A3
rename bx_klt_dinv_wd_gd_zs FDI_INDICATOR
keep ISO_A3 year FDI_INDICATOR
keep if year == 2014
drop if ISO_A3 == "-99"

* Save our data before merging to the database
* We use the block option on odbc insert, otherwise insertion happens rather slowly
odbc exec("DROP TABLE IF EXISTS FDI_GDP_PCT_STATA;"), connectionstring($conn_str)
odbc insert, table("FDI_GDP_PCT_STATA") connectionstring($conn_str) sqlshow create block
merge 1:1 ISO_A3 using world_shape_fixed

drop if missing(ISO_A3)
drop if missing(FDI_INDICATOR)

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
