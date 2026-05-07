import fs from "node:fs/promises";
import path from "node:path";
import { createWriteStream } from "node:fs";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);

const toolRoot = path.resolve(".supabase-export-tools/node_modules");
const { Client } = require(path.join(toolRoot, "pg"));
const Cursor = require(path.join(toolRoot, "pg-cursor"));

const now = new Date();
const timestamp = now
  .toISOString()
  .replace(/[-:]/g, "")
  .replace(/\..+/, "")
  .replace("T", "-");

const projectRef = process.env.SUPABASE_PROJECT_REF ?? "unknown-project";
const outputRoot =
  process.env.SUPABASE_EXPORT_DIR ??
  path.resolve("exports", `supabase-${projectRef}-${timestamp}`);

const connection = {
  host: requiredEnv("SUPABASE_DB_HOST"),
  port: Number(process.env.SUPABASE_DB_PORT ?? "5432"),
  database: process.env.SUPABASE_DB_NAME ?? "postgres",
  user: requiredEnv("SUPABASE_DB_USER"),
  password: requiredEnv("SUPABASE_DB_PASSWORD"),
  ssl: process.env.SUPABASE_DB_SSL === "false" ? false : { rejectUnauthorized: false },
};

const systemSchemaPatterns = [
  /^pg_/,
  /^information_schema$/,
  /^pg_toast$/,
  /^pg_temp_/,
];

const client = new Client(connection);

await main().catch(async (error) => {
  console.error(error?.stack ?? error);
  try {
    await client.end();
  } catch {
    // Ignore shutdown failures.
  }
  process.exitCode = 1;
});

