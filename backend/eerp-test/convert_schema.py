#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Convert MySQL DDL files to H2-compatible schema-h2.sql."""
import os
import re
import glob

SOURCE_DIR = r"d:\prj\e-erp\表结构"
OUTPUT_FILE = r"d:\prj\erp\backend\eerp-test\src\test\resources\schema-h2.sql"


def convert(content: str) -> str:
    # 1. Remove backticks
    content = content.replace('`', '')

    # 2. Remove MySQL table options
    content = re.sub(r'\s*ENGINE\s*=\s*\w+', '', content, flags=re.I)
    content = re.sub(r'\s*DEFAULT\s+CHARSET\s*=\s*\w+', '', content, flags=re.I)
    content = re.sub(r'\s*CHARACTER\s+SET\s+\w+', '', content, flags=re.I)
    content = re.sub(r'\s*COLLATE\s*=?\s*\w+', '', content, flags=re.I)
    content = re.sub(r'\s*ROW_FORMAT\s*=\s*\w+', '', content, flags=re.I)
    content = re.sub(r'\s*AUTO_INCREMENT\s*=\s*\d+', '', content, flags=re.I)

    # 3. Remove column-level AUTO_INCREMENT
    content = re.sub(r'\s*AUTO_INCREMENT', '', content, flags=re.I)

    # 4. Remove ON UPDATE CURRENT_TIMESTAMP
    content = re.sub(r'\s*ON\s+UPDATE\s+CURRENT_TIMESTAMP', '', content, flags=re.I)

    # 5. Remove COMMENT 'xxx' and COMMENT='xxx' (column and table level)
    content = re.sub(r"\s*COMMENT\s*=?\s*'[^']*'", '', content, flags=re.I)

    # 6. Data type conversions
    content = re.sub(r'tinyint\s*\(\s*\d+\s*\)', 'SMALLINT', content, flags=re.I)
    content = re.sub(r'\btinyint\b', 'SMALLINT', content, flags=re.I)
    content = re.sub(r'smallint\s*\(\s*\d+\s*\)', 'SMALLINT', content, flags=re.I)
    content = re.sub(r'mediumint\s*\(\s*\d+\s*\)', 'INTEGER', content, flags=re.I)
    content = re.sub(r'\bmediumint\b', 'INTEGER', content, flags=re.I)
    content = re.sub(r'\bint\s*\(\s*\d+\s*\)', 'INTEGER', content, flags=re.I)
    content = re.sub(r'\bbigint\s*\(\s*\d+\s*\)', 'BIGINT', content, flags=re.I)
    content = re.sub(r'\bjson\b', 'CLOB', content, flags=re.I)
    content = re.sub(r'\blongtext\b', 'CLOB', content, flags=re.I)
    content = re.sub(r'\bmediumtext\b', 'CLOB', content, flags=re.I)
    content = re.sub(r'\btext\b', 'CLOB', content, flags=re.I)
    content = re.sub(r'\bdatetime\b', 'TIMESTAMP', content, flags=re.I)
    content = re.sub(r'\blongblob\b', 'BLOB', content, flags=re.I)
    content = re.sub(r'\bmediumblob\b', 'BLOB', content, flags=re.I)
    content = re.sub(r'\btinyblob\b', 'VARBINARY(255)', content, flags=re.I)

    # enum('a','b') -> VARCHAR(50)
    # Note: \b before enum prevents matching table names like meta_enum;
    # [ \t]* (not \s*) prevents matching across newlines (e.g. CREATE TABLE meta_enum (...)
    content = re.sub(r'\benum[ \t]*\([^)]*\)', 'VARCHAR(50)', content, flags=re.I)
    content = re.sub(r'\bset[ \t]*\([^)]*\)', 'VARCHAR(100)', content, flags=re.I)

    # double(N,M) -> DOUBLE, float(N,M) -> FLOAT
    content = re.sub(r'\bdouble\s*\(\s*\d+\s*,\s*\d+\s*\)', 'DOUBLE', content, flags=re.I)
    content = re.sub(r'\bfloat\s*\(\s*\d+\s*,\s*\d+\s*\)', 'FLOAT', content, flags=re.I)

    # 7. Remove USING BTREE / USING HASH
    content = re.sub(r'\s*USING\s+(BTREE|HASH)', '', content, flags=re.I)

    # 8. H2 uses a GLOBAL index namespace (unlike MySQL where index names are per-table).
    #    Duplicate index names like idx_bo_code across tables cause "Index already exists" errors.
    #    Fix: drop names from UNIQUE KEY name (cols) -> UNIQUE (cols), and remove regular KEY lines.
    # 8a. UNIQUE KEY name (cols) -> UNIQUE (cols)
    content = re.sub(r'UNIQUE\s+KEY\s+\w+\s*\(', 'UNIQUE (', content, flags=re.I)
    # 8b. Remove regular KEY index lines (NOT PRIMARY KEY, NOT UNIQUE KEY — those don't start with "KEY")
    content = re.sub(r'^[ \t]*KEY\s+\w+\s*\([^)]*\),?[ \t]*$', '', content, flags=re.MULTILINE | re.I)
    # 8c. Fix trailing comma before closing paren (left over from removed last KEY line;
    #     allow blank lines left by the removal)
    content = re.sub(r',[ \t]*\r?\n([ \t]*\r?\n)*[ \t]*\)', '\n)', content)

    # 9. Clean up multiple blank lines
    content = re.sub(r'(\r?\n){3,}', '\n\n', content)

    return content


def main():
    # Get SQL files in order (exclude 08 logistics and V1.1.0 seed)
    all_sql = sorted(glob.glob(os.path.join(SOURCE_DIR, '*.sql')))
    sql_files = [f for f in all_sql
                 if not os.path.basename(f).startswith('08')
                 and not os.path.basename(f).startswith('V1')]

    print(f"Found {len(sql_files)} SQL files to convert:")
    for f in sql_files:
        print(f"  - {os.path.basename(f)}")

    parts = []
    parts.append("-- ============================================================")
    parts.append("-- EERP H2 Test Schema (auto-converted from MySQL DDL)")
    parts.append("-- H2 MODE=MySQL; Snowflake ID (ASSIGN_ID), no AUTO_INCREMENT")
    parts.append("-- ============================================================")
    parts.append("")

    for f in sql_files:
        base = os.path.splitext(os.path.basename(f))[0]
        parts.append("-- ============================================================")
        parts.append(f"-- {base}")
        parts.append("-- ============================================================")
        parts.append("")

        with open(f, 'r', encoding='utf-8') as fh:
            content = fh.read()
        converted = convert(content)
        parts.append(converted)
        parts.append("")

    output = '\n'.join(parts)

    with open(OUTPUT_FILE, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(output)

    # Stats
    table_count = len(re.findall(r'CREATE\s+TABLE', output, re.I))
    file_size_kb = round(os.path.getsize(OUTPUT_FILE) / 1024, 1)
    print("")
    print(f"Schema file created: {OUTPUT_FILE}")
    print(f"Total CREATE TABLE statements: {table_count}")
    print(f"File size: {file_size_kb} KB")


if __name__ == '__main__':
    main()
