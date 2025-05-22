-- NOTE: THE DATA CLEANING CODE IS NOT ALL HERE. THIS IS MOSTLY
-- DATABASE CREATION, TABLE CREATION, SETTING KEYS, AND FINAL 
-- QUERYING FOR EXCEL. MOST OF THE DATA CLEANING CODE WAS DELETED OR
-- ALTERED AFTER SINGLE USE.


-- Creating database
CREATE DATABASE NBA_Data;

-- Moving to the database
USE NBA_Data;

-- Creating table with all games
CREATE TABLE games (
    game_id INT PRIMARY KEY, 
    game_date TIMESTAMP,
    home_city VARCHAR(30),
    home_team_name VARCHAR(30) NOT NULL,
    home_id INT NOT NULL,
    away_city VARCHAR(30),
    away_team_name VARCHAR(30) NOT NULL,
    away_id INT NOT NULL,
    home_score INT NOT NULL,
    away_score INT NOT NULL,
    winner INT NOT NULL,
    game_type VARCHAR(30),
    attendance INT,
    arena_id INT,
    game_label VARCHAR(30),
    game_sub_label VARCHAR(30),
    series_game_number INT
);

-- Creating table with all player game-by-game statistics
CREATE TABLE player_game_stats (
    first_name VARCHAR(20),
    last_name VARCHAR(30),
    player_id INT,
    game_id INT,
    game_date TIMESTAMP,
    player_team_city VARCHAR(30),
    player_team_name VARCHAR(30) NOT NULL,
    opponent_team_city VARCHAR(30),
    opponent_team_name VARCHAR(30),
    game_type VARCHAR(30),
    game_label VARCHAR(40),
    game_sub_label VARCHAR(20),
    series_game_number INT,
    win INT NOT NULL,
    home INT,
    min_played DECIMAL(4,2),
    points INT NOT NULL,
    assists INT,
    blocks INT,
    steals INT,
    fg_attempted INT,
    fg_made INT,
    fg_percentage DECIMAL(4,3),
    3p_attempted INT,
    3p_made INT,
    3p_percentage DECIMAL(4,3),
    ft_attempted INT,
    ft_made INT,
    ft_percentage DECIMAL(4,3),
    def_rebounds INT,
    off_rebounds INT,
    rebounds INT,
    fouls INT,
    turnovers INT,
    plus_minus INT,
    PRIMARY KEY (player_id,game_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id) 
);

--Deleting foreign key from player_game_stats because
--I forgot to add a command on delete
ALTER TABLE player_game_stats
DROP FOREIGN KEY player_game_stats_ibfk_1;

--Adding foreign key back to delete entry on deletion
ALTER TABLE player_game_stats
ADD CONSTRAINT player_game_stats_ibfk_1
FOREIGN KEY (game_id)
REFERENCES games(game_id)
ON DELETE CASCADE;


-- Creating table with all player information
CREATE TABLE players (
    player_id INT PRIMARY KEY,
    first_name VARCHAR(30),
    last_name VARCHAR(40),
    birth_date DATE NOT NULL,
    school VARCHAR(40),
    country VARCHAR(30),
    height INT,
    weight INT,
    guard VARCHAR(5),
    forward VARCHAR(5),
    center VARCHAR(5),
    draft_year INT,
    draft_round INT,
    draft_number INT
);