async function main() {
  await ensureFolders();
  await client.connect();

  const metadata = {};
  metadata.exportedAt = now.toISOString();
  metadata.projectRef = projectRef;
  metadata.connection = {
    host: connection.host,
    port: connection.port,
    database: connection.database,
    user: connection.user,
    ssl: Boolean(connection.ssl),
  };

  metadata.database = await one(`
    select
      current_database() as database_name,
      current_user as current_user,
      version() as version
  `);

  metadata.schemas = await query(`
    select
      n.nspname as schema_name,
      obj_description(n.oid, 'pg_namespace') as comment
    from pg_namespace n
    where n.nspname !~ '^pg_' and n.nspname <> 'information_schema'
    order by n.nspname
  `);

  metadata.extensions = await query(`
    select
      e.extname as name,
      e.extversion as version,
      n.nspname as schema_name
    from pg_extension e
    join pg_namespace n on n.oid = e.extnamespace
    order by e.extname
  `);

  metadata.enums = await query(`
    select
      ns.nspname as schema_name,
      t.typname as enum_name,
      array_agg(e.enumlabel order by e.enumsortorder) as values
    from pg_type t
    join pg_namespace ns on ns.oid = t.typnamespace
    join pg_enum e on e.enumtypid = t.oid
    where ns.nspname !~ '^pg_' and ns.nspname <> 'information_schema'
    group by ns.nspname, t.typname
    order by ns.nspname, t.typname
  `);

  metadata.tables = await query(`
    select
      n.nspname as schema_name,
      c.relname as table_name,
      case c.relkind
        when 'r' then 'table'
        when 'p' then 'partitioned table'
        when 'v' then 'view'
        when 'm' then 'materialized view'
        when 'f' then 'foreign table'
        when 'S' then 'sequence'
        else c.relkind::text
      end as object_type,
      c.relkind,
      c.relrowsecurity as row_level_security,
      c.relforcerowsecurity as force_row_level_security,
      obj_description(c.oid, 'pg_class') as comment
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relkind in ('r','p','v','m','f','S')
      and n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, c.relkind, c.relname
  `);

  metadata.columns = await query(`
    select
      n.nspname as schema_name,
      c.relname as table_name,
      a.attnum as ordinal_position,
      a.attname as column_name,
      pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type,
      a.attnotnull as not_null,
      a.attidentity as identity_kind,
      a.attgenerated as generated_kind,
      pg_get_expr(ad.adbin, ad.adrelid) as column_default,
      col_description(c.oid, a.attnum) as comment
    from pg_attribute a
    join pg_class c on c.oid = a.attrelid
    join pg_namespace n on n.oid = c.relnamespace
    left join pg_attrdef ad on ad.adrelid = c.oid and ad.adnum = a.attnum
    where a.attnum > 0
      and not a.attisdropped
      and c.relkind in ('r','p','v','m','f')
      and n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, c.relname, a.attnum
  `);

  metadata.constraints = await query(`
    select
      n.nspname as schema_name,
      c.relname as table_name,
      con.conname as constraint_name,
      con.contype as constraint_type,
      pg_get_constraintdef(con.oid, true) as definition
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, c.relname, con.contype, con.conname
  `);

  metadata.indexes = await query(`
    select
      schemaname as schema_name,
      tablename as table_name,
      indexname as index_name,
      indexdef as definition
    from pg_indexes
    where schemaname !~ '^pg_'
      and schemaname <> 'information_schema'
    order by schemaname, tablename, indexname
  `);

  metadata.triggers = await query(`
    select
      n.nspname as schema_name,
      c.relname as table_name,
      t.tgname as trigger_name,
      pg_get_triggerdef(t.oid, true) as definition
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where not t.tgisinternal
      and n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, c.relname, t.tgname
  `);

  metadata.policies = await query(`
    select
      schemaname as schema_name,
      tablename as table_name,
      policyname as policy_name,
      permissive,
      roles,
      cmd,
      qual,
      with_check
    from pg_policies
    where schemaname !~ '^pg_'
      and schemaname <> 'information_schema'
    order by schemaname, tablename, policyname
  `);

  metadata.functions = await query(`
    select
      n.nspname as schema_name,
      p.proname as function_name,
      pg_get_function_identity_arguments(p.oid) as identity_arguments,
      pg_get_function_result(p.oid) as result_type,
      l.lanname as language,
      p.prokind as kind,
      p.prosecdef as security_definer,
      pg_get_functiondef(p.oid) as definition
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    join pg_language l on l.oid = p.prolang
    where n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, p.proname, pg_get_function_identity_arguments(p.oid)
  `);

  metadata.views = await query(`
    select
      n.nspname as schema_name,
      c.relname as view_name,
      c.relkind,
      pg_get_viewdef(c.oid, true) as definition
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where c.relkind in ('v','m')
      and n.nspname !~ '^pg_'
      and n.nspname <> 'information_schema'
    order by n.nspname, c.relname
  `);

  metadata.sequences = await query(`
    select
      sequence_schema as schema_name,
      sequence_name,
      data_type,
      start_value,
      minimum_value,
      maximum_value,
      increment
    from information_schema.sequences
    where sequence_schema !~ '^pg_'
      and sequence_schema <> 'information_schema'
    order by sequence_schema, sequence_name
  `);

  metadata.tableGrants = await query(`
    select
      table_schema as schema_name,
      table_name,
      grantee,
      privilege_type,
      is_grantable
    from information_schema.role_table_grants
    where table_schema !~ '^pg_'
      and table_schema <> 'information_schema'
    order by table_schema, table_name, grantee, privilege_type
  `);

  metadata.roles = await safeQuery(`
    select
      rolname as role_name,
      rolsuper,
      rolinherit,
      rolcreaterole,
      rolcreatedb,
      rolcanlogin,
      rolreplication,
      rolbypassrls
    from pg_roles
    order by rolname
  `);

  metadata.publications = await safeQuery(`
    select
      pubname as publication_name,
      pubowner::regrole::text as owner,
      puballtables as all_tables,
      pubinsert,
      pubupdate,
      pubdelete,
      pubtruncate
    from pg_publication
    order by pubname
  `);

  metadata.dataExport = await exportTableData(metadata.tables);

  await writeJson("metadata/database_metadata.json", metadata);
  await writeJson("metadata/data_summary.json", metadata.dataExport);
  await writeSqlFiles(metadata);
  await writeMarkdownOverview(metadata);

  await client.end();

  console.log(`Export complete: ${outputRoot}`);
  console.log(`Tables exported: ${metadata.dataExport.tables.length}`);
  console.log(`Rows exported: ${metadata.dataExport.totalRowsExported}`);
}

