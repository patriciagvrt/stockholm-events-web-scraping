library(DBI)
library(RSQLite)

# Ok - let's say that we want to track international trade flows between countries and
# see how trade flow patterns relate to the size and types of countries involved
# We want to also check the modes of transportation used and whether these are 
# using fossil fuel and not.

# So let's think how we should structure this database! What are the entities?
# What are the relationships between entities?

# Entities:
# - countries! Each has a name, a region they belong to, a type of governance, population size. geo-coordinates. Primary key (country_id)
# - trade_flows: From and to (two foreign keys from_countries_id, to_countries_id), commodity (text?), value, weight, year, transport mode (i.e. ship, plane, horse and cart etc)

# Perhaps additional entities? In trade_flows, we have commodities as text. Perhaps have that as separate entity?
# - commodities: commodity_id (PK), name
# This would mean that 'commodity' in 'trade_flows' would be replaced with commodity_id (foreign key, pointing to table 'commodities')

# Transport types?
# - transport_mode : transport_mode_id (PK), name, fossil (1/0), wheelbased (1/0)
# That would then also remove ' transport_mode' (TEXT) from 'trade_flows', instead having transport_mode_id as FK

# Perhaps different governance forms later on?
# - governance_types : governance_type_id (PK), name (text), democratic (0/1)
# This means we remove the 'governance TEXT' from countries, instead having governance_type_id as a FK

# Perhaps regions as well? Or maybe keep them as short texts (EUR, NAM, CAM,SAM,AFR, ASI)

# Ok - I think I'm ready to create my trade data database!

con <- dbConnect(SQLite(), "data/tradedata.sqlite")

# Be strict about foreign keys
dbExecute(con, "PRAGMA foreign_keys = ON")

# What to create first? Well, trade flows have foreign keys to 'countries' so countries
# before 'trade_flows'. But hm, countries has foreign keys to governance_types.
# 'governance_types' has no foreign keys. So let's create that first

# Create governance_types first:
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS governance_types (
    governance_id  INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    democratic  INTEGER DEFAULT 1
  )
")

# Check if it is there:
dbListTables(con)

# Get even more info:
dbGetQuery(con, "PRAGMA table_info(governance_types)")
# yep, looks nice!

# Now, lets create the 'countries' table:
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS countries (
    country_id  INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    region      TEXT NOT NULL,
    population  INTEGER,
    lat_capital TEXT,
    long_capital  TEXT,
    governance_id INTEGER NOT NULL,
    FOREIGN KEY (governance_id) REFERENCES governance_types(governance_id)
  )
")

# Did it work?
dbGetQuery(con, "PRAGMA table_info(countries)")

# Ok - let's create 'trade_flows' now! Let's check above what kind of fields we would have here
# - From and to (two foreign keys from_countries_id, to_countries_id)
# - commodity
# - value, weight, year
# - transport type
# Ok, some issues here! the foreign keys to the countries database are fine: they point to countries_id
# But then we have transport_mode which should be its own table

# So we need to create that first:
# transport_mode_id (PK), name, fossil (1/0), wheelbased (1/0)
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS transport_modes (
    transport_mode_id   INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    fossil      INTEGER DEFAULT 0,
    wheelbased  INTEGER DEFAULT 0
  )
")

# Did it work?
dbGetQuery(con, "PRAGMA table_info(transport_modes)")
# Yep!

# And now we can create the 'trade_flows' table
# It should have references (foreign keys) to other tables
# Note that two of the foreign keys point to the same foreign table!
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS trade_flows (
    tradeflow_id   INTEGER PRIMARY KEY,
    from_country_id INTEGER NOT NULL,
    to_country_id   INTEGER NOT NULL,
    commodity       TEXT,
    value           INTEGER,
    weight          REAL,
    year            INTEGER NOT NULL,
    transport_mode_id INTEGER NOT NULL,
    FOREIGN KEY (from_country_id) REFERENCES countries(country_id),
    FOREIGN KEY (to_country_id) REFERENCES countries(country_id),
    FOREIGN KEY (transport_mode_id) REFERENCES transport_modes(transport_mode_id)
  )
")

# Check it out:
# Did it work?
dbGetQuery(con, "PRAGMA table_info(trade_flows)")
# Yep!

# Ok, the database is ready: we have the following tables:
dbListTables(con)
# trade_flows: relates to countries (twice), transport_modes
# countries: relates to governance_types
# governance_types: no foreign keys
# transport_modes: no foreign keys

# We can then start adding data to our database
# First, we should add data to governance_types and transport_modes

dbExecute(con, "
  INSERT INTO governance_types (name, democratic)
  VALUES ('Representative democracy', 1)
")

dbExecute(con, "
  INSERT INTO governance_types (name, democratic)
  VALUES ('Illiberal democracy', 0)
")

dbExecute(con, "
  INSERT INTO governance_types (name, democratic)
  VALUES ('Monarchy', 0)
")

# To do:
# Add countries (making them referring to the governance_types table)
# Add entries to the transport mode table
# Then: start adding trade flows, making sure that all foreign keys point to the right
# entries in the other tables!

# Will supplement with code to exemplify this
