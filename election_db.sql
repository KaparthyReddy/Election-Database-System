-- ==============================
-- Election Database Schema + Data + Queries (cleaned)
-- ==============================

CREATE DATABASE IF NOT EXISTS PROJECT_1;
USE PROJECT_1;

-- Drop existing tables (to avoid conflicts when rerun)
DROP TABLE IF EXISTS Votes;
DROP TABLE IF EXISTS Candidates;
DROP TABLE IF EXISTS Voters;
DROP TABLE IF EXISTS Elections;
DROP TABLE IF EXISTS Constituencies;
DROP TABLE IF EXISTS Logs;

-- 1. Constituencies Table
CREATE TABLE Constituencies (
    ConstituencyID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL
);

-- 2. Voters Table
CREATE TABLE Voters (
    VoterID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Age INT CHECK (Age >= 18),
    ConstituencyID INT,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID)
);

-- 3. Candidates Table
CREATE TABLE Candidates (
    CandidateID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Party VARCHAR(100) NOT NULL,
    ConstituencyID INT,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID)
);

-- 4. Elections Table
CREATE TABLE Elections (
    ElectionID INT PRIMARY KEY AUTO_INCREMENT,
    Year INT NOT NULL,
    Type VARCHAR(50) NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL
);

-- 5. Votes Table
CREATE TABLE Votes (
    VoteID INT PRIMARY KEY AUTO_INCREMENT,
    Date DATE NOT NULL,
    VoterID INT,
    CandidateID INT,
    ElectionID INT,
    FOREIGN KEY (VoterID) REFERENCES Voters (VoterID),
    FOREIGN KEY (CandidateID) REFERENCES Candidates (CandidateID),
    FOREIGN KEY (ElectionID) REFERENCES Elections (ElectionID),
    UNIQUE (VoterID , ElectionID)
);

-- ===========================================
-- Insert Sample Data (explicit IDs still work with AUTO_INCREMENT)
-- ===========================================

-- Constituencies
INSERT INTO Constituencies (ConstituencyID, Name, State) VALUES
(1, 'Bangalore South', 'Karnataka'),
(2, 'Mumbai North', 'Maharashtra'),
(3, 'Chennai Central', 'Tamil Nadu')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), State = VALUES(State);

-- Voters
INSERT INTO Voters (VoterID, Name, Age, ConstituencyID) VALUES
(1, 'Ravi Kumar', 30, 1),
(2, 'Priya Sharma', 25, 1),
(3, 'Amit Desai', 45, 2),
(4, 'Sneha Iyer', 29, 3),
(5, 'Arjun Reddy', 34, 3)
ON DUPLICATE KEY UPDATE Name = VALUES(Name), Age = VALUES(Age), ConstituencyID = VALUES(ConstituencyID);

-- Candidates
INSERT INTO Candidates (CandidateID, Name, Party, ConstituencyID) VALUES
(1, 'Anil Mehta', 'Party A', 1),
(2, 'Kiran Rao', 'Party B', 1),
(3, 'Sunita Patil', 'Party A', 2),
(4, 'Rahul Khanna', 'Party B', 2),
(5, 'Deepa Nair', 'Party A', 3),
(6, 'Vikram Singh', 'Party B', 3)
ON DUPLICATE KEY UPDATE Name = VALUES(Name), Party = VALUES(Party), ConstituencyID = VALUES(ConstituencyID);

-- Elections
INSERT INTO Elections (ElectionID, Year, Type, StartDate, EndDate) VALUES
(1, 2024, 'Lok Sabha', '2024-04-10', '2024-04-20'),
(2, 2025, 'State Assembly', '2025-01-05', '2025-01-15')
ON DUPLICATE KEY UPDATE Year = VALUES(Year), Type = VALUES(Type), StartDate = VALUES(StartDate), EndDate = VALUES(EndDate);

-- Votes
INSERT INTO Votes (VoteID, Date, VoterID, CandidateID, ElectionID) VALUES
(1, '2024-04-11', 1, 1, 1),
(2, '2024-04-11', 2, 2, 1),
(3, '2024-04-12', 3, 3, 1),
(4, '2024-04-12', 4, 5, 1),
(5, '2024-04-13', 5, 6, 1)
ON DUPLICATE KEY UPDATE Date = VALUES(Date), VoterID = VALUES(VoterID), CandidateID = VALUES(CandidateID), ElectionID = VALUES(ElectionID);

-- ==============================
-- Useful Queries
-- ==============================

-- 1. Total votes per candidate
SELECT c.Name AS Candidate, c.Party, con.Name AS Constituency, COUNT(v.VoteID) AS TotalVotes
FROM Candidates c
LEFT JOIN Votes v ON c.CandidateID = v.CandidateID
LEFT JOIN Constituencies con ON c.ConstituencyID = con.ConstituencyID
GROUP BY c.CandidateID, c.Name, c.Party, con.Name
ORDER BY TotalVotes DESC;