async function exportTableData(tables) {
  const dataTables = tables.filter(
    (table) => table.relkind === "r" || table.relkind === "p",
  );
  const summary = {
    format: "JSON Lines; one row JSON object per line",
    generatedAt: new Date().toISOString(),
    tables: [],
    totalRowsExported: 0,
  };

  for (const table of dataTables) {
    const qualified = quoteIdent(table.schema_name, table.table_name);
    const fileBase = safeFileName(`${table.schema_name}.${table.table_name}`);
    const relativePath = `data/${fileBase}.jsonl`;
    const absolutePath = path.join(outputRoot, relativePath);
    const item = {
      schemaName: table.schema_name,
      tableName: table.table_name,
      file: relativePath,
      rowsExported: 0,
      error: null,
    };

    try {
      await fs.mkdir(path.dirname(absolutePath), { recursive: true });
      const out = createWriteStream(absolutePath, { encoding: "utf8" });
      const cursor = client.query(
        new Cursor(`select row_to_json(t) as row from ${qualified} as t`),
      );

      while (true) {
        const rows = await cursorRead(cursor, 500);
        if (rows.length === 0) {
          break;
        }
        for (const row of rows) {
          out.write(`${JSON.stringify(row.row)}\n`);
        }
        item.rowsExported += rows.length;
      }

      await cursorClose(cursor);
      await new Promise((resolve, reject) => {
        out.end(resolve);
        out.on("error", reject);
      });
    } catch (error) {
      item.error = error.message;
      await fs.writeFile(
        absolutePath,
        JSON.stringify({ error: error.message }, null, 2),
        "utf8",
      );
    }

    summary.totalRowsExported += item.rowsExported;
    summary.tables.push(item);
    console.log(
      `${item.error ? "WARN" : "OK"} ${table.schema_name}.${table.table_name}: ${item.rowsExported} rows`,
    );
  }

  return summary;
}

async function writeSqlFiles(metadata) {
  const enumsSql = metadata.enums
    .map((item) => {
      const values = item.values.map((value) => quoteLiteral(value)).join(", ");
      return `create type ${quoteIdent(item.schema_name, item.enum_name)} as enum (${values});`;
    })
    .join("\n\n");

  const extensionsSql = metadata.extensions
    .map(
      (item) =>
        `create extension if not exists ${quoteIdentifier(item.name)} with schema ${quoteIdentifier(item.schema_name)};`,
    )
    .join("\n");

  const functionsSql = metadata.functions
    .map((item) => `${item.definition.trim()};`)
    .join("\n\n");

  const viewsSql = metadata.views
    .map((item) => {
      const kind = item.relkind === "m" ? "materialized view" : "view";
      return `create or replace ${kind} ${quoteIdent(item.schema_name, item.view_name)} as\n${item.definition};`;
    })
    .join("\n\n");

  const tablesSql = buildTablesSql(metadata);
  const indexesSql = metadata.indexes
    .map((item) => `${item.definition};`)
    .join("\n");
  const triggersSql = metadata.triggers
    .map((item) => `${item.definition};`)
    .join("\n");
  const policiesSql = buildPoliciesSql(metadata);

  await writeText("sql/extensions.sql", `${extensionsSql}\n`);
  await writeText("sql/enums.sql", `${enumsSql}\n`);
  await writeText("sql/tables_and_constraints.sql", `${tablesSql}\n`);
  await writeText("sql/indexes.sql", `${indexesSql}\n`);
  await writeText("sql/functions.sql", `${functionsSql}\n`);
  await writeText("sql/views.sql", `${viewsSql}\n`);
  await writeText("sql/triggers.sql", `${triggersSql}\n`);
  await writeText("sql/policies.sql", `${policiesSql}\n`);
  await writeText(
    "sql/schema_reconstruction.sql",
    [
      "-- Best-effort schema reconstruction generated from PostgreSQL catalogs.",
      "-- Use pg_dump for production-grade restore scripts when available.",
      extensionsSql,
      enumsSql,
      tablesSql,
      indexesSql,
      functionsSql,
      viewsSql,
      triggersSql,
      policiesSql,
      "",
    ].join("\n\n"),
  );
}

