import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector
from db_config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

# ---------------------------------
# DATABASE CONNECTION
# ---------------------------------
def get_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )

# ---------------------------------
# GENERIC CRUD FUNCTIONS
# ---------------------------------
def fetch_data(table_name):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM {table_name}")
    rows = cursor.fetchall()
    cols = [i[0] for i in cursor.description]
    conn.close()
    return cols, rows

def insert_record(table_name, values):
    conn = get_connection()
    cursor = conn.cursor()
    placeholders = ','.join(['%s'] * len(values))
    cursor.execute(f"INSERT INTO {table_name} VALUES ({placeholders})", values)
    conn.commit()
    conn.close()

def update_record(table_name, set_clause, condition, values):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(f"UPDATE {table_name} SET {set_clause} WHERE {condition}", values)
    conn.commit()
    conn.close()

def delete_record(table_name, key_field, key_value):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(f"DELETE FROM {table_name} WHERE {key_field}=%s", (key_value,))
    conn.commit()
    conn.close()

# ---------------------------------
# UI SETUP
# ---------------------------------
root = tk.Tk()
root.title("Election Management System")
root.geometry("1050x650")

notebook = ttk.Notebook(root)
notebook.pack(fill="both", expand=True)

# ---------------------------------
# HELPER FUNCTIONS
# ---------------------------------
def create_tab(title):
    tab = ttk.Frame(notebook)
    notebook.add(tab, text=title)
    return tab

def create_tree(tab):
    tree = ttk.Treeview(tab)
    tree.pack(fill='both', expand=True, pady=10)
    return tree

def add_crud_controls(tab, table_name, tree, load_func, key_field):
    form_frame = tk.Frame(tab)
    form_frame.pack(pady=5)

    tk.Label(form_frame, text="Values (comma separated):").grid(row=0, column=0)
    entry = tk.Entry(form_frame, width=70)
    entry.grid(row=0, column=1, padx=5)

    btn_frame = tk.Frame(tab)
    btn_frame.pack(pady=5)

    def add_data():
        values = entry.get().split(',')
        try:
            insert_record(table_name, values)
            messagebox.showinfo("Success", "Record added successfully!")
            load_func()
        except Exception as e:
            messagebox.showerror("Error", str(e))

    def update_data():
        selected = tree.selection()
        if not selected:
            messagebox.showwarning("Select", "Please select a record to update.")
            return
        key_val = tree.item(selected[0])['values'][0]
        cols, _ = fetch_data(table_name)
        set_clause = ', '.join([f"{col}=%s" for col in cols[1:]])
        values = entry.get().split(',')[1:] + [key_val]
        try:
            update_record(table_name, set_clause, f"{key_field}=%s", values)
            messagebox.showinfo("Success", "Record updated successfully!")
            load_func()
        except Exception as e:
            messagebox.showerror("Error", str(e))

    def delete_data():
        selected = tree.selection()
        if not selected:
            messagebox.showwarning("Select", "Please select a record to delete.")
            return
        key_val = tree.item(selected[0])['values'][0]
        try:
            delete_record(table_name, key_field, key_val)
            messagebox.showinfo("Deleted", "Record deleted successfully!")
            load_func()
        except Exception as e:
            messagebox.showerror("Error", str(e))

    tk.Button(btn_frame, text="➕ Add", bg="#4CAF50", fg="white", width=10, command=add_data).pack(side="left", padx=5)
    tk.Button(btn_frame, text="📝 Update", bg="#2196F3", fg="white", width=10, command=update_data).pack(side="left", padx=5)
    tk.Button(btn_frame, text="❌ Delete", bg="#f44336", fg="white", width=10, command=delete_data).pack(side="left", padx=5)
    tk.Button(btn_frame, text="🔄 Refresh", bg="#9C27B0", fg="white", width=10, command=load_func).pack(side="left", padx=5)

# ---------------------------------
# 1️⃣ VOTERS TAB
# ---------------------------------
voters_tab = create_tab("Voters")
voter_tree = create_tree(voters_tab)