-- 2. Voter list per constituency
SELECT v.VoterID, v.Name AS VoterName, v.Age, con.Name AS Constituency, con.State
FROM Voters v
JOIN Constituencies con ON v.ConstituencyID = con.ConstituencyID
ORDER BY con.Name, v.Name;

-- 3. Election results (winner per constituency)
WITH VoteCounts AS (
    SELECT con.Name AS Constituency, 
           e.Year, 
           e.Type,
           c.Name AS Winner, 
           c.Party, 
           COUNT(v.VoteID) AS VotesWon,
           con.ConstituencyID,
           e.ElectionID
    FROM Votes v
    JOIN Candidates c ON v.CandidateID = c.CandidateID
    JOIN Constituencies con ON c.ConstituencyID = con.ConstituencyID
    JOIN Elections e ON v.ElectionID = e.ElectionID
    GROUP BY con.Name, e.Year, e.Type, c.Name, c.Party, con.ConstituencyID, e.ElectionID
)
SELECT Constituency, Year, Type, Winner, Party, VotesWon
FROM VoteCounts vc
WHERE VotesWon = (
    SELECT MAX(VotesWon)
    FROM VoteCounts vc2
    WHERE vc2.ConstituencyID = vc.ConstituencyID 
      AND vc2.ElectionID = vc.ElectionID
)
ORDER BY Year DESC, Constituency;

-- ===========================================
-- ✅ Additional Constraints (Rubrics Required)
-- ===========================================

ALTER TABLE Elections
ADD CONSTRAINT chk_election_dates
CHECK (StartDate <= EndDate);


-- ===========================================
-- ✅ Performance Improvement (Indexes)
-- ===========================================

-- ✅ Performance Improvement (Indexes)
-- ===========================================

CREATE INDEX idx_voters_const
ON Voters (ConstituencyID);

CREATE INDEX idx_candidates_const
ON Candidates (ConstituencyID);

CREATE INDEX idx_votes_candidate
ON Votes (CandidateID);

CREATE INDEX idx_votes_election
ON Votes (ElectionID);

-- ===========================================
-- ✅ Logs Table (Required by Triggers)
-- ===========================================

CREATE TABLE IF NOT EXISTS Logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    EventDetail VARCHAR(255),
    EventTime DATETIME
);

-- ===========================================
-- ✅ Triggers for Validation + Audit Logging
-- ===========================================
DELIMITER //

-- Prevent voter from voting outside their constituency / validate existence
CREATE TRIGGER trg_vote_constituency
BEFORE INSERT ON Votes
FOR EACH ROW
BEGIN
    DECLARE v_const INT;
    DECLARE c_const INT;
    
    SELECT ConstituencyID INTO v_const
      FROM Voters WHERE VoterID = NEW.VoterID;
      
    SELECT ConstituencyID INTO c_const
      FROM Candidates WHERE CandidateID = NEW.CandidateID;
    
    -- ensure voter & candidate exist
    IF v_const IS NULL OR c_const IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Vote: Voter or Candidate not found!';
    END IF;
    
    -- ensure constituency matches
    IF v_const <> c_const THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Vote: Constituency mismatch!';
    END IF;
END //

-- Log new voting events
CREATE TRIGGER trg_vote_log
AFTER INSERT ON Votes
FOR EACH ROW
BEGIN
    INSERT INTO Logs(EventDetail, EventTime)
    VALUES (CONCAT('Vote Cast -> VoterID: ', NEW.VoterID,
                   ', CandidateID: ', NEW.CandidateID,
                   ', ElectionID: ', NEW.ElectionID),
                   NOW());
END //
DELIMITER ;

-- ===========================================
-- ✅ Views (Reporting & Data Hiding)
-- ===========================================

CREATE OR REPLACE VIEW VoterInfo AS
SELECT V.VoterID, V.Name AS VoterName, V.Age, 
       C.Name AS Constituency, C.State
FROM Voters V
JOIN Constituencies C ON V.ConstituencyID = C.ConstituencyID;

CREATE OR REPLACE VIEW CandidateVoteCount AS
SELECT C.CandidateID, C.Name AS Candidate,
       C.Party, COALESCE(COUNT(V.VoteID),0) AS Votes
FROM Candidates C
LEFT JOIN Votes V ON C.CandidateID = V.CandidateID
GROUP BY C.CandidateID, C.Name, C.Party;

-- ===========================================
-- ✅ Stored Procedures
-- ===========================================
DELIMITER //
CREATE PROCEDURE CastVote (
    IN p_VoterID INT,
    IN p_CandidateID INT,
    IN p_ElectionID INT
)
BEGIN
    -- Prevent multiple votes in same election
    IF EXISTS (SELECT 1 FROM Votes 
               WHERE VoterID = p_VoterID
               AND ElectionID = p_ElectionID)
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Voter Already Voted in this Election!';
    ELSE
        -- Proceed with valid vote; Date uses current date
        INSERT INTO Votes (VoteID, Date, VoterID, CandidateID, ElectionID)
        VALUES (NULL, CURDATE(), p_VoterID, p_CandidateID, p_ElectionID);
    END IF;
END //
DELIMITER ;

-- End of file