CREATE OR REPLACE FUNCTION public.heatmap2(userid integer, _dict TEXT)
RETURNS TABLE(grid_id integer, geom geometry, accessibility_index numeric)
LANGUAGE plpgsql
AS $function$
DECLARE
  del int[];
BEGIN
  del = (SELECT deleted_feature_ids FROM user_data WHERE user_data.userid = heatmap2.userid AND layer_name = 'pois');
Return query

user_pois AS (
	SELECT r.grid_id, poi_gid, EXP(-(cost^2/((_dict::jsonb -> r.amenity ->> 'sensitivity')::integer)))::NUMERIC * (_dict::jsonb -> r.amenity ->> 'weight')::integer AS weighted_sensitivity_cost
	FROM reached_pois_heatmap r
	WHERE r.userid IS NULL OR r.userid = heatmap2.userid AND NOT poi_gid = ANY( del)
),

summed_costs AS (
	SELECT sum(weighted_sensitivity_cost) AS idx, w.grid_id FROM user_pois w GROUP BY w.grid_id
)

SELECT grid_500.grid_id, grid_500.geom, idx AS accessibility_index FROM grid_500 INNER JOIN summed_costs ON grid_500.grid_id = summed_costs.grid_id;

END;
$function$;




--SELECT heatmap2(7616535, '[{"kindergarten":{"sensitivity":150000,"weight":1}},{"primary_school":{"sensitivity":150000,"weight":1}},{"secondary_school":{"sensitivity":150000,"weight":1}},{"library":{"sensitivity":150000,"weight":1}},{"bar":{"sensitivity":150000,"weight":1}},{"biergarten":{"sensitivity":150000,"weight":1}},{"cafe":{"sensitivity":150000,"weight":1}},{"pub":{"sensitivity":150000,"weight":1}},{"fast_food":{"sensitivity":150000,"weight":1}},{"ice_cream":{"sensitivity":150000,"weight":1}},{"restaurant":{"sensitivity":150000,"weight":1}},{"nightclub":{"sensitivity":150000,"weight":1}},{"bicycle_rental":{"sensitivity":150000,"weight":1}},{"car_sharing":{"sensitivity":150000,"weight":1}},{"charging_station":{"sensitivity":150000,"weight":1}},{"bus_stop":{"sensitivity":150000,"weight":1}},{"tram_stop":{"sensitivity":150000,"weight":1}},{"subway_entrance":{"sensitivity":150000,"weight":1}},{"rail_station":{"sensitivity":150000,"weight":1}},{"taxi":{"sensitivity":150000,"weight":1}},{"hairdresser":{"sensitivity":150000,"weight":1}},{"atm":{"sensitivity":150000,"weight":1}},{"bank":{"sensitivity":150000,"weight":1}},{"dentist":{"sensitivity":150000,"weight":1}},{"doctors":{"sensitivity":150000,"weight":1}},{"pharmacy":{"sensitivity":150000,"weight":1}},{"post_box":{"sensitivity":150000,"weight":1}},{"fuel":{"sensitivity":150000,"weight":1}},{"recycling":{"sensitivity":150000,"weight":1}},{"bakery":{"sensitivity":150000,"weight":1}},{"butcher":{"sensitivity":150000,"weight":1}},{"clothes":{"sensitivity":150000,"weight":1}},{"convenience":{"sensitivity":150000,"weight":1}},{"greengrocer":{"sensitivity":150000,"weight":1}},{"kiosk":{"sensitivity":150000,"weight":1}},{"mall":{"sensitivity":150000,"weight":1}},{"shoes":{"sensitivity":150000,"weight":1}},{"supermarket":{"sensitivity":150000,"weight":1}},{"discount_supermarket":{"sensitivity":150000,"weight":1}},{"international_supermarket":{"sensitivity":150000,"weight":1}},{"hypermarket":{"sensitivity":150000,"weight":1}},{"chemist":{"sensitivity":150000,"weight":1}},{"organic":{"sensitivity":150000,"weight":1}},{"marketplace":{"sensitivity":150000,"weight":1}},{"cinema":{"sensitivity":150000,"weight":1}},{"theatre":{"sensitivity":150000,"weight":1}},{"museum":{"sensitivity":150000,"weight":1}},{"hotel":{"sensitivity":150000,"weight":1}},{"hostel":{"sensitivity":150000,"weight":1}},{"guest_house":{"sensitivity":150000,"weight":1}},{"gallery":{"sensitivity":150000,"weight":1}}]')


/*
SELECT jsonb_object_keys(x.jsons::jsonb) AS amenity, ((x.jsons->>jsonb_object_keys(x.jsons::jsonb)::TEXT)::jsonb->>'sensitivity')::NUMERIC AS sensitivity, ((x.jsons->>jsonb_object_keys(x.jsons::jsonb)::TEXT)::jsonb->>'weight')::NUMERIC AS weight
	FROM (
		SELECT value AS jsons FROM json_array_elements('[{"primary_school":{"sensitivity":-0.004,"weight":1}},{"kindergarten":{"sensitivity":-0.003,"weight":1}},{"secondary_school":{"sensitivity":-0.003,"weight":1}},{"library":{"sensitivity":-0.003,"weight":1}}]')
	)
	AS x


*/


