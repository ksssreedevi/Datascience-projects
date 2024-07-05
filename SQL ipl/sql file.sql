#1
use ipl;

select bidder_id,bidder_name,wins,total ,round((wins/total)*100,2) perc from 
(select ipd.*, ifnull((select count(BID_STATUS) wins from ipl_bidding_details ipdd 
where BID_STATUS='won' and ipd.bidder_id=ipdd.bidder_id
group by bidder_id),0) wins,
ifnull((select count(BID_STATUS) wins from ipl_bidding_details ipdd 
where ipd.bidder_id=ipdd.bidder_id
group by bidder_id),0) total
from ipl_bidder_details ipd) t order by perc desc;

#2
select ims.stadium_id,ips.STADIUM_NAME,CITY,count(match_id) n_matches
from ipl_match_schedule ims left join ipl_stadium ips on ims.STADIUM_ID=ips.STADIUM_ID
group by stadium_id,ips.STADIUM_NAME order by stadium_id;

#3
select stadium_id,(select STADIUM_NAME from ipl_stadium s where s.STADIUM_ID=t.STADIUM_ID) name,
count(TOSS_WINNER) cnt ,total, 
round((count(TOSS_WINNER)/total)*100,2) perc 
from 
(select STADIUM_ID,ims.MATCH_ID,TEAM_ID1,TEAM_ID2,
TOSS_WINNER,MATCH_WINNER
, count(*) over(partition by STADIUM_ID ) total
 from ipl_match_schedule ims left join ipl_match im 
on ims.MATCH_ID=im.MATCH_ID ) t 
where TOSS_WINNER=MATCH_WINNER 
group by stadium_id;

#4

select BID_TEAM,team_name,count(BIDDER_ID) total_bids
from ipl_bidding_details ibd left join ipl_team it
on TEAM_ID=bid_team group by BID_TEAM order by BID_TEAM;

#5

select t.*,team_name from 
(select *,trim( ' ' from trim(' w' from substr(win_details,6,4))) ext
 from ipl_match) t 
 left join  ipl_team it
 on  t.ext= it.remarks;

#6
select its.TEAM_ID,team_name,sum(MATCHES_PLAYED) 'total matches'
,sum(MATCHES_WON) 'matches won'
,sum(MATCHES_LOST) 'matches lost'
from ipl_team_standings its left join ipl_team it on its.team_id=it.team_id
group by its.team_id;


#7 
select itp.TEAM_ID,itp.PLAYER_ID,player_name,PLAYER_ROLE,team_name from ipl_team_players itp left join ipl_team it
on itp.team_id=it.team_id left join ipl_player ip on itp.player_id=ip.player_id
where player_role='bowler' and team_name like 'mumbai indians';

#8

select team_name,count(player_role) all_rounders 
from ipl_team_players itp left join ipl_team it on itp.team_id=it.team_id
where player_role='All-Rounder' group by team_name having all_rounders>4 order by all_rounders desc;

# 9
-- Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK 
-- when it won the match in M. Chinnaswamy Stadium bidding year-wise.
-- Note the total bidders’ points in descending order and the year is bidding year.
-- Display columns: bidding status, bid date as year, total bidder’s points
select *,
(select TOTAL_POINTS from ipl_bidder_points i where i.BIDDER_ID=t1.BIDDER_ID) as 'total bidder’s points'
from 
(select bid_status,bidder_id,year(bid_date) year,winner,ibd.SCHEDULE_ID
from 
(select match_id,if(match_winner=1,team_id1,team_id2) winner from ipl_match) t
left join ipl_match_schedule ims on ims.match_id=t.match_id
left join ipl_bidding_details ibd on ibd.SCHEDULE_ID=ims.SCHEDULE_ID
where stadium_id=(select stadium_id from ipl_stadium where stadium_name='M. Chinnaswamy Stadium')
and t.winner=(select team_id from ipl_team where remarks='csk')) t1
;

#10
select * from 
(select PLAYER_ID,PLAYER_NAME,player_role,dense_rank() over(order by cast(wkt as float) desc) rnk,wkt  from 
(select *,trim('#' from replace(substr(PERFORMANCE_DTLS,instr(PERFORMANCE_DTLS,'wkt')+4,2),' ','#')) wkt,
(select player_role from ipl_team_players itp where itp.PLAYER_ID=ip.PLAYER_ID) player_role
from ipl_player ip) t where player_role in ('All-Rounder','Bowler')) t1
where rnk<=5;

