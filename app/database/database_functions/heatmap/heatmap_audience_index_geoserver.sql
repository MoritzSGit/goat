CREATE OR REPLACE FUNCTION public.heatmap_audience_index_geoserver(userid_input integer, modus_input integer)
RETURNS SETOF type_audience_heatmap
LANGUAGE plpgsql
AS $function$
BEGIN 
	IF modus_input = 1 THEN 
		RETURN query

			SELECT grid_id, audience_index, 0::NUMERIC, audience_index::NUMERIC, ((CASE WHEN audience_index IS NOT NULL THEN ntile(6) OVER
		(order by audience_index) ELSE 1 END)-1)::SMALLINT AS percentile_audience , geom
			FROM heatmap_static_audience(150000);

	
	ELSEIF modus_input = 2 THEN  
		RETURN query
		SELECT grid_id, original_audience_index, delta_audience, audience_index, ((CASE WHEN audience_index IS NOT NULL THEN ntile(6) OVER
		(order by audience_index) ELSE 1 END)-1)::SMALLINT AS percentile_audience, geom
		FROM heatmap_dynamic_audience(userid_input, 150000);

	ELSE 
		RAISE NOTICE 'Please insert a valid modus.';
	END IF; 
END;
$function$
;

--DROP TABLE geoserver_audience_dynamic;
--CREATE TABLE geoserver_audience_dynamic AS
--SELECT * FROM heatmap_audience_index_geoserver(9775157, 1)
