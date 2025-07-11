-- Golf Tracker Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor to create the necessary tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Golf Rounds Table
CREATE TABLE golf_rounds (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    course_name TEXT NOT NULL,
    date DATE NOT NULL,
    total_score INTEGER NOT NULL,
    par INTEGER NOT NULL DEFAULT 72,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hole Scores Table
CREATE TABLE hole_scores (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    round_id UUID REFERENCES golf_rounds(id) ON DELETE CASCADE NOT NULL,
    hole_number INTEGER NOT NULL CHECK (hole_number >= 1 AND hole_number <= 18),
    par INTEGER NOT NULL CHECK (par >= 3 AND par <= 5),
    strokes INTEGER NOT NULL CHECK (strokes > 0),
    putts INTEGER CHECK (putts >= 0),
    fairway_hit BOOLEAN,
    green_in_regulation BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Golf Statistics Table
CREATE TABLE user_golf_stats (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    total_rounds INTEGER DEFAULT 0,
    average_score DECIMAL(5,2),
    best_score INTEGER,
    worst_score INTEGER,
    handicap_index DECIMAL(4,1),
    total_birdies INTEGER DEFAULT 0,
    total_eagles INTEGER DEFAULT 0,
    total_pars INTEGER DEFAULT 0,
    total_bogeys INTEGER DEFAULT 0,
    favorite_course TEXT,
    last_played_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Golf Courses Table (Optional - for future use)
CREATE TABLE golf_courses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    location TEXT,
    par INTEGER DEFAULT 72,
    holes INTEGER DEFAULT 18,
    rating DECIMAL(3,1),
    slope INTEGER,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_golf_rounds_user_id ON golf_rounds(user_id);
CREATE INDEX idx_golf_rounds_date ON golf_rounds(date DESC);
CREATE INDEX idx_hole_scores_round_id ON hole_scores(round_id);
CREATE INDEX idx_hole_scores_hole_number ON hole_scores(hole_number);

-- Row Level Security (RLS) Policies
-- Enable RLS on all tables
ALTER TABLE golf_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE hole_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_golf_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;

-- Golf Rounds Policies
CREATE POLICY "Users can view their own golf rounds" ON golf_rounds
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own golf rounds" ON golf_rounds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own golf rounds" ON golf_rounds
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own golf rounds" ON golf_rounds
    FOR DELETE USING (auth.uid() = user_id);

-- Hole Scores Policies
CREATE POLICY "Users can view hole scores for their rounds" ON hole_scores
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM golf_rounds 
            WHERE golf_rounds.id = hole_scores.round_id 
            AND golf_rounds.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert hole scores for their rounds" ON hole_scores
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM golf_rounds 
            WHERE golf_rounds.id = hole_scores.round_id 
            AND golf_rounds.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update hole scores for their rounds" ON hole_scores
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM golf_rounds 
            WHERE golf_rounds.id = hole_scores.round_id 
            AND golf_rounds.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete hole scores for their rounds" ON hole_scores
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM golf_rounds 
            WHERE golf_rounds.id = hole_scores.round_id 
            AND golf_rounds.user_id = auth.uid()
        )
    );

-- User Golf Stats Policies
CREATE POLICY "Users can view their own golf stats" ON user_golf_stats
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own golf stats" ON user_golf_stats
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own golf stats" ON user_golf_stats
    FOR UPDATE USING (auth.uid() = user_id);

-- Golf Courses Policies (public read access)
CREATE POLICY "Anyone can view golf courses" ON golf_courses
    FOR SELECT USING (true);

-- Functions to automatically update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_golf_rounds_updated_at 
    BEFORE UPDATE ON golf_rounds 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_golf_stats_updated_at 
    BEFORE UPDATE ON user_golf_stats 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate and update user statistics
CREATE OR REPLACE FUNCTION update_user_golf_statistics(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
    stats_record RECORD;
BEGIN
    -- Calculate statistics from golf_rounds
    SELECT 
        COUNT(*) as total_rounds,
        ROUND(AVG(total_score), 2) as avg_score,
        MIN(total_score) as best_score,
        MAX(total_score) as worst_score,
        MAX(date) as last_played,
        (
            SELECT course_name 
            FROM golf_rounds 
            WHERE user_id = user_uuid 
            GROUP BY course_name 
            ORDER BY COUNT(*) DESC 
            LIMIT 1
        ) as favorite_course
    INTO stats_record
    FROM golf_rounds 
    WHERE user_id = user_uuid;

    -- Upsert user statistics
    INSERT INTO user_golf_stats (
        user_id, 
        total_rounds, 
        average_score, 
        best_score, 
        worst_score, 
        favorite_course, 
        last_played_date,
        updated_at
    ) VALUES (
        user_uuid,
        COALESCE(stats_record.total_rounds, 0),
        stats_record.avg_score,
        stats_record.best_score,
        stats_record.worst_score,
        stats_record.favorite_course,
        stats_record.last_played,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_rounds = EXCLUDED.total_rounds,
        average_score = EXCLUDED.average_score,
        best_score = EXCLUDED.best_score,
        worst_score = EXCLUDED.worst_score,
        favorite_course = EXCLUDED.favorite_course,
        last_played_date = EXCLUDED.last_played_date,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update user statistics when rounds are added/updated/deleted
CREATE OR REPLACE FUNCTION trigger_update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM update_user_golf_statistics(OLD.user_id);
        RETURN OLD;
    ELSE
        PERFORM update_user_golf_statistics(NEW.user_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stats_on_round_change
    AFTER INSERT OR UPDATE OR DELETE ON golf_rounds
    FOR EACH ROW EXECUTE FUNCTION trigger_update_user_stats();

-- Insert some sample golf courses (optional)
INSERT INTO golf_courses (name, location, par, holes, rating, slope, description) VALUES
('Augusta National Golf Club', 'Augusta, Georgia', 72, 18, 76.2, 137, 'Home of the Masters Tournament'),
('Pebble Beach Golf Links', 'Pebble Beach, California', 72, 18, 75.0, 143, 'Iconic coastal course'),
('St. Andrews Old Course', 'St. Andrews, Scotland', 72, 18, 74.3, 129, 'The Home of Golf'),
('Pine Valley Golf Club', 'Pine Valley, New Jersey', 70, 18, 76.8, 152, 'Consistently ranked #1 in the world'),
('Oakmont Country Club', 'Oakmont, Pennsylvania', 71, 18, 77.5, 148, 'Known for its challenging rough and greens');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated; 