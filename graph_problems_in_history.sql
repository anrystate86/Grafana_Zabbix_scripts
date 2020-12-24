WITH times AS ( select * from generate_series('2020-12-01 00:00'::timestamp, current_timestamp,'10m') as minute, (select 0 as value) as value ), 
    zhosts AS (  
        select DISTINCT functions.itemid, functions.triggerid, hosts.host as host, hstgrp.name as group from functions 
        left JOIN items ON items.itemid = functions.itemid  
        left JOIN hosts ON items.hostid = hosts.hostid 
        left join hosts_groups ON hosts.hostid = hosts_groups.hostid  
        join hstgrp ON hosts_groups.groupid = hstgrp.groupid AND hstgrp.name IN ('stand-test','stand-test-jvm') 
    ), 
    tags AS (select * from event_tag where tag = 'StandWork') ,
	  timeproblems as (select  times.minute as time,count(problem2.name) as value from times,  
    ( 
        select pb.eventid,TO_TIMESTAMP(pb.clock) as start_time, TO_TIMESTAMP(e_recovery.r_clock) as stop_time, pb.name, tags.tag, tags.value, zhosts.host, zhosts.group  from events as pb 
        join tags ON pb.eventid = tags.eventid 
        join zhosts on pb.objectid = zhosts.triggerid
        left join ( 
                select event_recovery.eventid as eventid, event_recovery.r_eventid, events.clock as r_clock from event_recovery 
                join events on event_recovery.r_eventid = events.eventid 
            ) as e_recovery ON pb.eventid = e_recovery.eventid 
        where pb.value = 1 
    ) as problem2 
    where ( 
            problem2.start_time  <=  times.minute AND  
            problem2.stop_time >= times.minute 
        ) OR ( 
            problem2.start_time  <=  times.minute AND  
            problem2.stop_time is NULL 
        ) 
    group by times.minute 
    order by times.minute 
	)
	select times.minute as time , times.value+timeproblems.value as value from times
	left join timeproblems on times.minute = timeproblems.time
