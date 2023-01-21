---
### Case Study 1: How Does a Bike-Share Navigate Speedy Success?
##### Nathaniel Nete-Sie Williams Jr.
##### 12/19/2022
---
## Contents

1. [Introduction](#1.-Introduction)

    1.1 [Questions to Answer (Business Task)](#1.1-)

    1.2 [Hypothesis](#1.2-Hypothesis)
2. [Process](#2.-Process)


3. [Analysis](#3.-Analysis)

    3.1 [Metrics](#3.1-Metrics)
4. [Conclusion](#4.-Conclusion)
### 1. Introduction
 The purpose of this case study is to try and figure out how to maximize the number of annual memberships for the fictional company "Cyclistic" by trying to understand how casual riders and annual members use Cyclistic ride share bikes differently. I'll be using data to design marketing strategies aimed at converting casual riders into annual members.
##### 1.1 Questions to Answer (Business Task)
1) How do casual members and annual members use Cyclist bikes differently?
2) Why would causal riders buy Cyclistic annual memberships?
3) How can Cyclistic use digital media to influence casual riders to become members? (email,social media, etc)

_Without looking at the datasets, I decided to do some comparative analysis. I looked into the bike share industry to see if any companies have had similar problems, and what they've found success in doing.  I'll also be making assummptions that Cyclistic's docking stations are positioned strategically in Chicago, to fulfill a demand of both the annual and casual member. (Providing a low cost transportation alternative option to and from central business/commerical hubs and  nearby residential locations)._ 

_With this in mind here is my intial..._ 

##### 1.2 Hypothesis
1) Casual members use the bikes fewer times a year than annual members and most likely pay more per ride on average.
2) Casual members would buy annual memberships if they realized how cost effective an annual membership was.
3) Using the data we could send out direct email or social media campaigns that highlight the savings of an annual membership 
```
*Limitations: Data-privacy issues prohibit me from using riders’ personally identiﬁable information. This 
means that I won’t be able to connect past purchases to credit card numbers to determine if casual riders live in the 
Cyclistic service area or if they have purchased multiple single passes.* 
```

I downloaded "Cyclistic's" past 12 months of trip data from this website :
[Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html) (primary data source)

_(202210-divvy-tripdata.zip, 202209-divvy-tripdata.zip, ... 202110-divvy-tripdata.zip)_


#### [Download Data](https://divvy-tripdata.s3.amazonaws.com/index.html)
### 2. Process
Since the business task was to compare the differences between causal and annual members, I of course knew I would eventually be sorting and filtering the data based on if the rider was a casual or annual member. Finding my actionable metrics is the fun part that comes from exploring the dataset.

Initially, there were many null values in the start and end location columns so I decided not to focus on metrics based on those fields, early on . The consistent fields were ride_id, the type of bicycle used for each trip, Start and end times of each trip ,start and end latitude/longitude coordinates, and what type of member the rider was ( casual or annual).

So in Excel I decided to start off finding each trips 'ride_length' by subtracting the end ride time by the start ride time.

Next, I decided to single out the day of the week from each ride id's start time in order to get a feel on how rides were going in a Work Week/End format. Using the WEEKDAY function I was able to do that,starting my week on Sunday. I named the column 'day_of_week'
```
=WEEKDAY(C2,1)
```
Next I singled out the time of day in hours(AM/PM) because I was hoping to find out if rush hour effects casual riders differently than annual members. Singling out the time of day in its own column will make it easier to group data this way down the line. I named this column 'hour_of_day'.

```
=TIME(HOUR(D2),0,0)
```

I quickly put my cleaned data into a pivot table format to see if these newly created fields would be able to do the job and give me some preliminary insights on a monthly level. 
After doing this for each of the 12 datasets I should be ready to export these cleaned tables into a Google BigQuery. There I will combine the 12 tables  into a single year partitioned table ...then spatial join it to a shapefile of Chicagos Community Areas ...so I can see how certain data points in certain neighborhoods trend over time.

I downloaded Chicagos community area data from this website:
[Boundaries Community Areas](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-current-/cauq-8yn6)




_Testing for null values in fields I will be using for analysis_


```

SELECT ride_id,rideable_type,hour_of_day,started_at,ended_at ,ride_length,day_of_week,member_casual,start_latitude,start_longitude,end_latitude,end_longitude

FROM `wise-arena-359101.Cyclistic_data.202111` 

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
```
Then I combined all 12 tables

```

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

```
I joined the Chicago's Community boundaries map with my combined 12 month table


```
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
```
### 3. Analysis
Initial observation...I noticed that only casual members used a "docked_bike" besides the available electric and classic bike that annual members were using. It seemed only casual riders were using these bikes, in addition to the other 2. Strangely enough some of the trip duration lengths lasted multiple days and had null values for their end of ride gps location (lat/long).

After further investigation into these, long duration and no end gps location rides... I found multiple articles of bike share theft in the Chicago area where this dataset represents. So for now we will filter out data that seems to look like a stolen bike  (has no end of ride gps and the trip duration is over 24 hours). I want to focus on converting the casual riders that aren't stealing bikes lol.

##### 3.1 Metrics
After looking and living with the data I decided to focus on the metrics of: 

**_1. Average trip duration and how it trends monthly when comparing casual and annual member riders._** 

**_2. Which days of the week and time of day show the most rides for each group (casual/member)._**

**_3. Finally, the Top 3 most used bike station locations for each group._** 

I always find that focusing on the trend or rate of data is more important than static numbers (unless its a big company goal to reach a certain static number). Focusing on time segments that are appropriate to the scale of the problem, keeps decison makers looking to improve or take action. Vanity metrics vs Actionable metrics.

  
First, let's see the average trip duration for casual and member riders and see how they trend.




```
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

```

![Picture title](https://github.com/netesie/bikerideshare/blob/main/code%20and%20data/Notebook%20Folder/image-20221218-181932.png)
It seems that casual riders consistently take longer rides and it should be assumed they are spending more on average per trip as well. Besides that, casual and annual member riders trend pretty closely with an expected spike in ride duration in the summer months. The only difference I notice is that casual ride duration trends downwards agressively starting from December , which I assume is due to the cold weather.

Let's explore further to see why this might be. 
Now, let's see which days of the week are the busiest between both groups (casual/members).





```
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

```
![Picture title](https://github.com/netesie/bikerideshare/blob/main/code%20and%20data/Notebook%20Folder/image-20221215-104903.png)
From this bar chart, it seems pretty clear that casual members use the bikes for more leisure related activities on the weekends which may explain the longer ride durations and the shorter durations during winter. Annual members seem to be riding more throughout the work week (most likely for their work commute).
Let's see if we can substantiate this by looking at the time of day annual members usually ride.





```
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
```
![Picture title](https://github.com/netesie/bikerideshare/blob/main/code%20and%20data/Notebook%20Folder/image-20221216-124335.png)
As expected, annual member ride count spikes at 9 am and 5 pm. Interesting to see that casual riders also spikes around 5 as well. Casual riders don't have the 9 am spike like the annual members, but this could be an opportunity area to advertise these bikes as a viable primary mode of transportation to and from work.
Let's first make sure these casual riders are starting their rides near major transportation hubs in order to take advantage of the bikes as a work commute option. (I just used the data from our '202110 to 202210 GEOM' table in order to create this visual.)
![Picture title](https://github.com/netesie/bikerideshare/blob/main/code%20and%20data/Notebook%20Folder/image-20221216-001350.png)
Now we can clearly see with this heatmap that casual and annual members start their rides in almost identical neighborhoods in Chicago. We can now build a small customer profile of the casual riders based off when and where they like to ride. 

First off, I feel it’s more than likely a majority of our casual riders live in or near the neighborhoods they are starting these bike trips from.

So let’s take a look at these neighborhoods - The Near North Side is a bustling neighborhood, right next to Chicago’s downtown, that’s known for its residents who are always on the move. With its many cultural, commercial, and nightlife offerings, we can begin to get a sense of the hobbies of our casual riders. Also, with a higher share of adults who are in the age range of 25-35, and a median household income of around $130k, it’s safe to say the riders in this neighborhood are more than likely young professionals.

The neighborhood of Lincoln Park follows suite, being a nature lover’s dream - with its namesake park “Lincoln Park” , it’s manicured gardens and tons of lakefront green spaces we can see that the casual riders appreciate riding around beautiful natural spaces and enjoying leisurely outdoor activities.

The Loop with its lakeviews, nightlife, and proximity to big business  - falls right in line with the rest of the neighborhoods 


Now lets recap everything we’ve learned about our casual and annual riders.

 


### 4. Conclusion 

[Final Report](https://docs.google.com/presentation/d/12pxwNMqS1KeqkIGuxM3CkgyhWa8lJ_rQDk8yJDP5TsM/edit?usp=sharing)


<a style='text-decoration:none;line-height:16px;display:flex;color:#5B5B62;padding:10px;justify-content:end;' href='https://deepnote.com?utm_source=created-in-deepnote-cell&projectId=97425f17-7e24-4083-babd-07c994993e7d' target="_blank">
<img alt='Created in deepnote.com' style='display:inline;max-height:16px;margin:0px;margin-right:7.5px;' src='data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyB3aWR0aD0iODBweCIgaGVpZ2h0PSI4MHB4IiB2aWV3Qm94PSIwIDAgODAgODAiIHZlcnNpb249IjEuMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB4bWxuczp4bGluaz0iaHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayI+CiAgICA8IS0tIEdlbmVyYXRvcjogU2tldGNoIDU0LjEgKDc2NDkwKSAtIGh0dHBzOi8vc2tldGNoYXBwLmNvbSAtLT4KICAgIDx0aXRsZT5Hcm91cCAzPC90aXRsZT4KICAgIDxkZXNjPkNyZWF0ZWQgd2l0aCBTa2V0Y2guPC9kZXNjPgogICAgPGcgaWQ9IkxhbmRpbmciIHN0cm9rZT0ibm9uZSIgc3Ryb2tlLXdpZHRoPSIxIiBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPgogICAgICAgIDxnIGlkPSJBcnRib2FyZCIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTEyMzUuMDAwMDAwLCAtNzkuMDAwMDAwKSI+CiAgICAgICAgICAgIDxnIGlkPSJHcm91cC0zIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxMjM1LjAwMDAwMCwgNzkuMDAwMDAwKSI+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBpZD0iUGF0aC0yMCIgZmlsbD0iIzAyNjVCNCIgcG9pbnRzPSIyLjM3NjIzNzYyIDgwIDM4LjA0NzY2NjcgODAgNTcuODIxNzgyMiA3My44MDU3NTkyIDU3LjgyMTc4MjIgMzIuNzU5MjczOSAzOS4xNDAyMjc4IDMxLjY4MzE2ODMiPjwvcG9seWdvbj4KICAgICAgICAgICAgICAgIDxwYXRoIGQ9Ik0zNS4wMDc3MTgsODAgQzQyLjkwNjIwMDcsNzYuNDU0OTM1OCA0Ny41NjQ5MTY3LDcxLjU0MjI2NzEgNDguOTgzODY2LDY1LjI2MTk5MzkgQzUxLjExMjI4OTksNTUuODQxNTg0MiA0MS42NzcxNzk1LDQ5LjIxMjIyODQgMjUuNjIzOTg0Niw0OS4yMTIyMjg0IEMyNS40ODQ5Mjg5LDQ5LjEyNjg0NDggMjkuODI2MTI5Niw0My4yODM4MjQ4IDM4LjY0NzU4NjksMzEuNjgzMTY4MyBMNzIuODcxMjg3MSwzMi41NTQ0MjUgTDY1LjI4MDk3Myw2Ny42NzYzNDIxIEw1MS4xMTIyODk5LDc3LjM3NjE0NCBMMzUuMDA3NzE4LDgwIFoiIGlkPSJQYXRoLTIyIiBmaWxsPSIjMDAyODY4Ij48L3BhdGg+CiAgICAgICAgICAgICAgICA8cGF0aCBkPSJNMCwzNy43MzA0NDA1IEwyNy4xMTQ1MzcsMC4yNTcxMTE0MzYgQzYyLjM3MTUxMjMsLTEuOTkwNzE3MDEgODAsMTAuNTAwMzkyNyA4MCwzNy43MzA0NDA1IEM4MCw2NC45NjA0ODgyIDY0Ljc3NjUwMzgsNzkuMDUwMzQxNCAzNC4zMjk1MTEzLDgwIEM0Ny4wNTUzNDg5LDc3LjU2NzA4MDggNTMuNDE4MjY3Nyw3MC4zMTM2MTAzIDUzLjQxODI2NzcsNTguMjM5NTg4NSBDNTMuNDE4MjY3Nyw0MC4xMjg1NTU3IDM2LjMwMzk1NDQsMzcuNzMwNDQwNSAyNS4yMjc0MTcsMzcuNzMwNDQwNSBDMTcuODQzMDU4NiwzNy43MzA0NDA1IDkuNDMzOTE5NjYsMzcuNzMwNDQwNSAwLDM3LjczMDQ0MDUgWiIgaWQ9IlBhdGgtMTkiIGZpbGw9IiMzNzkzRUYiPjwvcGF0aD4KICAgICAgICAgICAgPC9nPgogICAgICAgIDwvZz4KICAgIDwvZz4KPC9zdmc+' > </img>
Created in <span style='font-weight:600;margin-left:4px;'>Deepnote</span></a>