-- Creating table with all team specific game stats
CREATE TABLE team_game_stats (
    game_id INT,
    game_date TIMESTAMP,
    team_city VARCHAR(30),
    team_name VARCHAR(30),
    team_id INT,
    opp_team_city VARCHAR(30),
    opp_team_name VARCHAR(30),
    opp_team_id INT,
    home INT,
    win INT NOT NULL,
    team_score INT,
    opp_score INT,
    assists INT,
    blocks INT,
    steals INT,
    fg_attempted INT,
    fg_made INT,
    fg_percentage DECIMAL(4,3),
    3p_attempted INT,
    3p_made INT,
    3p_percentage DECIMAL(4,3),
    ft_attempted INT,
    ft_made INT,
    ft_percentage DECIMAL(4,3),
    def_rebounds INT,
    off_rebounds INT,
    rebounds INT,
    fouls INT,
    turnovers INT,
    plus_minus INT,
    minutes INT,
    q1_pts INT,
    q2_pts INT,
    q3_pts INT,
    q4_pts INT,
    bench_pts INT,
    larges_lead INT,
    biggest_run INT,
    lead_changes INT,
    fast_break_pts INT,
    pts_from_turnover INT,
    pts_in_paint INT,
    2nd_chance_pts INT,
    times_tied INT,
    timeouts_left INT,
    season_wins INT,
    season_losses INT,
    coach_id INT,
    PRIMARY KEY (game_id, team_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE
);


-- Adding foreign key of player ID to player game stats table
-- that references the players table
ALTER TABLE player_game_stats
ADD CONSTRAINT player_id
FOREIGN KEY (player_id) REFERENCES players(player_id)
ON DELETE CASCADE;

-- Code that I altered and used in the command line 
-- to import CSV files to the empty tables
LOAD DATA LOCAL INFILE '/Users/coltondifranco/Desktop/GitHub/NBA-Analysis/Games.csv'
INTO TABLE games
FIELDS TERMINATED BY ','       -- Fields are separated by commas.
ENCLOSED BY '"'                -- Fields may be enclosed by double quotes (optional).
LINES TERMINATED BY '\n'       -- Rows are separated by newlines.
IGNORE 1 LINES;               -- Ignore the first line (header).


-- Format used to find string entry inconsistencies
SELECT DISTINCT game_type
FROM games
ORDER BY home game_type;

-- Deleting players drafted before 2005
DELETE FROM players
WHERE draft_year < 2005;

-- Deleting players from player_game_stats table who
-- are not in the players information table
DELETE FROM player_game_stats
WHERE player_id NOT IN (SELECT player_id FROM players);

-- Creating table of average player stats by season
CREATE TABLE player_season_stats AS
SELECT
player_game_stats.player_id,
player_game_stats.first_name,
player_game_stats.last_name,
players.draft_year,
EXTRACT(YEAR FROM player_game_stats.game_date) AS season_year,
(EXTRACT(YEAR FROM player_game_stats.game_date) - players.draft_year) AS seasons_since_draft,
COUNT(*) AS games_played,
AVG(player_game_stats.points) AS avg_points,
AVG(player_game_stats.assists) AS avg_assists,
AVG(player_game_stats.rebounds) AS avg_rebounds,
AVG(player_game_stats.min_played) AS avg_min,
AVG(player_game_stats.blocks) AS avg_blocks,
AVG(player_game_stats.steals) AS avg_steals,
AVG(player_game_stats.fg_percentage) AS avg_fg_percentage,
AVG(player_game_stats.fg_attempted) AS avg_fg_attempted,
AVG(player_game_stats.fouls) AS avg_fouls,
AVG(player_game_stats.turnovers) AS avg_turnovers,
AVG(player_game_stats.plus_minus) AS avg_plus_minus
FROM player_game_stats
JOIN players ON player_game_stats.player_id = players.player_id
WHERE players.draft_year IS NOT NULL
GROUP BY player_game_stats.player_id, players.first_name, players.last_name, players.draft_year, EXTRACT(YEAR FROM player_game_stats.game_date)
ORDER BY player_game_stats.player_id, season_year;

-- Adding primary composite key to player_season_stats table
ALTER TABLE player_season_stats
ADD PRIMARY KEY (player_id, season_year);

-- Adding position columns to player_season_stats table
ALTER TABLE player_season_stats
ADD COLUMN guard VARCHAR(5),
ADD COLUMN forward VARCHAR(5),
ADD COLUMN center VARCHAR(5);

-- Adding position information into player_season_stats table
UPDATE player_season_stats
JOIN players ON player_season_stats.player_id = players.player_id
SET 
player_season_stats.guard = players.guard,
player_season_stats.forward = players.forward,
player_season_stats.center = players.center;

-- Changing positions from true/false to 1/0
UPDATE player_season_stats
SET guard = CASE guard
              WHEN 'True' THEN 1
              WHEN 'False' THEN 0
            END,
    forward = CASE forward
              WHEN 'True' THEN 1
              WHEN 'False' THEN 0
            END,
    center = CASE center
              WHEN 'True' THEN 1
              WHEN 'False' THEN 0
            END;

-- Number of players vs season since they were drafted for all positions
SELECT 
  seasons_since_draft, 
  COUNT(*) AS num_players,
  SUM(CASE WHEN guard = 1 THEN 1 ELSE 0 END) AS num_guards,
  SUM(CASE WHEN forward = 1 THEN 1 ELSE 0 END) AS num_forwards,
  SUM(CASE WHEN center = 1 THEN 1 ELSE 0 END) AS num_centers
FROM player_season_stats
GROUP BY seasons_since_draft
ORDER BY seasons_since_draft;


-- Average stats by season since draft
SELECT 
  seasons_since_draft,
  COUNT(*) AS num_players,
  AVG(avg_points) AS avg_points,
  AVG(avg_assists) AS avg_assists,
  AVG(avg_rebounds) AS avg_rebounds,
  AVG(avg_min) AS avg_minutes,
  AVG(games_played) AS avg_games,
  AVG(avg_fg_percentage) AS avg_fg_percentage,
  AVG(avg_fouls) AS avg_fouls
FROM player_season_stats
GROUP BY seasons_since_draft
ORDER BY seasons_since_draft;


-- Stats per position by season
SELECT
  seasons_since_draft,

  -- Guards averages
  AVG(CASE WHEN guard = 1 THEN avg_points ELSE NULL END) AS guard_avg_points,
  AVG(CASE WHEN guard = 1 THEN avg_assists ELSE NULL END) AS guard_avg_assists,
  AVG(CASE WHEN guard = 1 THEN avg_rebounds ELSE NULL END) AS guard_avg_rebounds,
  AVG(CASE WHEN guard = 1 THEN avg_min ELSE NULL END) AS guard_avg_min,
  AVG(CASE WHEN guard = 1 THEN games_played ELSE NULL END) AS guard_avg_games_played,


  -- Forwards averages
  AVG(CASE WHEN forward = 1 THEN avg_points ELSE NULL END) AS forward_avg_points,
  AVG(CASE WHEN forward = 1 THEN avg_assists ELSE NULL END) AS forward_avg_assists,
  AVG(CASE WHEN forward = 1 THEN avg_rebounds ELSE NULL END) AS forward_avg_rebounds,
  AVG(CASE WHEN forward = 1 THEN avg_min ELSE NULL END) AS forward_avg_min,
  AVG(CASE WHEN forward = 1 THEN games_played ELSE NULL END) AS forward_avg_games_played,


  -- Centers averages
  AVG(CASE WHEN center = 1 THEN avg_points ELSE NULL END) AS center_avg_points,
  AVG(CASE WHEN center = 1 THEN avg_assists ELSE NULL END) AS center_avg_assists,
  AVG(CASE WHEN center = 1 THEN avg_rebounds ELSE NULL END) AS center_avg_rebounds,
  AVG(CASE WHEN center = 1 THEN avg_min ELSE NULL END) AS center_avg_min,
  AVG(CASE WHEN center = 1 THEN games_played ELSE NULL END) AS center_avg_games_played


FROM player_season_stats
GROUP BY seasons_since_draft
ORDER BY seasons_since_draft;

