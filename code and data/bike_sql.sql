/*Make sure to format your excel csv date columns in this format yyyy-m-d h:mm;@ */
/*I Imported 12 CSV tables of data into BigQuery from Excel (each labeled as the year and month it represented i.e '202209') then ran this code 12 different times to clean each one of them just in case any null values snuck their way into my data* /
/*CSV Output:202111 cleaned.csv*/

SELECT ride_id,rideable_type,hour_of_day,started_at,ended_at ,ride_length,day_of_week,member_casual,start_latitude,start_longitude,end_latitude,end_longitude
FROM 
	`wise-arena-359101.Cyclistic_data.202110` 
WHERE
ride_id IS NOT NULL AND 
rideable_type IS NOT NULL AND 
hour_of_day IS NOT NULL AND
ended_at IS NOT NULL AND 
ride_length IS NOT NULL AND 
day_of_week IS NOT NULL AND 
member_casual IS NOT NULL AND 
start_latitude IS NOT NULL AND 
start_longitude IS NOT NULL AND 
end_latitude IS NOT NULL AND 
end_longitude IS NOT NULL

/*Then I combined each of the 12 months together using a UNION DISTINCT function. I did this because each row was unique and every matching column between tables had identical data types. This type of UNION is slower to query but also doesnt allow duplicates * /
/*CSV Output:202110 to 202210.csv*/

SELECT *
FROM `wise-arena-359101.Cyclistic_data.202110 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202111 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202112 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202201 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202202 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202203 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202204 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202205 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202206 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202207 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202208 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202209 cleaned`
UNION DISTINCT
SELECT *
FROM `wise-arena-359101.Cyclistic_data.202210 cleaned`

/*I then researched online to see if I could find a way to somehow map the neighborhoods of Chicago via longitude and latitiude, so I could group my existing long/lat data into each of those neighborhood long/lat buckets. I found out this was called a Shapefile (spatial data) and I found out Chicago hosts this data on their city website as a CSV table. I later learned that I had to turn that simple CSV table (non spatial) into a spatial table by converting the CSV table column "the_geom" into a spatial column.*/
/*CSV Output:CommunityGeo.csv */

SELECT 
    ST_GEOGFROMTEXT(the_geom) AS NEW_GEO, Community,AREA_NUM_1,shape_area,shape_len
FROM `wise-arena-359101.Cyclistic_data.Chicago Community Boundaries` 


/*Then I did a special kind of join called a spatial join with my new spatial Chicagos neighborhood table and my other table comprised of the 12 months of bike data. I did this in order to group wherever the rides started at so I can see which Chicago neighborhoods these rides were starting in * /
/*CSV Output:202110 to 202210 GEOM.csv*/

SELECT 
   t.ride_id,
   t.rideable_type,
   t.hour_of_day,
   t.started_at,
   t.ended_at ,
   t.ride_length,
   t.day_of_week,
   t.member_casual,
   t.start_latitude,
   t.start_longitude,
   t.end_latitude,
   t.end_longitude,
    st_geogpoint(start_longitude, start_latitude) as start_point,
    st_geogpoint(end_longitude, end_latitude) as end_point,
    st_makeline(st_geogpoint(start_longitude, start_latitude),st_geogpoint(end_longitude, end_latitude)) as bike_route,
    nh.NEW_GEO,
    nh.Community,
    nh.AREA_NUM_1,
    nh.shape_area,
    nh.shape_len
FROM `wise-arena-359101.Cyclistic_data.202110 to 202210`AS t
JOIN  `wise-arena-359101.Cyclistic_data.CommunityGeo` AS nh
ON ST_WITHIN(st_geogpoint(t.start_longitude, t.start_latitude), nh.NEW_GEO)
where start_longitude IS NOT NULL and start_latitude IS NOT NULL and end_longitude IS NOT NULL and end_latitude IS NOT NULL

/*In order to create a visualization in Looker Studio I ran this code in order to see the average trip duration for casual and annual members to see how they trend monthly* /
/*CSV Output:*/

SELECT 
member_casual,
started_at,
CAST(AVG(TIME_DIFF(ride_length, '00:00:00', SECOND)) AS 
  INT64)
   AS avg_ride_length_seconds,
FROM 
  `wise-arena-359101.Cyclistic_data.202110 to 202210 GEOM` 
GROUP BY
member_casual, 
started_at

/*Now, let's see which days of the week are the busiest between both groups (casual/members). We'll do this in Tableau because they have more control on double bar charts and the way you can express value through color hue. Not only that but it's easy to label data on top of the actual bars in the chart* /
/*CSV Output:*/

SELECT 
day_of_week,
member_casual,
COUNT(ride_id) AS rides,
FROM 
  `wise-arena-359101.Cyclistic_data.202110 to 202210 GEOM` 
GROUP BY
day_of_week,
member_casual
ORDER BY 
member_casual,
day_of_week ASC

/*Now, let's look at the time of day annual and casual members usually ride * /
/*CSV Output:*/

SELECT 
member_casual,
PARSE_TIME("%I:%M %p",hour_of_day) as time_of_day,
COUNT(ride_id) AS rides,
FROM 
  `wise-arena-359101.Cyclistic_data.202110 to 202210 GEOM` 
GROUP BY
member_casual, 
time_of_day
ORDER BY 
member_casual,
time_of_day
