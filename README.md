# 🗳️ Election Database System

A simple **Election Management System** built using **MySQL** and **Python**.  
This project demonstrates how to use **stored procedures**, **triggers**, **views**, and **Python UI integration** for managing election operations.

---

## 📁 Project Structure
election_app/
├── db_config.py        # Handles MySQL connection setup
├── ui.py               # Python interface to interact with the database
└── election_db.sql     # Complete SQL schema with triggers, procedures & sample data

---

## ⚙️ Features

- 🧱 Database schema for constituencies, voters, candidates, elections & votes  
- 🚨 Triggers to prevent invalid votes and log voting actions  
- 🧮 Stored procedure `CastVote` to ensure a voter votes only once per election  
- 🪶 Views for easy reporting (VoterInfo, CandidateVoteCount)  
- 💻 Python integration for interactive use

---

## 🚀 Setup Instructions

### 1️⃣ Clone the repository
```bash
git clone https://github.com/KaparthyReddy/Election-Database-System.git
cd Election-Database-System/election_app

2️⃣ Import SQL file into MySQL

mysql -u root -p < election_db.sql

3️⃣ Configure Database Connection

Edit db_config.py:

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'YOUR_PASSWORD',
    'database': 'project_1'
}

4️⃣ Run the UI

python ui.py

🧠 Demonstration Ideas
	•	Try inserting a duplicate vote to see the trigger block it.
	•	Cast a new vote with the stored procedure:

CALL CastVote(6, 5, 1);

	•	Check the logs table to verify the event was recorded.

📄 License

This project is open-source under the MIT License.`