def load_voters():
    cols, rows = fetch_data("Voters")
    voter_tree.delete(*voter_tree.get_children())
    voter_tree["columns"] = cols
    voter_tree["show"] = "headings"
    for col in cols:
        voter_tree.heading(col, text=col)
        voter_tree.column(col, width=130)
    for r in rows:
        voter_tree.insert('', 'end', values=r)

load_voters()
add_crud_controls(voters_tab, "Voters", voter_tree, load_voters, "VoterID")

# ---------------------------------
# 2️⃣ CANDIDATES TAB
# ---------------------------------
candidates_tab = create_tab("Candidates")
candidate_tree = create_tree(candidates_tab)

def load_candidates():
    cols, rows = fetch_data("Candidates")
    candidate_tree.delete(*candidate_tree.get_children())
    candidate_tree["columns"] = cols
    candidate_tree["show"] = "headings"
    for col in cols:
        candidate_tree.heading(col, text=col)
        candidate_tree.column(col, width=130)
    for r in rows:
        candidate_tree.insert('', 'end', values=r)

load_candidates()
add_crud_controls(candidates_tab, "Candidates", candidate_tree, load_candidates, "CandidateID")

# ---------------------------------
# 3️⃣ ELECTIONS TAB
# ---------------------------------
elections_tab = create_tab("Elections")
election_tree = create_tree(elections_tab)

def load_elections():
    cols, rows = fetch_data("Elections")
    election_tree.delete(*election_tree.get_children())
    election_tree["columns"] = cols
    election_tree["show"] = "headings"
    for col in cols:
        election_tree.heading(col, text=col)
        election_tree.column(col, width=130)
    for r in rows:
        election_tree.insert('', 'end', values=r)

load_elections()
add_crud_controls(elections_tab, "Elections", election_tree, load_elections, "ElectionID")

# ---------------------------------
# 4️⃣ VOTES TAB
# ---------------------------------
votes_tab = create_tab("Votes")
votes_tree = create_tree(votes_tab)

def load_votes():
    cols, rows = fetch_data("Votes")
    votes_tree.delete(*votes_tree.get_children())
    votes_tree["columns"] = cols
    votes_tree["show"] = "headings"
    for col in cols:
        votes_tree.heading(col, text=col)
        votes_tree.column(col, width=130)
    for r in rows:
        votes_tree.insert('', 'end', values=r)

load_votes()
add_crud_controls(votes_tab, "Votes", votes_tree, load_votes, "VoteID")

# ---------------------------------
# 5️⃣ RESULTS TAB
# ---------------------------------
results_tab = create_tab("Results")
results_tree = create_tree(results_tab)

def load_results():
    query = """
    SELECT Constituency, Year, Type, Winner, Party, VotesWon
    FROM (
        SELECT con.Name AS Constituency, e.Year, e.Type, c.Name AS Winner,
               c.Party, COUNT(v.VoteID) AS VotesWon,
               ROW_NUMBER() OVER(PARTITION BY con.ConstituencyID, e.ElectionID
                                 ORDER BY COUNT(v.VoteID) DESC) AS rn
        FROM Votes v
        JOIN Candidates c ON v.CandidateID = c.CandidateID
        JOIN Constituencies con ON c.ConstituencyID = con.ConstituencyID
        JOIN Elections e ON v.ElectionID = e.ElectionID
        GROUP BY con.Name, e.Year, e.Type, c.Name, c.Party, con.ConstituencyID, e.ElectionID
    ) winners
    WHERE rn = 1
    ORDER BY Year DESC, Constituency;
    """
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    rows = cursor.fetchall()
    cols = [desc[0] for desc in cursor.description]
    conn.close()

    results_tree.delete(*results_tree.get_children())
    results_tree["columns"] = cols
    results_tree["show"] = "headings"
    for col in cols:
        results_tree.heading(col, text=col)
        results_tree.column(col, width=150)
    for r in rows:
        results_tree.insert('', 'end', values=r)

load_results()

tk.Button(results_tab, text="🔄 Refresh Results", bg="#607D8B", fg="white",
          command=load_results).pack(pady=10)

# ---------------------------------
root.mainloop()