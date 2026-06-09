-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Races Table (Schedule)
CREATE TABLE IF NOT EXISTS races (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    event_name TEXT NOT NULL,
    country TEXT NOT NULL,
    location TEXT NOT NULL,
    circuit_name TEXT NOT NULL,
    date_fp1 TIMESTAMP WITH TIME ZONE,
    date_fp2 TIMESTAMP WITH TIME ZONE,
    date_fp3 TIMESTAMP WITH TIME ZONE,
    date_qualifying TIMESTAMP WITH TIME ZONE,
    date_sprint TIMESTAMP WITH TIME ZONE,
    date_race TIMESTAMP WITH TIME ZONE,
    event_format TEXT,
    gmt_offset TEXT,
    UNIQUE(year, round_number)
);

-- Driver Standings Table
CREATE TABLE IF NOT EXISTS driver_standings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    position INTEGER NOT NULL,
    driver_code TEXT NOT NULL,
    full_name TEXT NOT NULL,
    team TEXT NOT NULL,
    nationality TEXT NOT NULL,
    points NUMERIC NOT NULL,
    wins INTEGER NOT NULL,
    podiums INTEGER NOT NULL DEFAULT 0,
    UNIQUE(year, driver_code)
);

-- Constructor Standings Table
CREATE TABLE IF NOT EXISTS constructor_standings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    position INTEGER NOT NULL,
    team_name TEXT NOT NULL,
    nationality TEXT NOT NULL,
    points NUMERIC NOT NULL,
    wins INTEGER NOT NULL,
    UNIQUE(year, team_name)
);

-- Session Results Table (for Race/Sprint/Quali results)
CREATE TABLE IF NOT EXISTS session_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL, -- e.g., 'Race', 'Qualifying'
    position INTEGER,
    driver_code TEXT NOT NULL,
    full_name TEXT NOT NULL,
    team TEXT NOT NULL,
    team_color TEXT NOT NULL,
    grid_position INTEGER,
    status TEXT NOT NULL,
    points NUMERIC NOT NULL DEFAULT 0.0,
    fastest_lap_time NUMERIC, -- in MS
    finishing_time NUMERIC, -- in MS
    gap_to_leader NUMERIC, -- in MS
    UNIQUE(year, round_number, session_type, driver_code)
);

-- Laps Table
CREATE TABLE IF NOT EXISTS laps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    driver_code TEXT NOT NULL,
    team_color TEXT,
    lap_number INTEGER NOT NULL,
    lap_time_ms NUMERIC,
    sector1_ms NUMERIC,
    sector2_ms NUMERIC,
    sector3_ms NUMERIC,
    compound TEXT,
    tyre_life INTEGER,
    stint INTEGER,
    is_personal_best BOOLEAN,
    pit_in_time NUMERIC,
    pit_out_time NUMERIC,
    speed_i1 NUMERIC,
    speed_i2 NUMERIC,
    speed_fl NUMERIC,
    speed_st NUMERIC,
    track_status TEXT,
    UNIQUE(year, round_number, session_type, driver_code, lap_number)
);

-- Telemetry Table
CREATE TABLE IF NOT EXISTS telemetry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    driver_code TEXT NOT NULL,
    lap_time_ms NUMERIC,
    compound TEXT,
    telemetry_data JSONB NOT NULL,
    UNIQUE(year, round_number, session_type, driver_code)
);

-- Weather Table
CREATE TABLE IF NOT EXISTS weather (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    air_temp NUMERIC NOT NULL,
    track_temp NUMERIC NOT NULL,
    humidity NUMERIC NOT NULL,
    pressure NUMERIC NOT NULL,
    wind_speed NUMERIC NOT NULL,
    wind_direction INTEGER NOT NULL,
    rainfall BOOLEAN NOT NULL,
    UNIQUE(year, round_number, session_type, time)
);

-- Race Control Messages Table
CREATE TABLE IF NOT EXISTS race_control (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    lap_number INTEGER,
    category TEXT,
    message TEXT NOT NULL,
    flag TEXT,
    scope TEXT,
    driver_code TEXT,
    UNIQUE(year, round_number, session_type, time, message)
);

-- Track Status Table
CREATE TABLE IF NOT EXISTS track_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT NOT NULL,
    message TEXT NOT NULL,
    UNIQUE(year, round_number, session_type, time)
);

-- Circuit Info Table
CREATE TABLE IF NOT EXISTS circuit_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    corners JSONB NOT NULL,
    marshal_lights JSONB NOT NULL,
    marshal_sectors JSONB NOT NULL,
    rotation NUMERIC NOT NULL,
    UNIQUE(year, round_number)
);

-- Position Data Table
CREATE TABLE IF NOT EXISTS position_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year INTEGER NOT NULL,
    round_number INTEGER NOT NULL,
    session_type TEXT NOT NULL,
    driver_code TEXT NOT NULL,
    pos_data JSONB NOT NULL,
    UNIQUE(year, round_number, session_type, driver_code)
);
