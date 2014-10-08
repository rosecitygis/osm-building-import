.SECONDARY:

# Extract, simplify, and reproject shapefiles from compressed archives.
shp/%.shp:
	rm -rf $(basename $@)
	mkdir -p $(basename $@)
	tar --exclude="._*" -xzm -C $(basename $@) -f $<

	for file in `find $(basename $@) -name '*.shp'`; do \
		ogr2ogr -simplify 0.2 -dim 2 -t_srs EPSG:4326 $(basename $@).$${file##*.} $$file; \
		chmod 644 $(basename $@).$${file##*.}; \
	done
	rm -rf $(basename $@)

# Download compressed archives from Oregon Metro.
gz/metro/%.zip:
	mkdir -p $(dir $@)
	curl -L --remote-time 'http://library.oregonmetro.gov/rlisdiscovery/$(notdir $@)' -o $@.download
	mv $@.download $@


make all: shp/buildings.shp shp/addresses.shp shp/precincts.shp

# A simplified version of buildings_raw.shp that only includes properties we'll
# be working with later.  The goal here is to not alter table names or transform
# data, but simply to reduce the number of irrelevant attributes.
#
# See shp/buildings_raw.shp for more details
shp/buildings.shp: shp/buildings_raw.shp
	ogr2ogr $@ $< -sql "select BLDG_ID,BLDG_ADDR,BLDG_NAME,STATE_ID,NUM_STORY \
	,BLDG_USE,BLDG_TYPE from buildings_raw"

# The primary, unmodified building footprint dataset as distributed by Oregon
# Metro.	This dataset contains over 655k building footprints for the Multnomah
# County area which includes Portland, Beaverton, Gresham and many other neighboring
# cities and suburbs.
#
# distributor - Oregon Metro
# details - http://rlisdiscovery.oregonmetro.gov/?action=viewDetail&layerID=2406
# updated- July 24, 2014
# license - ODbL v1.0
shp/buildings_raw.shp: gz/metro/buildings.zip

# The master address file for Multnomah County.	The file includes every address
# in Portland, Beaverton, Gresham and many other neighboring cities and suburbs.
#
# distributor - Oregon Metro
# details - http://rlisdiscovery.oregonmetro.gov/?action=viewDetail&layerID=656
# updated- July 25, 2014
# license - ODbL v1.0
shp/addresses.shp: gz/metro/master_address.zip


# The voter precincts for Multnomah County.	This data breaks Portland and the
# surrounding areas into 783 smaller areas.
#
# distributor - Oregon Metro
# details - http://rlisdiscovery.oregonmetro.gov/?action=viewDetail&layerID=276
# updated- April 25, 2014
# license - ODbL v1.0
shp/precincts.shp: gz/metro/precinct.zip

osm/features.json:
	rm -rf $(basename $@)
	mkdir -p $(basename $@)

	curl --get 'http://overpass-api.de/api/interpreter' \
		--data-urlencode 'data=[out:json];(way["building"](45.2012894970606,-123.19651445735,45.7254175022529,-121.926452653623);node(45.2012894970606,-123.19651445735,45.7254175022529,-121.926452653623);relation(45.2012894970606,-123.19651445735,45.7254175022529,-121.926452653623););out meta;>;' \
		-o $@.download

	mv $@.download $@
	rm -rf $(basename $@)
