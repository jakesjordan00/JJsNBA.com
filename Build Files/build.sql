--This will create the tables for the database
--Change the nba1 variable from openquery to the name of the Linked Server you are loading from.


Select * into game -- This creates the game table
from openquery(nba1, 'select * from game')
GO

---------------------------------------------------------------------------------

Select * into player -- This creates the player table
from openquery(nba1, 'select * from player')
GO

---------------------------------------------------------------------------------

Select * into player_game_log -- This creates the player_game_log table
from openquery(nba1, 'select * from player_game_log')
GO

---------------------------------------------------------------------------------

Select * into pgtt -- This creates the player_general_traditional_total table as pgtt. I found the title of the former took up took much space
from openquery(nba1, 'select * from player_general_traditional_total')
GO

---------------------------------------------------------------------------------

Select * into player_season -- This creates the player_season table
from openquery(nba1, 'select * from player_season')
GO

---------------------------------------------------------------------------------

Select * into season -- This creates the season table
from openquery(nba1, 'select * from season')
GO

---------------------------------------------------------------------------------

Select * into team -- This creates the team table
from openquery(nba1, 'select * from team')
GO

---------------------------------------------------------------------------------

Select * into pbp -- This creates the team table
from openquery(nba1, 'select * from play_by_play')
GO

---------------------------------------------------------------------------------

Select * into event_message_type -- This creates the team table
from openquery(nba1, 'select * from event_message_type')
GO

---------------------------------------------------------------------------------

--CREATION FOR team_game_log
----Creates the initial table for the first team in each game
SELECT season.season_id,  game.game_id, team.team_id, t2.team_id as opteam_id,
									SUM(player_game_log.pts) as score, 									
								       SUM(player_game_log.ast)  as asts,
									   SUM(player_game_log.reb) as rebs,
									   SUM(player_game_log.oreb) as orebs,
									   SUM(player_game_log.dreb) as drebs,
									   SUM(player_game_log.stl) as stls,
									   SUM(player_game_log.blk) as blks,
									   SUM(player_game_log.fgm)-SUM(player_game_log.fg3m) as fgs,
									   SUM(player_game_log.fga)-SUM(player_game_log.fg3a)as fga,
									   ROUND((SUM(player_game_log.fgm)-SUM(player_game_log.fg3m))/(SUM(player_game_log.fga)-SUM(player_game_log.fg3a))*100,1) as fgpct,
									   SUM(player_game_log.fg3m) as fg3s,
									   SUM(player_game_log.fg3a) as fg3a,
									   ROUND(SUM(player_game_log.fg3m)/SUM(player_game_log.fg3a)*100,1) as fg3pct,
									   SUM(player_game_log.ftm) as fts,
									   SUM(player_game_log.fta) as fta,
									   ROUND(SUM(player_game_log.ftm)/SUM(player_game_log.fta)*100,1) as ftpct,
									   player_game_log.wl as result									  
INTO team_winner_game_log

FROM game INNER JOIN
	 team on game.team_id_winner = team.team_id JOIN
	 team as t2 on game.team_id_loser = t2.team_id INNER JOIN
	 player_game_log on team.team_id = player_game_log.team_id INNER JOIN
	 season on player_game_log.season_id = season.season_id

WHERE game.game_id = player_game_log.game_id AND player_game_log.team_id = team.team_id 
GROUP BY team.team_id, game.game_id, player_game_log.wl, season.season_id, t2.team_id
ORDER BY game_id ASC

GO

--Creates the matching table for the opponent of the teams selected above
SELECT season.season_id,  game.game_id, t2.team_id, team.team_id as opteam_id,
									SUM(player_game_log.pts) as score, 									
								       SUM(player_game_log.ast)  as asts,
									   SUM(player_game_log.reb) as rebs,
									   SUM(player_game_log.oreb) as orebs,
									   SUM(player_game_log.dreb) as drebs,
									   SUM(player_game_log.stl) as stls,
									   SUM(player_game_log.blk) as blks,
									   SUM(player_game_log.fgm)-SUM(player_game_log.fg3m) as fgs,
									   SUM(player_game_log.fga)-SUM(player_game_log.fg3a)as fga,
									   ROUND((SUM(player_game_log.fgm)-SUM(player_game_log.fg3m))/(SUM(player_game_log.fga)-SUM(player_game_log.fg3a))*100,1) as fgpct,
									   SUM(player_game_log.fg3m) as fg3s,
									   SUM(player_game_log.fg3a) as fg3a,
									   ROUND(SUM(player_game_log.fg3m)/SUM(player_game_log.fg3a)*100,1) as fg3pct,
									   SUM(player_game_log.ftm) as fts,
									   SUM(player_game_log.fta) as fta,
									   ROUND(SUM(player_game_log.ftm)/SUM(player_game_log.fta)*100,1) as ftpct,
									   player_game_log.wl as result										  
INTO team_loser_game_log

FROM game INNER JOIN
	 team on game.team_id_winner = team.team_id JOIN
	 team as t2 on game.team_id_loser = t2.team_id INNER JOIN
	 player_game_log on t2.team_id = player_game_log.team_id INNER JOIN
	 season on game.season_id = season.season_id

WHERE game.game_id = player_game_log.game_id AND player_game_log.team_id = t2.team_id 
GROUP BY team.team_id, game.game_id, player_game_log.wl, season.season_id, t2.team_id
ORDER BY game_id ASC
GO


--Creates a temp table to insert the contents of both the team_loser and team_winner tables
SELECT x.* INTO team_game_log FROM
	(SELECT * from team_loser_game_log 

	UNION

	SELECT * from team_winner_game_log)x
GO

--Drops redundant tables
drop table team_loser_game_log
GO
drop table team_winner_game_log
GO

--CREATION FOR opteam_game_log
SELECT team_game_log.season_id, team_game_log.game_id, team_game_log.team_id, team_game_log.opteam_id,
	   optgl.score as opscore,
	   optgl.asts as opasts,
	   optgl.rebs as oprebs,
	   optgl.orebs as oporebs,
	   optgl.drebs as opdrebs,
	   optgl.stls as opstls,
	   optgl.blks as opblks,
	   optgl.fgs as opfgs,
	   optgl.fga as opfga,
	   optgl.fgpct as opfgpct,
	   optgl.fg3s as opfg3s,
	   optgl.fg3a as opfg3a,
	   optgl.fg3pct as opfg3pct,
	   optgl.fts as opfts,
	   optgl.fta as opfta,
	   optgl.ftpct as opftpct
INTO opteam_game_log

FROM team_game_log JOIN
	team_game_log as optgl ON team_game_log.opteam_id = optgl.team_id AND team_game_log.game_id = optgl.game_id 
GO

---------------------------------------------------------------------------------

