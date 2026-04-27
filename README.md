# Restaurant Management System

This project is a database-driven Restaurant Management System built with MySQL and Python Flask.

## Main Features

- User login and role-based access control
- Customer management
- Table status management
- Menu and staff management
- Reservation management
- Order management
- Invoice generation and payment tracking
- Business reports
- System logs and audit logs

## Technologies Used

- Python Flask
- MySQL
- MySQL Workbench
- HTML, CSS, Bootstrap
- Jinja2 templates

## Project Structure

```text
restaurant-management-system/
├── app/
│   ├── app.py
│   ├── templates/
│   └── static/
├── sql/
├── requirements.txt
├── .env.example
└── README.md
```

## Setup and Run Instructions

### 1. Clone the repository

```bash
git clone https://github.com/your-username/restaurant-management-system.git
cd restaurant-management-system
```

Replace the repository URL with your actual GitHub repository link.

### 2. Create a virtual environment

```bash
python -m venv venv
```

Activate it on Windows CMD:

```bash
venv\Scripts\activate
```

Or on PowerShell:

```powershell
.\venv\Scripts\Activate.ps1
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Create the MySQL database

Open MySQL Workbench and run the SQL files in the `sql/` folder in this order:

```text
01_schema.sql
02_sample_data.sql
03_indexes.sql
04_views.sql
05_functions.sql
06_procedures.sql
07_triggers.sql
08_roles_security.sql
```

After running these scripts, the database `restaurant_db` should be created.

### 5. Configure environment variables

Create a `.env` file in the project root folder based on `.env.example`.

Example:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=restaurant_db
DB_PORT=3306
```

Do not upload `.env` to GitHub.

### 6. Run the Flask app

Go to the app folder:

```bash
cd app
```

Run the application:

```bash
python app.py
```

### 7. Open in browser

```text
http://127.0.0.1:5000
```

## Demo Accounts

```text
admin / admin123
cashier / cashier123
waiter / waiter123
```

## Basic Usage Flow

1. Log in using one of the demo accounts.
2. Use the Dashboard to view the system overview.
3. Manage customers, tables, menu, staff, reservations, orders, and invoices.
4. Generate reports and view system logs.

## Notes

- MySQL must be running before starting the Flask app.
- The `.env` file is required for database connection.
- Do not push `.env`, `venv/`, or full database backup files to GitHub.