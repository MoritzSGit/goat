DROP FUNCTION IF EXISTS public.saved_co2;
CREATE OR REPLACE FUNCTION public.saved_co2(user_id integer) RETURNS numeric AS $$
DECLARE

    isochrone geometry;
    new_stations numeric[][];
    isochrone_id integer;
    
    population integer;
    --number of trips a human makes per day
    trips_per_inhabitant NUMERIC = 3.1;
    --percentage that cars have in the modal split of people (general trip purpose)
    percentage_cars_in_population_modal_split NUMERIC = 0.5;
    --how many people sit in one car on average
    occupancy_rate_inhabitants NUMERIC = 1.5;
    --average trip length by car
    average_trip_length_population NUMERIC = 20;
    --how many local residents become bike sharing customers if a station is near them
    percentage_inhabitants_bike_sharing_customers NUMERIC = 0.1;
    --how many percent points the car is reduced in modal split of bike sharing customers
    reduction_motorized_private_transport_population NUMERIC = 0.03;
    emissions_population_base_scenario NUMERIC;
    emissions_population_bike_scenario NUMERIC;
   
    employees integer;
    trips_per_employee numeric = 1.9;
    percentage_cars_in_employee_modal_split NUMERIC = 0.53;
    occupancy_rate_employee NUMERIC = 1.1;
    average_trip_length_employee NUMERIC = 17;
    percentage_employees_bike_sharing_customers NUMERIC = 0.1;
    reduction_motorized_private_transport_employee NUMERIC = 0.03;
    emissions_employees_base_scenario NUMERIC;
    emissions_employees_bike_scenario NUMERIC;
    
    --Emmission factor of an average car in g CO2/km
    emission_factor numeric = 134;
   
   
BEGIN
	new_stations = (SELECT array_agg(ARRAY[st_X(geom),ST_Y(geom)]) FROM pois_modified pm WHERE userid = user_id AND amenity = 'bicycle_rental');
	
    isochrone_id = (SELECT random_between(1,10000000));
	PERFORM multi_isochrones_based_on_single(1, isochrone_id, 10, 1, 'walking_wheelchair', 5, 0.00003, 2, 2, new_stations);	
    isochrone = (SELECT geom FROM multi_isochrones mi WHERE objectid =isochrone_id);

	population = (
		SELECT sum(p.population)
		FROM population p
		WHERE st_within(p.geom, isochrone)
	);

	employees = (
		SELECT sum(e.employees_adjusted)
		FROM employees e
		WHERE st_within(e.geom, isochrone)
	);
     
    emissions_population_base_scenario =
    	population *
    	trips_per_inhabitant *
    	percentage_cars_in_population_modal_split *
    	(1/occupancy_rate_inhabitants) *
    	average_trip_length_population *
    	365 *
        emission_factor *
        0.000001;
       
    emissions_population_bike_scenario =
        population *
    	trips_per_inhabitant *
    	(percentage_cars_in_population_modal_split - reduction_motorized_private_transport_population) *
    	(1/occupancy_rate_inhabitants) *
    	average_trip_length_population *
    	365 *
        emission_factor *
        0.000001;
    
	emissions_employees_base_scenario =
    	employees *
    	trips_per_employee *
    	percentage_cars_in_employee_modal_split *
    	(1/occupancy_rate_employee) *
    	average_trip_length_employee *
    	249 *
        emission_factor *
        0.000001;
       
    emissions_employees_bike_scenario =
        employees *
    	trips_per_employee *
    	(percentage_cars_in_employee_modal_split - reduction_motorized_private_transport_employee) *
    	(1/occupancy_rate_employee) *
    	average_trip_length_employee *
    	249 *
        emission_factor *
        0.000001;      
       
    RETURN
    	(emissions_population_base_scenario + emissions_employees_base_scenario) -
    	(emissions_population_bike_scenario + emissions_employees_bike_scenario);
END;
$$ LANGUAGE plpgsql;

--SELECT saved_co2(7719169);