--Creation for team_season
SELECT season.season_id, team.team_id,
				AVG(player_season.age) as avgage,
				CONCAT(AVG(player_season.player_height_inches)/12, '''', AVG(player_season.player_height_inches)%12)as avgheight,
									   ROUND(SUM(team_game_log.score)/COUNT(team_game_log.game_id),1) as ppg, 
									   ROUND(SUM(team_game_log.asts)/COUNT(team_game_log.game_id),0) as apg,
									   ROUND(SUM(team_game_log.orebs)/COUNT(team_game_log.game_id),0) as orbpg,
									   ROUND(SUM(team_game_log.drebs)/COUNT(opteam_game_log.game_id),0) as drbpg,
									   ROUND(SUM(team_game_log.rebs)/COUNT(team_game_log.game_id),0) as rbpg,
									   ROUND(SUM(team_game_log.fgs)/COUNT(team_game_log.game_id),0)as fgm,
									   ROUND(SUM(team_game_log.fga)/COUNT(team_game_log.game_id),0) as fga,									   									   
									   ROUND(AVG(team_game_log.fgpct),1) as fgpct,
									   ROUND(SUM(team_game_log.fts)/COUNT(team_game_log.game_id),0)as ftm,
									   ROUND(SUM(team_game_log.fta)/COUNT(team_game_log.game_id),0) as fta,									   									   
									   ROUND(AVG(team_game_log.ftpct),1) as ftpct,
									   ROUND(ROUND(SUM(team_game_log.fg3s),1)/COUNT(team_game_log.game_id),0) as fg3m,
									   ROUND(ROUND(SUM(team_game_log.fg3a),1)/COUNT(team_game_log.game_id),0) as fg3a,									   									   
									   ROUND(AVG(team_game_log.fg3pct),1) as fg3pct,
									   --The rank here is ROUNDED by 2 to get a more accurate reading of the statistics
									   ----ROUNDING by more than 2 does not generate a completely unique list, thus this is the maximum it can be rounded by
									   RANK() OVER(ORDER BY ROUND(SUM(team_game_log.score)/COUNT(team_game_log.game_id),2)DESC) as ppg_rank,
									   RANK() OVER(ORDER BY ROUND(SUM(opteam_game_log.opscore)/COUNT(team_game_log.game_id),2)) as ptsallowed_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(team_game_log.asts)/COUNT(team_game_log.game_id),1)) as apg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(team_game_log.orebs)/COUNT(team_game_log.game_id),1)) as orbpg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(team_game_log.drebs)/COUNT(team_game_log.game_id),1)) as drbpg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(team_game_log.rebs)/COUNT(team_game_log.game_id),1)) as rbpg_rank,								   					   
									   --The rank here is ROUNDED by 2 to get a more accurate reading of the statistics
									   RANK() OVER(ORDER BY ROUND(AVG(team_game_log.fgpct),2) DESC) as fgpct_rank,
									   RANK() OVER(ORDER BY ROUND(SUM(team_game_log.fga)/COUNT(team_game_log.game_id),2) ASC) as fga_rank,								   								   
									   --The rank is ROUNDED by 1 here in order to get a more accurate reading of the statistics
									   ----I found that when ROUNDING by 0 returns a lot of ties								   
									   RANK() OVER(ORDER BY ROUND(AVG(team_game_log.fg3pct),2) DESC) as fg3pct_rank,									   
									   RANK() OVER(ORDER BY ROUND(SUM(team_game_log.fg3a)/COUNT(team_game_log.game_id),2) ASC) as fg3a_rank,									   
									   --The rank is ROUNDED by 1 here in order to get a more accurate reading of the statistics
									   ----I found that when ROUNDING by 0 returns a lot of ties	
									   RANK() OVER(ORDER BY ROUND(AVG(team_game_log.ftpct),2)DESC) as ftpct_rank,							   
									   RANK() OVER(ORDER BY ROUND(SUM(team_game_log.fta)/COUNT(team_game_log.game_id),2) ASC) as fta_rank,
									   

									   --opteam season columns
									   ROUND(SUM(opteam_game_log.opscore)/COUNT(team_game_log.game_id),1) as op_ppg,
									   ROUND(SUM(opteam_game_log.opasts)/COUNT(opteam_game_log.game_id),0) as opapg,
									   ROUND(SUM(opteam_game_log.oporebs)/COUNT(opteam_game_log.game_id),0) as oporbpg,
									   ROUND(SUM(opteam_game_log.opdrebs)/COUNT(opteam_game_log.game_id),0) as opdrbpg,
									   ROUND(SUM(opteam_game_log.oprebs)/COUNT(opteam_game_log.game_id),0) as oprbpg,
									   --Adding stats to show how the opposing team fares against this team
									   ROUND(SUM(opteam_game_log.opfgs)/COUNT(team_game_log.game_id),0) as opfgm,
									    ROUND(SUM(opteam_game_log.opfga)/COUNT(team_game_log.game_id),0) as opfga,									   									   
									   ROUND(AVG(opteam_game_log.opfgpct),1) as opfgpct,
									   ROUND(SUM(opteam_game_log.opfts)/COUNT(team_game_log.game_id),0) as opftm,
									   ROUND(SUM(opteam_game_log.opfta)/COUNT(team_game_log.game_id),0) as opfta,									   									   
									   ROUND(AVG(opteam_game_log.opftpct),1) as opftpct,
									   ROUND(ROUND(SUM(opteam_game_log.opfg3s),1)/COUNT(team_game_log.game_id),0) as opfg3m,
									   ROUND(ROUND(SUM(opteam_game_log.opfg3a),1)/COUNT(opteam_game_log.game_id),0) as opfg3a,									   									   
									   ROUND(AVG(opteam_game_log.opfg3pct),1) as opfg3pct,							   
									   RANK() OVER(ORDER BY	 ROUND(SUM(opteam_game_log.opasts)/COUNT(opteam_game_log.game_id),1)) as opapg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(opteam_game_log.oporebs)/COUNT(opteam_game_log.game_id),1)) as oporbpg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(opteam_game_log.opdrebs)/COUNT(opteam_game_log.game_id),1)) as opdrbpg_rank,
									   RANK() OVER(ORDER BY	 ROUND(SUM(opteam_game_log.oprebs)/COUNT(opteam_game_log.game_id),1)) as oprbpg_rank,								   					   
									   --The rank here is ROUNDED by 2 to get a more accurate reading of the statistics
									   ----ROUNDING by more than 2 does not generate a completely unique list, thus this is the maximum it can be rounded by
									   RANK() OVER(ORDER BY ROUND(AVG(opteam_game_log.opfgpct),2)) as opfgpct_rank,
									   RANK() OVER(ORDER BY ROUND(SUM(opteam_game_log.opfga)/COUNT(team_game_log.game_id),2) ASC) as opfga_rank,								   								   
									   --The rank is ROUNDED by 1 here in order to get a more accurate reading of the statistics
									   ----I found that when ROUNDING by 0 returns a lot of ties								   
									   RANK() OVER(ORDER BY ROUND(AVG(opteam_game_log.opfg3pct),2)) as opfg3pct_rank,									   
									   RANK() OVER(ORDER BY ROUND(SUM(opteam_game_log.opfg3a)/COUNT(opteam_game_log.game_id),2) ASC) as opfg3a_rank,									   
									   --The rank is ROUNDED by 1 here in order to get a more accurate reading of the statistics
									   ----I found that when ROUNDING by 0 returns a lot of ties	
									   RANK() OVER(ORDER BY ROUND(AVG(opteam_game_log.opftpct),2)) as opftpct_rank,							   
									   RANK() OVER(ORDER BY ROUND(SUM(opteam_game_log.opfta)/COUNT(team_game_log.game_id),2) ASC) as opfta_rank									   
									   
INTO team_season

FROM team_game_log INNER JOIN
	opteam_game_log on team_game_log.game_id = opteam_game_log.game_id INNER JOIN
	team on team.team_id = team_game_log.team_id INNER JOIN
	season on team_game_log.season_id = season.season_id JOIN
	player_season on team_game_log.team_id = player_season.team_id


GROUP BY team.team_id, season.season_id
ORDER BY team_id
GO

---------------------------------------------------------------------------------

--Creation for team wins table
--Wins
SELECT team.team_id, season.season_id, CONCAT('(',team.abbreviation,')', team.city, ' ', team.nickname) as Team, 
	   COUNT(team_game_log.score) as Wins
INTO team_wins
FROM GAME INNER JOIN
	team on game.team_id_winner = team.team_id JOIN --Our players' team
	team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --Creating this as the "opteam" table
	team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
	opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id INNER JOIN --Total team score for opteam
	season on season.season_id = game.season_id

WHERE team_game_log.score > opteam_game_log.opscore
GROUP BY CONCAT('(',team.abbreviation,')', team.city, ' ', team.nickname), team.team_id, season.season_id
GO

---------------------------------------------------------------------------------

--Creation for team losses table
--Losses
SELECT team.team_id, season.season_id, CONCAT('(',team.abbreviation,')', team.city, ' ', team.nickname) as Team,
	   COUNT(team_game_log.score) as Losses
INTO team_losses
FROM GAME INNER JOIN
	team on game.team_id_loser = team.team_id JOIN --Our players' team
	team as loserTeam on game.team_id_winner = loserTeam.team_id INNER JOIN --Creating this as the "opteam" table
	team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
	opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id INNER JOIN --Total team score for opteam
	season on season.season_id = game.season_id

WHERE opteam_game_log.opscore > team_game_log.score
GROUP BY CONCAT('(',team.abbreviation,')', team.city, ' ', team.nickname), team.team_id, season.season_id
GO

---------------------------------------------------------------------------------

--Creates table for Eastern Conference teams
SELECT team.team_id, team.nickname
INTO team_east
FROM team
WHERE  team.abbreviation = 'BOS' OR
	   team.abbreviation = 'MIL' OR
	   team.abbreviation = 'BKN' OR
	   team.abbreviation = 'CLE' OR
	   team.abbreviation = 'PHI' OR
	   team.abbreviation = 'NYK' OR
	   team.abbreviation = 'IND' OR
	   team.abbreviation = 'MIA' OR
	   team.abbreviation = 'ATL' OR
	   team.abbreviation = 'TOR' OR
	   team.abbreviation = 'CHI' OR
	   team.abbreviation = 'WAS' OR
	   team.abbreviation = 'ORL' OR
	   team.abbreviation = 'CHA' OR
	   team.abbreviation = 'DET'
GO	   
	   
---------------------------------------------------------------------------------
	    
--Creates table for Western Conference teams
SELECT team.team_id, team.nickname
INTO team_west
FROM team
WHERE  team.abbreviation = 'DEN' OR
	   team.abbreviation = 'NOP' OR
	   team.abbreviation = 'MEM' OR
	   team.abbreviation = 'LAC' OR
	   team.abbreviation = 'PHX' OR
	   team.abbreviation = 'DAL' OR
	   team.abbreviation = 'SAC' OR
	   team.abbreviation = 'POR' OR
	   team.abbreviation = 'UTA' OR
	   team.abbreviation = 'GSW' OR
	   team.abbreviation = 'MIN' OR
	   team.abbreviation = 'OKC' OR
	   team.abbreviation = 'LAL' OR
	   team.abbreviation = 'SAS' OR
	   team.abbreviation = 'HOU'	   
GO	   

------#####################################################################################
------#####################################################################################
------#####################################################################################
------------This section will update the tables with the appropriate key values------------
------#####################################################################################
------#####################################################################################
------#####################################################################################
ALTER TABLE team
ALTER COLUMN team_id int NOT NULL
GO
ALTER TABLE team
ADD primary key (team_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE player	
ALTER COLUMN player_id int NOT NULL
GO
ALTER TABLE player	
ADD primary key (player_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE season
ALTER COLUMN season_id int NOT NULL
GO
ALTER TABLE season
ADD primary key (season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE game	
ALTER COLUMN game_id int NOT NULL
GO
ALTER TABLE game
ADD primary key (game_id)
GO
ALTER TABLE game
ADD foreign key (team_id_winner) references team(team_id)
GO
ALTER TABLE game
ADD foreign key (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE player_game_log
ALTER COLUMN player_id int NOT NULL
GO
ALTER TABLE player_game_log
ALTER COLUMN game_id int NOT NULL
GO
ALTER TABLE player_game_log
ALTER COLUMN team_id int NOT NULL
GO
ALTER TABLE player_game_log
ADD foreign key (player_id) references player(player_id)
GO
ALTER TABLE player_game_log
ADD foreign key (game_id) references game(game_id)
GO
ALTER TABLE player_game_log
ADD foreign key (team_id) references team(team_id)
GO
ALTER TABLE player_game_log
ADD foreign key (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE pgtt
DROP COLUMN id
GO
ALTER TABLE pgtt
ADD id int identity(1,1) primary key
GO
ALTER TABLE pgtt
ADD foreign key (player_id) references player(player_id)
GO
ALTER TABLE pgtt
ADD foreign key (team_id) references team(team_id)
GO
ALTER TABLE pgtt
ADD foreign key (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE player_season
drop column id
GO
ALTER TABLE player_season
ADD id int identity(1,1) primary key
GO
ALTER TABLE player_season
ADD foreign key (player_id) references player(player_id)
GO
ALTER TABLE player_season
ADD foreign key (team_id) references team(team_id)
GO
ALTER TABLE player_season
ADD foreign key (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE event_message_type
DROP COLUMN id
GO
ALTER TABLE event_message_type
ADD id int identity(1,1) primary key
GO

---------------------------------------------------------------------------------

ALTER TABLE pbp
DROP COLUMN id
GO
ALTER TABLE pbp
ADD id int identity(1,1) primary key
GO
ALTER TABLE pbp WITH NOCHECK
ADD foreign key (event_msg_type_id) references event_message_type(id)
GO

---------------------------------------------------------------------------------

ALTER TABLE team_game_log
ADD foreign key (season_id) references season(season_id)
GO
ALTER TABLE team_game_log
ADD foreign key (game_id) references game(game_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE opteam_game_log
ADD foreign key (season_id) references season(season_id)
GO
ALTER TABLE opteam_game_log
ADD foreign key (game_id) references game(game_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE team_season
ADD FOREIGN KEY (season_id) references season(season_id)
GO
ALTER TABLE team_season
ADD FOREIGN KEY (team_id) references team(team_id)
GO

---------------------------------------------------------------------------------
ALTER TABLE team_wins
ADD FOREIGN KEY (team_id) references team(team_id)
GO
ALTER TABLE team_wins
ADD FOREIGN KEY (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE team_losses
ADD FOREIGN KEY (team_id) references team(team_id)
GO
ALTER TABLE team_losses
ADD FOREIGN KEY (season_id) references season(season_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE team_east
ADD FOREIGN KEY (team_id) references team(team_id)
GO

---------------------------------------------------------------------------------

ALTER TABLE team_west
ADD FOREIGN KEY (team_id) references team(team_id)
GO

---------------------------------------------------------------------------------
----------------------------Stored Procedure Creation----------------------------
---------------------------------------------------------------------------------
--Stored procedure to retrive box score results for both teams in a specified matchup
----Returns results for each game, sorted by winning and losing team, then sorted by player minutes and points descending
------The team whose players' results are being displayed will appear first in the "Matchup" column
----Returns most recent games first
CREATE PROCEDURE seasonbox
							@team1 varchar(255), @team2 varchar(255)
AS
SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,	
		player_game_log.fgm - player_game_log.fg3m	as "FGM",
		player_game_log.fga - player_game_log.fg3a	as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')	as "FG%",
		player_game_log.ftm							as FTM,		 
		player_game_log.fta							as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%')	as "FT%",
		player_game_log.fg3m						as "FG3M",
		player_game_log.fg3a						as "FG3A",
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"
		
		

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --Our players' team
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --"opteam" table, losing team from each matchup
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --This is getting our players' game stats in each win
		player on player_game_log.player_id = player.player_id LEFT JOIN   --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
		team_season on team.team_id = team_season.team_id  JOIN --Getting our players' team_season table here 
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --And getting the "opteam" team_season table here
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id --Total team score for opteam


WHERE (team.nickname=@team1 or team.nickname = @team2) AND (loserTeam.nickname=@team1 or loserTeam.nickname = @team2) AND player_game_log.wl = 'W'


UNION


SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A",
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"
		

FROM game INNER JOIN
		team on game.team_id_loser = team.team_id JOIN --Joining the losing team from each matchup as the main table 
		team as winnerTeam on game.team_id_winner = winnerTeam.team_id INNER JOIN --Joining the winning team from each matchup
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Losing team's player stats
		player on player_game_log.player_id = player.player_id LEFT JOIN --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Losing team's stats
		team_season on team.team_id = team_season.team_id JOIN --Losing team season stats
		team_season as opteam_season on winnerTeam.team_id = opteam_season.team_id INNER JOIN --Winning team's stats again but as "opteam" 
		opteam_game_log on winnerTeam.team_id = opteam_game_log.opteam_id and opteam_game_log.game_id = game.game_id --Added this table to get opteam, or team2's, score

WHERE (team.nickname=@team1 or team.nickname = @team2) AND (winnerTeam.nickname=@team1 or winnerTeam.nickname = @team2) AND player_game_log.wl = 'L'
ORDER BY  game.game_id DESC, player_game_log.wl DESC, MIN DESC, PTS DESC
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Stored procedure to retrieve box score results for up to six specified players in a particular matchup
----Enter as few players as you would like
----Returns results for each game, sorted by the date and winner and loser of each matchup, sorted by minutes, then points descending
----Returns most recent games first
--Enter the team names and player name(s)
----For example, @team1 = 'Pelicans',
-----------------@team2 = 'Suns',
-----------------@player= 'Brandon Ingram', and so on and so forth
CREATE PROCEDURE seasonbox_6players
									@team1 varchar(255), @team2 varchar(255), 
									@player varchar(255), @player1 varchar(255), @player2 varchar(255), @player3 varchar(255), @player4 varchar(255), @player5 varchar(255), 
									@player6 varchar(255), @player7 varchar(255), @player8 varchar(255), @player9 varchar(255), @player10 varchar(255)
AS
SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A",
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --Our players' team
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --"opteam" table, losing team from each matchup
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --This is getting our players' game stats in each win
		player on player_game_log.player_id = player.player_id LEFT JOIN   --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
		team_season on team.team_id = team_season.team_id  JOIN --Getting our players' team_season table here 
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --And getting the "opteam" team_season table here
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id --Total team score for opteam

WHERE (team.nickname=@team1 or team.nickname = @team2) AND (loserTeam.nickname=@team1 or loserTeam.nickname = @team2) AND player_game_log.wl = 'W' AND (player.player_name = @player 
																																					 OR   player.player_name = @player1
																																					 OR   player.player_name = @player2
																																					 OR   player.player_name = @player3
																																					 OR   player.player_name = @player4
																																					 OR   player.player_name = @player5
																																					 OR   player.player_name = @player6
																																					 OR   player.player_name = @player7
																																					 OR   player.player_name = @player8
																																					 OR   player.player_name = @player9
																																					 OR   player.player_name = @player10)
UNION


SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,		
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A", 
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_loser = team.team_id JOIN --Joining the losing team from each matchup as the main table 
		team as winnerTeam on game.team_id_winner = winnerTeam.team_id INNER JOIN --Joining the winning team from each matchup
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Losing team's player stats
		player on player_game_log.player_id = player.player_id LEFT JOIN --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Losing team's stats
		team_season on team.team_id = team_season.team_id JOIN --Losing team season stats
		team_season as opteam_season on winnerTeam.team_id = opteam_season.team_id INNER JOIN --Winning team's stats again but as "opteam" 
		opteam_game_log on winnerTeam.team_id = opteam_game_log.opteam_id and opteam_game_log.game_id = game.game_id --Added this table to get opteam, or team2's, score

WHERE (team.nickname=@team1 or team.nickname = @team2) AND (winnerTeam.nickname=@team1 or winnerTeam.nickname = @team2) AND player_game_log.wl = 'L' AND (player.player_name = @player 
																																					 OR   player.player_name = @player1
																																					 OR   player.player_name = @player2
																																					 OR   player.player_name = @player3
																																					 OR   player.player_name = @player4
																																					 OR   player.player_name = @player5
																																					 OR   player.player_name = @player6
																																					 OR   player.player_name = @player7
																																					 OR   player.player_name = @player8
																																					 OR   player.player_name = @player9
																																					 OR   player.player_name = @player10)
ORDER BY  game.game_id DESC, player_game_log.wl DESC, MIN DESC, PTS DESC
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Stored procedure to retrieve box score results for up to six specified players in a particular matchup
----Enter as few players as you would like
----Returns results for each game, sorted by the date and winner and loser of each matchup, sorted by minutes, then points descending
----Returns most recent games first
--Enter the team name and player name(s)
----For example, @team1 = 'Pelicans',
-----------------@player= 'Zion Williamson', and so on and so forth
CREATE PROCEDURE seasonbox_playersinwin 
				 @team1 varchar(255),
				 @player varchar(255), @player1 varchar(255), @player2 varchar(255), @player3 varchar(255), @player4 varchar(255), @player5 varchar(255), 
									@player6 varchar(255), @player7 varchar(255), @player8 varchar(255), @player9 varchar(255), @player10 varchar(255)
AS
SELECT	CONCAT('vs. ',  loserTeam.nickname) as Matchup,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A",
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --Our players' team
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --"opteam" table 
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --This is getting our players' game stats in each win
		player on player_game_log.player_id = player.player_id LEFT JOIN  --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
		team_season on team.team_id = team_season.team_id  JOIN --Getting our players' team_season table here 
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --And getting the "opteam" team_season table here
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id --Total team score for opteam

WHERE (team.nickname=@team1)  AND player_game_log.wl = 'W' AND (player.player_name = @player 
																							  OR   player.player_name = @player1
																							  OR   player.player_name = @player2
																							  OR   player.player_name = @player3
																							  OR   player.player_name = @player4
																							  OR   player.player_name = @player5
																							  OR   player.player_name = @player6
																							  OR   player.player_name = @player7
																							  OR   player.player_name = @player8
																							  OR   player.player_name = @player9
																							  OR   player.player_name = @player10)
ORDER BY  game.game_id DESC, player_game_log.wl DESC, MIN DESC, PTS DESC
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Stored procedure to retrieve box score results for up to six specified players in a particular matchup
----Enter as few players as you would like
----Returns results for each game, sorted by winner and loser the date of each matchup, sorted by minutes, then points descending
----Returns most recent games first
--Enter the team name and player name(s)
----For example, @team1  = 'Pelicans',
-----------------@team2  = 'Suns',
-----------------@player = 'Zion Williamson'
-----------------@player1= 'Chris Paul', and so on and so forth
CREATE PROCEDURE seasonbox_playersinmatchupwin
				 @team1 varchar(255), @team2 varchar(255), 
				 @player varchar(255), @player1 varchar(255), @player2 varchar(255), @player3 varchar(255), @player4 varchar(255), @player5 varchar(255), 
									@player6 varchar(255), @player7 varchar(255), @player8 varchar(255), @player9 varchar(255), @player10 varchar(255)
AS
SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A",
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --If team one has won in the matchup, builds out team table (Pelicans)
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --Corresponding "oppteam" table (suns)
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Getting the player stats of the first team if they've won (Pels, Zion Williamson)
		player on player_game_log.player_id = player.player_id LEFT JOIN  --For player names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --And the team's game log 
		team_season on team.team_id = team_season.team_id  JOIN --Getting our players' team_season table here 
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --And getting the "opteam" team_season table here
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id --Total team score for opteam

WHERE (team.nickname=@team1 AND loserTeam.nickname=@team2)  AND player_game_log.wl = 'W' AND (player.player_name = @player 
																							  OR   player.player_name = @player1
																							  OR   player.player_name = @player2
																							  OR   player.player_name = @player3
																							  OR   player.player_name = @player4
																							  OR   player.player_name = @player5
																							  OR   player.player_name = @player6
																							  OR   player.player_name = @player7
																							  OR   player.player_name = @player8
																							  OR   player.player_name = @player9
																							  OR   player.player_name = @player10)
UNION

SELECT	team.nickname as Team,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A", 
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --This is our second team's table (Suns)
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --This will be our first team, but here as "opteam" (Pelicans)
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Second team's players' stats in wins (suns, Chirs Paul)
		player on player_game_log.player_id = player.player_id LEFT JOIN --And for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Team2 game stats (suns)
		team_season on team.team_id = team_season.team_id JOIN --Team2 season stats
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --Team 1 stats again but as "opteam" 
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id and opteam_game_log.game_id = game.game_id --Added this table to get opteam, or team2's, score

WHERE (team.nickname=@team2 AND loserTeam.nickname=@team1)  AND player_game_log.wl = 'W' AND (player.player_name = @player 
																							  OR   player.player_name = @player1
																							  OR   player.player_name = @player2
																							  OR   player.player_name = @player3
																							  OR   player.player_name = @player4
																							  OR   player.player_name = @player5
																							  OR   player.player_name = @player6
																							  OR   player.player_name = @player7
																							  OR   player.player_name = @player8
																							  OR   player.player_name = @player9
																							  OR   player.player_name = @player10)
ORDER BY  game.game_id DESC, player_game_log.wl DESC, MIN DESC, PTS DESC
GO
--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Stored procedure to retrieve box score results for up to six specified players from a particular team
----Enter as few players as you would like
----Returns results for each game, sorted by the date of each matchup, sorted by minutes, then points descending
----Returns most recent games first
--Enter the team name and player name(s)
----For example, @team1  = 'Pelicans',
-----------------@player = 'Zion Williamson'
-----------------@player1= 'Brandon Ingram', and so on and so forth
CREATE PROCEDURE seasonbox_playergames
				 @team1 varchar(255), 
				 @player varchar(255), @player1 varchar(255), @player2 varchar(255), @player3 varchar(255), @player4 varchar(255), @player5 varchar(255), 
									@player6 varchar(255), @player7 varchar(255), @player8 varchar(255), @player9 varchar(255), @player10 varchar(255)
AS									
SELECT	CONCAT('vs. ',  loserTeam.nickname) as Matchup,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A", 
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --Our players' team
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --Creating this as the "opteam" table
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Tying our players to each specific game they logged minutes in
		player on player_game_log.player_id = player.player_id LEFT JOIN --Getting the game log to the player table for their names
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Getting this table for total team score
		team_season on team.team_id = team_season.team_id  JOIN --Getting our players' team_season table here 
		team_season as opteam_season on loserTeam.team_id = opteam_season.team_id INNER JOIN --And getting the "opteam" team_season table here
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id --Total team score for opteam

WHERE (team.nickname=@team1)  AND player_game_log.wl = 'W' AND (player.player_name = @player 
																							  OR   player.player_name = @player1
																							  OR   player.player_name = @player2
																							  OR   player.player_name = @player3
																							  OR   player.player_name = @player4
																							  OR   player.player_name = @player5
																							  OR   player.player_name = @player6
																							  OR   player.player_name = @player7
																							  OR   player.player_name = @player8
																							  OR   player.player_name = @player9
																							  OR   player.player_name = @player10)

UNION

SELECT	CONCAT('vs. ',team.nickname) as Matchup,
		FORMAT (game.date, 'd','us') as date, game.game_id,
		player.player_name as Player,
		CONCAT(ROUND(team_season.ppg,0), 'ppg - ', team_season.apg, 'apg - ', team_season.rbpg, 'rbpg')				as "Team ppg - apg - rbpg",
		player_game_log.wl as Result,
		CONCAT(team_game_log.score, ' - ', opteam_game_log.opscore) as Score,
		ROUND(player_game_log.min,0) as MIN,
		player_game_log.pts as PTS, 
		player_game_log.ast as AST, 
		player_game_log.reb as REB,
		player_game_log.blk as BLK,
		player_game_log.stl as STL,
		player_game_log.pf as PF,
		player_game_log.fgm - player_game_log.fg3m as "FGM",
		player_game_log.fga - player_game_log.fg3a as "FGA",
		CONCAT(player_game_log.fg_pct * 100, '%')  as "FG%",
		player_game_log.ftm as FTM,		 
		player_game_log.fta as FTA, 
		CONCAT(player_game_log.ft_pct * 100, '%') as "FT%",
		player_game_log.fg3m as "FG3M",
		player_game_log.fg3a as "FG3A", 
		CONCAT(player_game_log.fg3_pct * 100, '%')	as "FG3%",
		CONCAT(ROUND(opteam_season.op_ppg,0), ' PtsAlwd - Rank ', opteam_season.ptsallowed_rank)				as "OpPtsAlwd - Rank",
		opteam_season.opfgm							as "oFGM",
		opteam_season.opfga							as "oFGA",
		 
		CONCAT(opteam_season.opfgpct, '% Rank - ', opteam_season.opfgpct_rank) as "oFG% - Rank",
		opteam_season.opfg3m						as "oFG3M",
		opteam_season.opfg3a						as "oFG3A",
		 
		CONCAT(opteam_season.opfg3pct, '% Rank - ', opteam_season.opfg3pct_rank) as "oFG3% - Rank"

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN --This is our "opteam" table
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN --Here, we have the team we are selecting in our execution as the loserTeam
		player_game_log on game.game_id = player_game_log.game_id  INNER JOIN --Our players' team again here
		player on player_game_log.player_id = player.player_id LEFT JOIN --And here
		team_game_log on loserTeam.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id INNER JOIN --Our players' team, used for score
		team_season on loserTeam.team_id = team_season.team_id JOIN --Our players' team
		team_season as opteam_season on team.team_id = opteam_season.team_id INNER JOIN --"opteam" table again
		opteam_game_log on team.team_id = opteam_game_log.opteam_id and opteam_game_log.game_id = game.game_id --Added this table here to get opteam's score

WHERE (loserTeam.nickname=@team1)  AND player_game_log.wl = 'L' AND (player.player_name = @player 
																							  OR   player.player_name = @player1
																							  OR   player.player_name = @player2
																							  OR   player.player_name = @player3
																							  OR   player.player_name = @player4
																							  OR   player.player_name = @player5
																							  OR   player.player_name = @player6
																							  OR   player.player_name = @player7
																							  OR   player.player_name = @player8
																							  OR   player.player_name = @player9
																							  OR   player.player_name = @player10)
ORDER BY game.game_id DESC, player_game_log.wl DESC, MIN DESC, PTS DESC
GO



--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Procedure creations for all teams ranked by win percentage.
--One for east, west and league

---------------------------------------------------------------------------------
CREATE PROCEDURE east_rank
AS
SELECT team_wins.Team as "Eastern Conference", CONCAT(team_wins.Wins, '-', team_losses.Losses) as Record, CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct"
FROM team_wins INNER JOIN
	 team on team.team_id = team_wins.team_id INNER JOIN 
	 team_losses on team_wins.team_id = team_losses.team_id INNER JOIN
	 team_east on team_wins.team_id = team_east.team_id
	
ORDER BY CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') DESC
GO

---------------------------------------------------------------------------------
CREATE PROCEDURE west_rank
AS
SELECT team_wins.Team as "Western Conference", CONCAT(team_wins.Wins, '-', team_losses.Losses) as Record, CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct"
FROM team_wins INNER JOIN
	 team on team.team_id = team_wins.team_id INNER JOIN 
	 team_losses on team_wins.team_id = team_losses.team_id INNER JOIN
	 team_west on team_wins.team_id = team_west.team_id
	
ORDER BY CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') DESC
GO

---------------------------------------------------------------------------------
CREATE PROCEDURE rank
AS
SELECT team_wins.Team, CONCAT(team_wins.Wins, '-', team_losses.Losses) as Record, CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct"
FROM team_wins INNER JOIN
	 team on team.team_id = team_wins.team_id INNER JOIN 
	 team_losses on team_wins.team_id = team_losses.team_id INNER JOIN
	 team_east on team_wins.team_id = team_east.team_id
UNION

SELECT team_wins.Team, CONCAT(team_wins.Wins, '-', team_losses.Losses) as Record, CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct"

FROM team_wins INNER JOIN
	 team on team.team_id = team_wins.team_id INNER JOIN 
	 team_losses on team_wins.team_id = team_losses.team_id INNER JOIN
	 team_west on team_wins.team_id = team_west.team_id
	
ORDER BY CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') DESC
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
--Creates a stored procedure that returns the teams that played last night/today and who won
CREATE PROCEDURE yesterdaygames
AS
SELECT	CONCAT('(', team.abbreviation, ') ', team.city, ' ', team.nickname, '   vs.   ', '(', loserTeam.abbreviation, ') ', loserTeam.city, ' ', loserTeam.nickname) as Matchup, 
CONCAT(team.city, ' ',team_game_log.result, 'in') as Result,
CONCAT(team_game_log.score ,' - ', opteam_game_log.opscore) as Score

FROM game INNER JOIN
		team on game.team_id_winner = team.team_id JOIN
		team as loserTeam on game.team_id_loser = loserTeam.team_id INNER JOIN
		team_game_log on team.team_id = team_game_log.team_id and team_game_log.game_id = game.game_id AND team_game_log.opteam_id = loserTeam.team_id INNER JOIN
		opteam_game_log on loserTeam.team_id = opteam_game_log.opteam_id AND opteam_game_log.game_id = game.game_id


WHERE game.date = DATEADD(day, -1, CAST(GETDATE() AS DATE)) OR game.date = CAST(GETDATE() AS DATE)
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
CREATE PROCEDURE roster @team varchar(255)
as
SELECT     player.player_name AS Roster,
		   player_season.age as Age,
		   player_season.gp as GP,
		   ROUND(	SUM(player_game_log.min/player_season.gp),0) as MIN,
		   ROUND(player_season.pts/player_season.gp,1) as PTS,
		   ROUND(player_season.ast/player_season.gp,1) as AST,
		   ROUND(player_season.reb/player_season.gp,1) as REB,	   
		   ROUND(	SUM(player_game_log.plus_minus)/player_season.gp,1) as "+/-",
		   ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m)/player_season.gp,1)as "2FGM",		
		       
		   ROUND(	SUM(player_game_log.fga-player_game_log.fg3a)/player_season.gp,1) as "2FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m)/SUM(player_game_log.fga-player_game_log.fg3a)*100,1), '%')	as "2FG%",
		   ROUND(	SUM(player_game_log.ftm)/player_season.gp,1)as "FTA",
		   
		   ROUND(	SUM(player_game_log.fta)/player_season.gp,1) as "FTM",
		   CONCAT(	ROUND(	SUM(player_game_log.ftm)/SUM(player_game_log.fta) * 100, 1),'%') as "FT%",
		   ROUND(	SUM(player_game_log.fg3m)/player_season.gp,1) as "3FGM",
		   
		   ROUND(	SUM(player_game_log.fg3a)/player_season.gp,1) as "3FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fg3m)/SUM(player_game_log.fg3a) * 100, 1),'%') as "3FG%",
		   ROUND(	SUM(player_game_log.stl)/player_season.gp,1) as STL,
		   ROUND(	SUM(player_game_log.blk)/player_season.gp,1) as BLK,
		   ROUND(	SUM(player_game_log.tov)/player_season.gp,1) as TOV,
		   CONCAT(player_season.oreb_pct*100,'%') as "OREB%",
		   CONCAT( player_season.dreb_pct*100,'%') as "DREB%",
		   CONCAT(player_season.usg_pct*100,'%') as "USG%",
		   CONCAT(player_season.ts_pct*100,'%') as "TS%",
		   CONCAT(player_season.ast_pct*100,'%') as "AST%"



FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id INNER JOIN
						 team_season on team.team_id = team_season.team_id INNER JOIN
						 player_game_log on player_game_log.player_id = player.player_id
WHERE nickname = @team AND player_season.gp != 0 
GROUP BY player.player_name,
		   player_season.age,
		   
		   player_season.gp,
		   ROUND(player_season.pts/player_season.gp,1),
		   ROUND(player_season.ast/player_season.gp,1) ,
		   ROUND(player_season.reb/player_season.gp,1) ,
		   player_season.net_rating,
		   CONCAT(player_season.oreb_pct*100,'%'),
		   CONCAT( player_season.dreb_pct*100,'%'),
		   CONCAT(player_season.usg_pct*100,'%'),
		   CONCAT(player_season.ts_pct*100,'%'),
		   CONCAT(player_season.ast_pct*100,'%')
HAVING SUM(player_game_log.FTA) != 0		AND	SUM(player_game_log.fga)!= 0	AND SUM(player_game_log.fg3a) != 0		   	   
ORDER BY PTS DESC
GO
--################################################################################################################################################################################################################################--
CREATE PROCEDURE rosterseason @team varchar(255)
AS
SELECT     player.player_name AS Roster,
		   player_season.age as Age,
		   player_season.gp as GP,
		   ROUND(SUM(player_game_log.min),0) as MIN,
		   ROUND(SUM(player_game_log.pts),1) as PTS,
		   ROUND(SUM(player_game_log.ast),1) as AST,
		   ROUND(SUM(player_game_log.reb),1) as REB,	   
		   ROUND(	SUM(player_game_log.plus_minus),1) as "+/-",
		   ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m)/player_season.gp,1)as "2FGM",		
		       
		   ROUND(	SUM(player_game_log.fga-player_game_log.fg3a)/player_season.gp,1) as "2FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m)/SUM(player_game_log.fga-player_game_log.fg3a)*100,1), '%')	as "2FG%",
		   ROUND(	SUM(player_game_log.ftm)/player_season.gp,1)as "FTA",
		   
		   ROUND(	SUM(player_game_log.fta)/player_season.gp,1) as "FTM",
		   CONCAT(	ROUND(	SUM(player_game_log.ftm)/SUM(player_game_log.fta) * 100, 1),'%') as "FT%",
		   ROUND(	SUM(player_game_log.fg3m)/player_season.gp,1) as "3FGM",
		   
		   ROUND(	SUM(player_game_log.fg3a)/player_season.gp,1) as "3FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fg3m)/SUM(player_game_log.fg3a) * 100, 1),'%') as "3FG%",
		   ROUND(	SUM(player_game_log.stl),1) as STL,
		   ROUND(	SUM(player_game_log.blk),1) as BLK,
		   ROUND(	SUM(player_game_log.tov),1) as TOV,
		   CONCAT(player_season.oreb_pct*100,'%') as "OREB%",
		   CONCAT( player_season.dreb_pct*100,'%') as "DREB%",
		   CONCAT(player_season.usg_pct*100,'%') as "USG%",
		   CONCAT(player_season.ts_pct*100,'%') as "TS%",
		   CONCAT(player_season.ast_pct*100,'%') as "AST%",
		   SUM(player_game_log.dd2) as DD,
		   SUM(player_game_log.td3) as TD


FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id INNER JOIN
						 team_season on team.team_id = team_season.team_id INNER JOIN
						 player_game_log on player_game_log.player_id = player.player_id
WHERE nickname = @team AND player_season.gp != 0 
GROUP BY player.player_name,
		   player_season.age,
		   
		   player_season.gp,
		   ROUND(player_season.pts/player_season.gp,1),
		   ROUND(player_season.ast/player_season.gp,1) ,
		   ROUND(player_season.reb/player_season.gp,1) ,
		   player_season.net_rating,
		   CONCAT(player_season.oreb_pct*100,'%'),
		   CONCAT( player_season.dreb_pct*100,'%'),
		   CONCAT(player_season.usg_pct*100,'%'),
		   CONCAT(player_season.ts_pct*100,'%'),
		   CONCAT(player_season.ast_pct*100,'%')
HAVING SUM(player_game_log.FTA) != 0		AND	SUM(player_game_log.fga)!= 0	AND SUM(player_game_log.fg3a) != 0
ORDER BY PTS DESC
GO
--################################################################################################################################################################################################################################--
CREATE PROCEDURE rosterperminute @team varchar(255)
AS
SELECT     player.player_name AS Roster,
		   player_season.age as Age,
		   player_season.gp as GP,
		   ROUND(	SUM(player_game_log.min/player_season.gp),0) as MIN,
		   ROUND(ROUND(SUM(player_game_log.pts),2)/ROUND(SUM(player_game_log.min),2),2) as "PTS",
		   ROUND(ROUND(SUM(player_game_log.ast),2)/ROUND(SUM(player_game_log.min),2),2) as AST,
		   ROUND(ROUND(SUM(player_game_log.reb),2)/ROUND(SUM(player_game_log.min),2),2) as REB,	   
		   ROUND(ROUND(SUM(player_game_log.plus_minus),2)/ROUND(SUM(player_game_log.min),2),2) as "+/-",
		   ROUND(	ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m),1)/ROUND(SUM(player_game_log.min),2),2)  as "2FGM",
		   
		   ROUND(	ROUND(	SUM(player_game_log.fga-player_game_log.fg3a),1)/ROUND(SUM(player_game_log.min),2),2) as "2FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fgm-player_game_log.fg3m)/SUM(player_game_log.fga-player_game_log.fg3a)*100,1), '%')	as "2FG%",		   		   
		   ROUND(	ROUND(	SUM(player_game_log.ftm),1)/ROUND(SUM(player_game_log.min),2),2)as "FTM",
		   
		   ROUND(	ROUND(	SUM(player_game_log.fta),1)/ROUND(SUM(player_game_log.min),2),2) as "FTA",
		   CONCAT(	ROUND(	SUM(player_game_log.ftm)/SUM(player_game_log.fta) * 100, 1),'%') as "FT%",
		   ROUND(	ROUND(	SUM(player_game_log.fg3m),1)/ROUND(SUM(player_game_log.min),2),2) as "3FGM",
		   
		   ROUND(	ROUND(	SUM(player_game_log.fg3a),1)/ROUND(SUM(player_game_log.min),2),2) as "3FGA",
		   CONCAT(	ROUND(	SUM(player_game_log.fg3m)/SUM(player_game_log.fg3a) * 100, 1),'%') as "3FG%"


FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id INNER JOIN
						 team_season on team.team_id = team_season.team_id INNER JOIN
						 player_game_log on player_game_log.player_id = player.player_id
WHERE nickname = @team AND player_season.gp != 0 
GROUP BY player.player_name,
		   player_season.age,
		   
		   player_season.gp,
		   ROUND(player_season.pts/player_season.gp,1),
		   ROUND(player_season.ast/player_season.gp,1) ,
		   ROUND(player_season.reb/player_season.gp,1) ,
		   player_season.net_rating,
		   CONCAT(player_season.oreb_pct*100,'%'),
		   CONCAT( player_season.dreb_pct*100,'%'),
		   CONCAT(player_season.usg_pct*100,'%'),
		   CONCAT(player_season.ts_pct*100,'%'),
		   CONCAT(player_season.ast_pct*100,'%')
HAVING SUM(player_game_log.FTA) != 0		AND	SUM(player_game_log.fga)!= 0	AND SUM(player_game_log.fg3a) != 0
ORDER BY PTS DESC
GO

--################################################################################################################################################################################################################################--

CREATE PROCEDURE teampage @team varchar(255)
as
SELECT team.nickname,
[ppg] as PPG, 
ROUND(ppg-op_ppg,1) as "MoV",
[apg] as APG,
[rbpg] as RBPG,
[orbpg] as oRBPG,
[drbpg] as dRBPG,
team_season.fgm as FGM,
team_season.fga as FGA,
CONCAT(fgpct, '%') as "FG%",
team_season.fg3m as FG3M,
team_season.fg3a as FG3A,
CONCAT(fg3pct, '%') as "FG3%",
[op_ppg] as opPPG,
[opapg]	 as opAPG,
[oprbpg] as opRBPG,
[oporbpg] as opORBPG,
[opdrbpg] as opDRBPG,
team_season.opfgm as opFGM,
team_season.opfga as opFGA,
CONCAT(opfgpct, '%') as "opFG%",
team_season.opfg3m as opFG3M,
team_season.opfg3a as opFG3A,
CONCAT(opfg3pct, '%') as "opFG3%"

  FROM [nba].[dbo].[team_season] INNER JOIN team on team_season.team_id=team.team_id
  WHERE team.nickname = @team
  GO
--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
CREATE PROCEDURE teamspage
AS
SELECT   CONCAT('(',team.abbreviation, ')', team.city, ' ', team.nickname) AS Team,
team_wins.Wins as Wins,
team_losses.Losses as Losses,
CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct",
ROUND(team_season.ppg,1) as PPG,
ROUND(ROUND(team_season.ppg,1)-ROUND(team_season.op_ppg,1),1) as MoV, 
team_season.apg as APG, 
team_season.rbpg as RBPG,
team_season.orbpg as oRBPG, 
team_season.drbpg as dRBPG,  
team_season.fgm as FGM, 
team_season.fga as FGA,
CONCAT(team_season.fgpct, '%') as "FG%",
team_season.fgpct_rank as "FG% Rank",
team_season.ftm as FTM, 
team_season.fta as FTA,
CONCAT(team_season.ftpct, '%') as "FT%",
team_season.ftpct_rank as "FT% Rank",
team_season.fg3m as FG3M, 
team_season.fg3a as FG3A,
CONCAT(team_season.fg3pct, '%') as "FG3%",
team_season.fg3pct_rank as "FG3% Rank"
FROM   team INNER JOIN
						 team_season on team.team_id = team_season.team_id INNER JOIN
						 team_wins on team.team_id = team_wins.team_id INNER JOIN 
						 team_losses on team.team_id = team_losses.team_id
ORDER BY [Win Pct] DESC
GO

---------------------------------------------------------------------------------

CREATE PROCEDURE oTeamspage
AS
SELECT   CONCAT('(',team.abbreviation, ')', team.city, ' ', team.nickname) AS Team,
team_wins.Wins as Wins,
team_losses.Losses as Losses,
CONCAT(ROUND(CAST(Wins as float)/(CAST(Wins as float)+CAST(Losses as float))*100,1),'%') as "Win Pct", 
ROUND(team_season.op_ppg,1) as oPPG,
ROUND(ROUND(team_season.op_ppg,1)-ROUND(team_season.ppg,1),1) as oMoV, 
team_season.opapg as oAPG, 
team_season.oprbpg as oRBPG,
team_season.oporbpg as oORBPG, 
team_season.opdrbpg as oDRBPG,  
team_season.opfgm as oFGM, 
team_season.opfga as oFGA,
CONCAT(team_season.opfgpct, '%') as "oFG%",
team_season.opfgpct_rank as "oFG% Rank",
team_season.opftm as oFTM, 
team_season.opfta as oFTA,
CONCAT(team_season.opftpct, '%') as "oFT%",
team_season.opftpct_rank as "oFT% Rank",
team_season.opfg3m as oFG3M, 
team_season.opfg3a as oFG3A,
CONCAT(team_season.opfg3pct, '%') as "oFG3%",
team_season.opfg3pct_rank as "oFG3% Rank"
FROM   team INNER JOIN
						 team_season on team.team_id = team_season.team_id INNER JOIN
						 team_wins on team.team_id = team_wins.team_id INNER JOIN 
						 team_losses on team.team_id = team_losses.team_id
ORDER BY [Win Pct] DESC
GO

--################################################################################################################################################################################################################################--
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
-------------##########################################################################################################################################################################################################-------------
--################################################################################################################################################################################################################################--
CREATE PROCEDURE pelicans 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'Pelicans'
GO

CREATE PROCEDURE "76ers" 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = '76ers'
GO

CREATE PROCEDURE bucks 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'bucks'
GO

CREATE PROCEDURE cavaliers 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'Cavaliers'
GO

CREATE PROCEDURE celtics 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'celtics'
GO

CREATE PROCEDURE clippers 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'clippers'
GO

CREATE PROCEDURE grizzlies 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'grizzlies'
GO

CREATE PROCEDURE hawks 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'hawks'
GO

CREATE PROCEDURE heat 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'heat'
GO

CREATE PROCEDURE hornets 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'hornets'
GO

CREATE PROCEDURE jazz 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'jazz'
GO

CREATE PROCEDURE kings 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'kings'
GO

CREATE PROCEDURE knicks 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'knicks'
GO

CREATE PROCEDURE lakers 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'lakers'
GO

CREATE PROCEDURE magic 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'magic'
GO

CREATE PROCEDURE mavericks 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'mavericks'
GO

CREATE PROCEDURE nets 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'nets'
GO

CREATE PROCEDURE nuggets 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'nuggets'
GO

CREATE PROCEDURE pacers 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'pacers'
GO

CREATE PROCEDURE pistons 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'pistons'
GO

CREATE PROCEDURE raptors 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'raptors'
GO

CREATE PROCEDURE rockets 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'rockets'
GO

CREATE PROCEDURE spurs 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'spurs'
GO

CREATE PROCEDURE suns 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'suns'
GO

CREATE PROCEDURE thunder 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'thunder'
GO

CREATE PROCEDURE timberwolves 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'timberwolves'
GO

CREATE PROCEDURE trailblazers 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'trail blazers'
GO

CREATE PROCEDURE warriors 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'warriors'
GO

CREATE PROCEDURE wizards 
AS
SELECT player_name

FROM            player LEFT OUTER JOIN
                         player_season ON player.player_id = player_season.player_id LEFT OUTER JOIN
                         team ON player_season.team_id = team.team_id

where team.nickname = 'wizards'
GO