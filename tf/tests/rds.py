import psycopg2, os


AURORA_ENDPOINT="media-intake-aurora.cluster-cgdesizasqxm.us-east-1.rds.amazonaws.com"
AURORA_USER="appadmin"
AURORA_PASSWORD="v\u0026EC\u003ceIjarhn_-7Wm*9j"
AURORA_DB="appdb"

conn = psycopg2.connect(
    host=AURORA_ENDPOINT,
    user=AURORA_USER,
    password=AURORA_PASSWORD,
    dbname=AURORA_DB
)
cur = conn.cursor()
cur.execute("SELECT NOW();")
print(cur.fetchone())
cur.close()
conn.close()


# aws ssm start-session --target <instance-id>

