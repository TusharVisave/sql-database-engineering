"""
Script: generate_orders_seed.py
Purpose: Generates 10,000 realistic sample rows for the `orders` table in MySQL
         to benchmark Full Table Scans vs B-Tree Secondary Indexes.
Outputs: seeds/orders_seed.sql
"""

import random
from datetime import date, timedelta
from pathlib import Path

# Seed for reproducibility
random.seed(42)

FIRST_NAMES = [
    "Aarav", "Aditi", "Alex", "Amit", "Ananya", "Arjun", "Carlos", "David",
    "Deepak", "Elena", "Emma", "Fatima", "Grace", "Isha", "James", "John",
    "Kavita", "Liam", "Manish", "Michael", "Neha", "Nikhil", "Olivia", "Pooja",
    "Pradeep", "Priya", "Rahul", "Riya", "Rohan", "Sanjay", "Sarah", "Sneha",
    "Sophia", "Suresh", "Tanvi", "Tushar", "Vikram", "William", "Yash", "Zara"
]

LAST_NAMES = [
    "Agarwal", "Bansal", "Brown", "Choudhury", "Davis", "Deshmukh", "Garcia",
    "Gupta", "Iyer", "Jain", "Johnson", "Joshi", "Kapoor", "Khan", "Kumar",
    "Mehta", "Miller", "Nair", "Patel", "Rao", "Reddy", "Roy", "Sharma",
    "Singh", "Smith", "Taylor", "Verma", "Visave", "Williams", "Wilson"
]

STATUSES = ["COMPLETED", "PROCESSING", "SHIPPED", "PENDING", "CANCELLED", "REFUNDED"]
STATUS_WEIGHTS = [0.55, 0.15, 0.15, 0.08, 0.05, 0.02]

START_DATE = date(2025, 1, 1)
END_DATE = date(2026, 9, 25)
DATE_RANGE_DAYS = (END_DATE - START_DATE).days

TOTAL_ROWS = 10000
TOTAL_CUSTOMERS = 2000
BATCH_SIZE = 1000

# Pre-generate customer pool to simulate realistic repeat purchases
customers = []
for cid in range(1, TOTAL_CUSTOMERS + 1):
    fname = FIRST_NAMES[(cid * 7) % len(FIRST_NAMES)]
    lname = LAST_NAMES[(cid * 13) % len(LAST_NAMES)]
    cname = f"{fname} {lname}"
    cemail = f"customer{cid}@{fname.lower()}{lname.lower()}.org" if cid % 3 == 0 else f"customer{cid}@example.com"
    customers.append((cid, cname, cemail))

# Add a specific target customer for benchmarking
target_customer_id = 1542
target_customer = (
    target_customer_id,
    "Sophia Miller",
    "sophia.miller@example.com"
)
customers[target_customer_id - 1] = target_customer

output_path = Path(__file__).parent / "orders_seed.sql"

with open(output_path, "w", encoding="utf-8") as f:
    f.write("-- ============================================================\n")
    f.write("-- SEED DATA: 10,000 ORDERS BENCHMARK DATASET\n")
    f.write("-- Generated via seeds/generate_orders_seed.py\n")
    f.write("-- ============================================================\n\n")
    f.write("USE order_management;\n\n")
    f.write("SET FOREIGN_KEY_CHECKS = 0;\n")
    f.write("TRUNCATE TABLE orders;\n")
    f.write("SET FOREIGN_KEY_CHECKS = 1;\n\n")

    for batch_start in range(1, TOTAL_ROWS + 1, BATCH_SIZE):
        batch_end = min(batch_start + BATCH_SIZE - 1, TOTAL_ROWS)
        f.write(f"-- Inserting batch {batch_start} to {batch_end}\n")
        f.write("INSERT INTO orders (order_id, customer_id, customer_name, customer_email, order_amount, order_status, order_date)\nVALUES\n")

        row_strings = []
        for order_id in range(batch_start, batch_end + 1):
            # Target customer has exactly 5 orders scattered through the table
            if order_id in [142, 2890, 5432, 7810, 9654]:
                cid, cname, cemail = target_customer
            else:
                cid, cname, cemail = random.choice(customers)

            amount = round(random.uniform(10.00, 2500.00), 2)
            status = random.choices(STATUSES, weights=STATUS_WEIGHTS)[0]
            random_days = random.randint(0, DATE_RANGE_DAYS)
            order_date = START_DATE + timedelta(days=random_days)

            row_strings.append(
                f"    ({order_id}, {cid}, '{cname}', '{cemail}', {amount:.2f}, '{status}', '{order_date.isoformat()}')"
            )

        f.write(",\n".join(row_strings))
        f.write(";\n\n")

    f.write("-- Verify insertion count\n")
    f.write("SELECT COUNT(*) AS total_orders FROM orders;\n")

print(f"Successfully generated {TOTAL_ROWS} rows in {output_path}")