function buildTablesSql(metadata) {
  const tableObjects = metadata.tables.filter(
    (item) => item.relkind === "r" || item.relkind === "p",
  );
  const byTable = groupBy(
    metadata.columns.filter((column) =>
      tableObjects.some(
        (table) =>
          table.schema_name === column.schema_name &&
          table.table_name === column.table_name,
      ),
    ),
    (column) => `${column.schema_name}.${column.table_name}`,
  );
  const constraintsByTable = groupBy(
    metadata.constraints,
    (constraint) => `${constraint.schema_name}.${constraint.table_name}`,
  );

  const statements = [];
  for (const schema of metadata.schemas) {
    statements.push(`create schema if not exists ${quoteIdentifier(schema.schema_name)};`);
  }

  for (const table of tableObjects) {
    const key = `${table.schema_name}.${table.table_name}`;
    const columns = byTable.get(key) ?? [];
    const columnLines = columns.map((column) => {
      const parts = [quoteIdentifier(column.column_name), column.data_type];
      if (column.identity_kind && column.identity_kind !== "") {
        parts.push(column.identity_kind === "a" ? "generated always as identity" : "generated by default as identity");
      } else if (column.column_default) {
        parts.push(`default ${column.column_default}`);
      }
      if (column.not_null) {
        parts.push("not null");
      }
      return `  ${parts.join(" ")}`;
    });
    statements.push(
      `create table if not exists ${quoteIdent(table.schema_name, table.table_name)} (\n${columnLines.join(",\n")}\n);`,
    );

    for (const constraint of constraintsByTable.get(key) ?? []) {
      statements.push(
        `alter table ${quoteIdent(table.schema_name, table.table_name)} add constraint ${quoteIdentifier(constraint.constraint_name)} ${constraint.definition};`,
      );
    }

    if (table.row_level_security) {
      statements.push(`alter table ${quoteIdent(table.schema_name, table.table_name)} enable row level security;`);
    }
    if (table.force_row_level_security) {
      statements.push(`alter table ${quoteIdent(table.schema_name, table.table_name)} force row level security;`);
    }
  }

  return statements.join("\n\n");
}

function buildPoliciesSql(metadata) {
  return metadata.policies
    .map((policy) => {
      const roles = Array.isArray(policy.roles) ? policy.roles.join(", ") : policy.roles;
      const using = policy.qual ? ` using (${policy.qual})` : "";
      const check = policy.with_check ? ` with check (${policy.with_check})` : "";
      return `create policy ${quoteIdentifier(policy.policy_name)} on ${quoteIdent(policy.schema_name, policy.table_name)} as ${policy.permissive} for ${policy.cmd} to ${roles}${using}${check};`;
    })
    .join("\n");
}

