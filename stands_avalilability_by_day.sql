--WITH times AS (	select * from generate_series((date_trunc('day',current_timestamp) - interval '1 DAY')::DATE, date_trunc('day',current_timestamp),'10m') as minute ),
WITH times AS (	select * from generate_series((date_trunc('day',timestamp '2020-12-23 00:01') - interval '1 DAY')::DATE, date_trunc('day',timestamp '2020-12-23 00:01'),'10m') as minute ),
	zhosts AS (  
        select DISTINCT functions.itemid, functions.triggerid, hosts.host as host, hstgrp.name as group from functions 
        left JOIN items ON items.itemid = functions.itemid  
        left JOIN hosts ON items.hostid = hosts.hostid 
        left join hosts_groups ON hosts.hostid = hosts_groups.hostid  
        join hstgrp ON hosts_groups.groupid = hstgrp.groupid AND hstgrp.name IN ('stand-test','stand-test-jvm','stand-demo','stand-demo-jvm') 
    ), 
    tags AS (select * from event_tag where tag = 'StandWork'),
	tcount AS ( select count(*) as tcount from times), --where times.minute > date_trunc('MONTH', now()) ),
--============= stand-dev-n2 ===============--
	stand_dev_n2 AS (
		select pb.eventid,TO_TIMESTAMP(pb.clock) as start_time, TO_TIMESTAMP(e_recovery.r_clock) as stop_time, pb.name, tags.tag, tags.value, zhosts.host, zhosts.group  from events as pb 
		join tags ON pb.eventid = tags.eventid 
		join zhosts on pb.objectid = zhosts.triggerid AND (
			(zhosts.group = 'eb-exp05fb' AND zhosts.host LIKE 'stand-dev-n2%')
			OR ( zhosts.group = 'stand-test' AND zhosts.host NOT IN ('stand-test-portal','stand-test-s','stand-test-ufo'))
			OR ( zhosts.group = 'stand-test-jvm' AND zhosts.host NOT IN ('stand-test-ufo_AdminServer','stand-test-ufo_Airport','stand-test-ufo_Port'))
			OR (
				zhosts.host = 'stand-test-http-checks'
				AND ( pb.name NOT LIKE 'stand-test-ufo%' OR pb.name NOT LIKE 'stand-test-port%'))
			OR ( zhosts.group = 'stand-test-jvm' AND zhosts.host LIKE ('stand-dev-n2%'))
		)
		left join ( 
			select event_recovery.eventid as eventid, event_recovery.r_eventid, events.clock as r_clock from event_recovery 
			join events on event_recovery.r_eventid = events.eventid 
		) as e_recovery ON pb.eventid = e_recovery.eventid 
		where pb.value = 1 
	),
	stand_dev_n2_vcount AS ( --stand name
		select 'stand-dev-n2' as stand, ROUND(100-((vcount.vcount::float/tcount.tcount::float)*100)::numeric,2) as value from tcount, ( --stand name
			select count(DISTINCT times.minute) as vcount from times,stand_dev_n2 as problems --stand name
			where (	problems.start_time  <=  times.minute AND problems.stop_time >= times.minute) 
				OR (problems.start_time  <=  times.minute AND (problems.stop_time IS NULL or problems.stop_time = TO_TIMESTAMP(0))
				)
	) as vcount ),
--==================================================
--============ stand-test-n2 ===============--
	stand_test_n2 AS (
		select pb.eventid,TO_TIMESTAMP(pb.clock) as start_time, TO_TIMESTAMP(e_recovery.r_clock) as stop_time, pb.name, tags.tag, tags.value, zhosts.host, zhosts.group  from events as pb 
		join tags ON pb.eventid = tags.eventid 
		join zhosts on pb.objectid = zhosts.triggerid AND (
			(zhosts.group = 'stand' AND zhosts.host LIKE 'stand-test-n2%')
			OR ( zhosts.group = 'stand-test' AND zhosts.host NOT IN ('stand-test-port','stand-test-s','stand-ufo'))
			OR ( zhosts.group = 'stand-test-jvm' AND zhosts.host NOT IN ('stand-test-ufo_AdminServer','stand-test-ufo_Airport','stand-test-ufo_Port'))
			OR (
				zhosts.host = 'eb-exp-test-http-checks'
				AND ( pb.name NOT LIKE 'stand-test-ufo%' OR pb.name NOT LIKE 'stand-test-port%'))
			OR ( zhosts.group = 'stand-test-jvm' AND zhosts.host LIKE ('stand-test-n2%'))
		)
		left join ( 
			select event_recovery.eventid as eventid, event_recovery.r_eventid, events.clock as r_clock from event_recovery 
			join events on event_recovery.r_eventid = events.eventid 
		) as e_recovery ON pb.eventid = e_recovery.eventid 
		where pb.value = 1 
	),
	stand_test_n2_vcount AS ( --stand name
		select 'stand-test-n2' as stand, ROUND(100-((vcount.vcount::float/tcount.tcount::float)*100)::numeric,2) as value from tcount, ( --stand name
			select count(DISTINCT times.minute) as vcount from times,stand_test_n2 as problems --stand name
			where (	problems.start_time  <=  times.minute AND problems.stop_time >= times.minute) 
				OR (problems.start_time  <=  times.minute AND (problems.stop_time IS NULL or problems.stop_time = TO_TIMESTAMP(0))
				)
	) as vcount ),
--==================================================
select * from (
	select * from stand_dev_n2_vcount
	union
	select * from stand_test_n2_vcount
) as stands
order by stand
