WITH times AS (	select * from generate_series((current_timestamp - interval '1 MONTH')::DATE, current_timestamp,'10m') as minute ),
    zhosts AS (  
        select DISTINCT functions.itemid, functions.triggerid, hosts.host as host, hstgrp.name as group from functions 
        left JOIN items ON items.itemid = functions.itemid  
        left JOIN hosts ON items.hostid = hosts.hostid 
        left join hosts_groups ON hosts.hostid = hosts_groups.hostid  
        join hstgrp ON hosts_groups.groupid = hstgrp.groupid AND hstgrp.name IN ('stand-test','stand-test-jvm') 
    ), 
    tags AS (select * from event_tag where tag = 'StandWork'),
	problems AS (
		select pb.eventid,TO_TIMESTAMP(pb.clock) as start_time, TO_TIMESTAMP(e_recovery.r_clock) as stop_time, pb.name, tags.tag, tags.value, zhosts.host, zhosts.group  from events as pb 
    join tags ON pb.eventid = tags.eventid 
    join zhosts on pb.objectid = zhosts.triggerid --AND ( zhosts.host NOT IN ('stand-test-jetty') )
    left join ( 
            select event_recovery.eventid as eventid, event_recovery.r_eventid, events.clock as r_clock from event_recovery 
            join events on event_recovery.r_eventid = events.eventid 
        ) as e_recovery ON pb.eventid = e_recovery.eventid 
    where pb.value = 1
	),
	tcount AS ( select count(*) as tcount from times where times.minute > date_trunc('MONTH', now()) ),
	vcount AS (
		select  count(DISTINCT times.minute) as vcount from times,problems
		where (
				problems.start_time  <=  times.minute AND 
				problems.stop_time >= times.minute
			) OR (
				problems.start_time  <=  times.minute AND 
				problems.stop_time is NULL
			)
	)
select ROUND(100-((vcount.vcount::float/tcount.tcount::float)*100)::numeric,2) as value from tcount, vcount
