# Day 2 — Relationships, Foreign Keys and Constraints

## 1. Relationship Types

### One-to-One

One record is related to exactly one record.

Example:

Customer -> CustomerProfile

```text
Customer
   |
   | 1:1
   |
CustomerProfile