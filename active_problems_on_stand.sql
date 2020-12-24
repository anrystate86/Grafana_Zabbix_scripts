WITH zhosts AS ( 
		select DISTINCT functions.itemid, functions.triggerid, hosts.host as host, hstgrp.name as group from functions
		left JOIN items ON items.itemid = functions.itemid 
		left JOIN hosts ON items.hostid = hosts.hostid
		left join hosts_groups ON hosts.hostid = hosts_groups.hostid 
		join hstgrp ON hosts_groups.groupid = hstgrp.groupid AND hstgrp.name IN ('stand-test','stand-test-jvm')
	),
	tags AS (select * from event_tag where tag = 'StandWork')
select  count(*) as value from (
	select pb.eventid,TO_TIMESTAMP(pb.clock) as start_time, TO_TIMESTAMP(e_recovery.r_clock) as stop_time, pb.name, tags.tag, tags.value, zhosts.host, zhosts.group  from events as pb
	join tags ON pb.eventid = tags.eventid
	join zhosts on pb.objectid = zhosts.triggerid AND (
		(
			zhosts.host NOT IN ('stand-test-port','stand-test-s','stand-test-ufo','stand-test-http-checks')
		)
		OR
		(
			zhosts.host NOT IN ('stand-test-ufo_AdminServer','stand-test-ufo_Airport','stand-test-ufo_Port','stand-test-port_AdminServer')
		)
		OR
		(
			zhosts.host = 'stand-test-http-checks'
			AND
			(
				pb.name NOT LIKE 'stand-test-ufo%'
				OR
				pb.name NOT LIKE 'stand-test-port%'
			)
		)
	)
	left join (
			select event_recovery.eventid as eventid, event_recovery.r_eventid, events.clock as r_clock from event_recovery
			join events on event_recovery.r_eventid = events.eventid
		) as e_recovery ON pb.eventid = e_recovery.eventid
	where pb.value = 1
) as problems
where (	problems.stop_time is NULL )