#11
select temp.*,total_points,round((wins/total_points)*100,2) perc  from 
(select bidder_id,count(toss) wins
from ipl_bidding_details ibd left join 
(select im.MATCH_ID,SCHEDULE_ID,
TEAM_ID1,TEAM_ID2,if(TOSS_WINNER=1,TEAM_ID1,TEAM_ID2) toss
from ipl_match im join ipl_match_schedule ims on ims.MATCH_ID=im.MATCH_ID) t 
on ibd.schedule_id=t.SCHEDULE_ID where bid_team=toss group by bidder_id) temp 
left join ipl_bidder_points ibp on ibp.bidder_id=temp.bidder_id;

#12
(select *,'max' as 'min/max' from 
(SELECT TOURNMT_ID,TOURNMT_NAME,datediff(TO_DATE,FROM_DATE) duration FROM ipl_tournament) t where
duration = (select max(datediff(TO_DATE,FROM_DATE)) from  ipl_tournament))
union all
(select *,'min' as 'min/max' from 
(SELECT TOURNMT_ID,TOURNMT_NAME,datediff(TO_DATE,FROM_DATE) duration FROM ipl_tournament) t where
duration = (select min(datediff(TO_DATE,FROM_DATE)) from  ipl_tournament)) ;

#13

select ibd.bidder_id,bidder_name,year(bid_date) as year,month(bid_date) as month,sum(TOTAL_POINTS) total
from ipl_bidding_details ibd left join ipl_bidder_details ibbd on ibd.BIDDER_ID=ibbd.BIDDER_ID
left join ipl_bidder_points ibp on ibp.bidder_id=ibd.bidder_id 
where year(bid_date)=2017 group by ibd.bidder_id,bidder_name,year,month order by total desc,month ;

#14

select bidder_id,bidder_name,year,month,sum(TOTAL_POINTS) TOTAL_POINTS from 
(select ibd2.bidder_id,	
(select BIDDER_NAME from ipl_bidder_details ibd1 where ibd1.BIDDER_ID=ibd2.BIDDER_ID) BIDDER_NAME,
year(bid_date) year,month(bid_date) month,
(select TOTAL_POINTS from ipl_bidder_points ibp where ibp.BIDDER_ID=ibd2.BIDDER_ID) TOTAL_POINTS
 from ipl_bidding_details ibd2 where year(bid_date)=2017) t 
 group by bidder_id,bidder_name,year,month order by total_points desc,month;
 

 #15
 
 select bidder_id,rnk,total_points,
 (select BIDDER_NAME from ipl_bidder_details i where i.bidder_id=temp.bidder_id ) highest_3,
 (select BIDDER_NAME from ipl_bidder_details i where i.bidder_id=temp.last_3 ) lowest_3
 from 
 (select *, 
 (select bidder_id from 
 (select bidder_id,total_points,row_number() over(order by total_points) rnk ,row_number() over() rnk1 from ipl_bidder_points) t1
 where rnk<=3 and t1.rnk1=t.rnk) last_3
 from 
 (select bidder_id,total_points,dense_rank() over(order by total_points desc) rnk from ipl_bidder_points) t
 where rnk<=3) temp ;


#16

-- Creating Student_details table
CREATE TABLE Student_details (
  Student_id INT PRIMARY KEY,
  Student_name VARCHAR(50),
  Mail_id VARCHAR(50),
  Mobile_no VARCHAR(15)
);

-- Creating Student_details_backup table
CREATE TABLE Student_details_backup (
  Student_id INT,
  Student_name VARCHAR(50),
  Mail_id VARCHAR(50),
  Mobile_no VARCHAR(15),
  Backup_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Enters timestamp on inserting values;
);

-- creating triggers
CREATE TRIGGER student_details_insert_trigger
AFTER INSERT ON Student_details
FOR EACH ROW
  INSERT INTO Student_details_backup (Student_id, Student_name, Mail_id, Mobile_no)
  VALUES (NEW.Student_id, NEW.Student_name, NEW.Mail_id, NEW.Mobile_no);
  
-- drop trigger student_details_insert_trigger;

INSERT INTO Student_details(Student_id, Student_name, Mail_id, Mobile_no)
  VALUES (101,'adarsh','mail',90792415);
-- inserting values will store the record in backup table as well.