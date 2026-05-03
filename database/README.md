# TB Health Watch — Database

PostgreSQL 14+ schema for the TB Health Watch application.

## Files

| File | Purpose |
|------|---------|
| `migrations/001_init.sql` | Forward-only migration — creates all tables, indexes, and views |
| `schema.sql` | Read-only reference copy of `001_init.sql` (do not apply separately) |
| `seed.sql` | Reference data (31 Surabaya kecamatan, 5 TB drugs) + one demo admin user |

## Applying the Migration

```bash
# 1. Run the migration
psql <connection_string> -f database/migrations/001_init.sql

# 2. Load seed data
psql <connection_string> -f database/seed.sql
```

Replace `<connection_string>` with your PostgreSQL DSN, e.g.:
`postgresql://user:password@localhost:5432/tbhealthwatch`

## Future Changes

- **Never** edit `001_init.sql` after it has been applied.
- Create a new numbered file for each change: `database/migrations/002_add_foo.sql`, `003_rename_bar.sql`, etc.
- `schema.sql` is updated to match the latest cumulative schema as a convenience reference.