async function writeMarkdownOverview(metadata) {
  const lines = [];
  lines.push(`# Supabase Export: ${metadata.projectRef}`);
  lines.push("");
  lines.push(`Exported at: ${metadata.exportedAt}`);
  lines.push("");
  lines.push("## Database");
  lines.push("");
  lines.push(`- Database: \`${metadata.database.database_name}\``);
  lines.push(`- User: \`${metadata.database.current_user}\``);
  lines.push(`- Host: \`${metadata.connection.host}:${metadata.connection.port}\``);
  lines.push("");
  lines.push("## Counts");
  lines.push("");
  lines.push(`- Schemas: ${metadata.schemas.length}`);
  lines.push(`- Tables/views/sequences: ${metadata.tables.length}`);
  lines.push(`- Columns: ${metadata.columns.length}`);
  lines.push(`- Constraints: ${metadata.constraints.length}`);
  lines.push(`- Indexes: ${metadata.indexes.length}`);
  lines.push(`- Triggers: ${metadata.triggers.length}`);
  lines.push(`- Policies: ${metadata.policies.length}`);
  lines.push(`- Functions: ${metadata.functions.length}`);
  lines.push(`- Rows exported: ${metadata.dataExport.totalRowsExported}`);
  lines.push("");
  lines.push("## Schemas");
  lines.push("");
  for (const schema of metadata.schemas) {
    lines.push(`- \`${schema.schema_name}\`${schema.comment ? ` - ${schema.comment}` : ""}`);
  }
  lines.push("");
  lines.push("## Tables And Views");
  lines.push("");
  lines.push("| Schema | Name | Type | RLS | Rows Exported |");
  lines.push("|---|---|---|---:|---:|");
  for (const table of metadata.tables) {
    const data = metadata.dataExport.tables.find(
      (item) =>
        item.schemaName === table.schema_name && item.tableName === table.table_name,
    );
    lines.push(
      `| \`${table.schema_name}\` | \`${table.table_name}\` | ${table.object_type} | ${table.row_level_security ? "yes" : "no"} | ${data?.rowsExported ?? ""} |`,
    );
  }
  lines.push("");
  lines.push("## Functions");
  lines.push("");
  lines.push("| Schema | Function | Result | Language | Security Definer |");
  lines.push("|---|---|---|---|---:|");
  for (const fn of metadata.functions) {
    lines.push(
      `| \`${fn.schema_name}\` | \`${fn.function_name}(${fn.identity_arguments})\` | \`${escapePipe(fn.result_type)}\` | ${fn.language} | ${fn.security_definer ? "yes" : "no"} |`,
    );
  }
  lines.push("");
  lines.push("## Output Files");
  lines.push("");
  lines.push("- `metadata/database_metadata.json`: catalog metadata and definitions.");
  lines.push("- `metadata/data_summary.json`: data export status per table.");
  lines.push("- `sql/schema_reconstruction.sql`: best-effort schema reconstruction.");
  lines.push("- `sql/*.sql`: separated SQL artifacts for extensions, tables, functions, views, triggers, and policies.");
  lines.push("- `data/*.jsonl`: table data as JSON Lines.");
  lines.push("");
  lines.push("## Important Notes");
  lines.push("");
  lines.push("- This export is generated from SQL catalogs using a Node script, not `pg_dump`.");
  lines.push("- Use official `pg_dump` if you need a byte-for-byte production restore artifact.");
  lines.push("- Supabase Edge Functions and dashboard configuration are not stored in Postgres and are not included.");
  lines.push("- Supabase Storage object metadata is included if accessible as table data; binary file objects themselves are not included.");
  lines.push("- Auth tables may contain sensitive user data. Store this export securely.");
  lines.push("");

  await writeText("README.md", `${lines.join("\n")}\n`);
}

async function query(sql, params = []) {
  const result = await client.query(sql, params);
  return result.rows;
}

async function safeQuery(sql, params = []) {
  try {
    return await query(sql, params);
  } catch (error) {
    return { error: error.message };
  }
}

async function one(sql, params = []) {
  const result = await query(sql, params);
  return result[0] ?? null;
}

async function writeJson(relativePath, value) {
  await writeText(relativePath, `${JSON.stringify(value, null, 2)}\n`);
}

async function writeText(relativePath, value) {
  const target = path.join(outputRoot, relativePath);
  await fs.mkdir(path.dirname(target), { recursive: true });
  await fs.writeFile(target, value, "utf8");
}

async function ensureFolders() {
  await fs.mkdir(path.join(outputRoot, "metadata"), { recursive: true });
  await fs.mkdir(path.join(outputRoot, "sql"), { recursive: true });
  await fs.mkdir(path.join(outputRoot, "data"), { recursive: true });
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function quoteIdentifier(value) {
  return `"${String(value).replaceAll('"', '""')}"`;
}

function quoteIdent(schemaName, objectName) {
  return `${quoteIdentifier(schemaName)}.${quoteIdentifier(objectName)}`;
}

function quoteLiteral(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function safeFileName(value) {
  return value.replace(/[^a-zA-Z0-9._-]+/g, "_");
}

function escapePipe(value) {
  return String(value ?? "").replaceAll("|", "\\|");
}

function groupBy(items, keyFn) {
  const map = new Map();
  for (const item of items) {
    const key = keyFn(item);
    const bucket = map.get(key) ?? [];
    bucket.push(item);
    map.set(key, bucket);
  }
  return map;
}

function cursorRead(cursor, count) {
  return new Promise((resolve, reject) => {
    cursor.read(count, (error, rows) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(rows);
    });
  });
}

function cursorClose(cursor) {
  return new Promise((resolve, reject) => {
    cursor.close((error) => {
      if (error) {
        reject(error);
        return;
      }
      resolve();
    });
  });
}
