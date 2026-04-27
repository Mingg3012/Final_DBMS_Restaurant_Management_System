from db import get_connection

try:
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT DATABASE();")
    result = cursor.fetchone()

    print("Connected successfully!")
    print("Current database:", result[0])

    cursor.close()
    conn.close()

except Exception as e:
    print("Connection failed!")
    print(e)