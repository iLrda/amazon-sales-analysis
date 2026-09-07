from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, URL, text


password = getpass("PostgreSQL password: ")

url = URL.create(
    drivername="postgresql+psycopg",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="postgres"
)

engine = create_engine(url)


with engine.connect() as connection:
    database = connection.execute(
        text("SELECT current_database();")
    ).scalar()

    print("Connected successfully!")
    print("Database:", database)


df = pd.read_sql(
    'SELECT * FROM public.amazon_sales LIMIT 5;',
    engine
)

print(df)