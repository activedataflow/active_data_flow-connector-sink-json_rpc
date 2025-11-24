# ActiveDataFlow Installation Verification

This document helps verify that ActiveDataFlow is properly installed and configured.

## Installation Checklist

### 1. Gem Installation

Verify the gem is installed:

```bash
bundle list | grep active_data_flow
```

**Expected output:**
```
* active_data_flow (0.1.1)
```

### 2. Generator Available

Check that generators are available:

```bash
rails generate --help | grep active_data_flow
```

**Expected output:**
```
  active_data_flow:data_flow
  active_data_flow:install
```

### 3. Run Install Generator

Install ActiveDataFlow:

```bash
rails generate active_data_flow:install
```

**What it does:**
- ✅ Creates migration for data_flows table
- ✅ Creates `app/data_flows/` directory
- ✅ Copies initializer to `config/initializers/active_data_flow.rb`
- ✅ Mounts engine in `config/routes.rb`
- ✅ Displays setup instructions

### 4. Verify Migration

Check that migration was created:

```bash
ls db/migrate/*create_active_data_flow_data_flows.rb
```

**Expected:** File exists with timestamp

### 5. Run Migration

Apply the migration:

```bash
rails db:migrate
```

**Expected output:**
```
== CreateActiveDataFlowDataFlows: migrating ==================================
-- create_table(:active_data_flow_data_flows)
   -> 0.0123s
== CreateActiveDataFlowDataFlows: migrated (0.0124s) =========================
```

### 6. Verify Table

Check that table was created:

```bash
rails dbconsole
```

```sql
.schema active_data_flow_data_flows
-- or for PostgreSQL/MySQL:
\d active_data_flow_data_flows
```

**Expected columns:**
- id
- name
- source (json)
- sink (json)
- runtime (json)
- status
- last_run_at
- last_error
- created_at
- updated_at

### 7. Verify Engine Mount

Check routes file:

```bash
grep "ActiveDataFlow::Engine" config/routes.rb
```

**Expected output:**
```ruby
mount ActiveDataFlow::Engine => "/active_data_flow"
```

### 8. Verify Routes

List ActiveDataFlow routes:

```bash
rails routes | grep active_data_flow
```

**Expected routes:**
```
active_data_flow        /active_data_flow           ActiveDataFlow::Engine
root GET                /                           active_data_flow/dashboard#index
trigger_data_flow POST  /data_flows/:id/trigger     active_data_flow/data_flows#trigger
data_flows GET          /data_flows                 active_data_flow/data_flows#index
data_flow GET           /data_flows/:id             active_data_flow/data_flows#show
```

### 9. Verify Initializer

Check that initializer was created:

```bash
cat config/initializers/active_data_flow.rb
```

**Expected content:**
```ruby
ActiveDataFlow.configure do |config|
  config.auto_load_data_flows = true
  config.log_level = :info
  config.data_flows_path = "app/data_flows"
end
```

### 10. Verify Data Flows Directory

Check that directory was created:

```bash
ls -la app/data_flows/
```

**Expected:**
```
drwxr-xr-x  app/data_flows/
-rw-r--r--  app/data_flows/.keep
```

### 11. Start Rails Server

Start the server:

```bash
rails server
```

### 12. Access Dashboard

Visit the dashboard in your browser:

```
http://localhost:3000/active_data_flow
```

**Expected:** Dashboard page loads without errors

### 13. Check Logs

View Rails logs for ActiveDataFlow initialization:

```bash
tail -f log/development.log | grep ActiveDataFlow
```

**Expected output:**
```
[ActiveDataFlow] Initializing...
[ActiveDataFlow] Loading concerns and data flows...
[ActiveDataFlow] No data flow files found in /path/to/app/data_flows
[ActiveDataFlow] Initialization complete
```

## Troubleshooting

### Generator Not Found

**Problem:** `rails generate active_data_flow:install` fails

**Solutions:**
1. Run `bundle install`
2. Restart Spring: `spring stop`
3. Check Gemfile includes the gem
4. Verify gem is installed: `bundle list | grep active_data_flow`

### Migration Fails

**Problem:** `rails db:migrate` fails

**Solutions:**
1. Check database is running
2. Verify database.yml configuration
3. Check for existing table: `rails dbconsole` then `.tables` or `\dt`
4. Drop and recreate database if needed: `rails db:drop db:create db:migrate`

### Routes Not Found

**Problem:** Routes don't appear in `rails routes`

**Solutions:**
1. Check `config/routes.rb` has mount statement
2. Restart Rails server
3. Clear routes cache: `rails tmp:clear`
4. Verify engine is loaded: `Rails.application.railties.map(&:class)`

### Dashboard 404

**Problem:** Visiting `/active_data_flow` returns 404

**Solutions:**
1. Verify engine is mounted: `grep ActiveDataFlow config/routes.rb`
2. Check routes: `rails routes | grep active_data_flow`
3. Restart Rails server
4. Check for route conflicts

### No Logs Appearing

**Problem:** No `[ActiveDataFlow]` logs in development.log

**Solutions:**
1. Check log level: `ActiveDataFlow.configuration.log_level`
2. Check Rails log level: `Rails.logger.level`
3. Verify initializer is loaded
4. Check `config.auto_load_data_flows` is true

## Verification Script

Create a script to verify installation:

```ruby
# script/verify_active_data_flow.rb
puts "Checking ActiveDataFlow installation..."

# Check gem
require 'active_data_flow'
puts "✓ Gem loaded: #{ActiveDataFlow::VERSION}"

# Check configuration
puts "✓ Configuration loaded"
puts "  - Auto-load: #{ActiveDataFlow.configuration.auto_load_data_flows}"
puts "  - Log level: #{ActiveDataFlow.configuration.log_level}"
puts "  - Data flows path: #{ActiveDataFlow.configuration.data_flows_path}"

# Check database
if ActiveRecord::Base.connection.table_exists?('active_data_flow_data_flows')
  puts "✓ Database table exists"
  count = ActiveDataFlow::DataFlow.count
  puts "  - Data flows in database: #{count}"
else
  puts "✗ Database table missing - run migrations"
end

# Check routes
if Rails.application.routes.routes.any? { |r| r.app.app == ActiveDataFlow::Engine }
  puts "✓ Engine mounted"
else
  puts "✗ Engine not mounted - check config/routes.rb"
end

# Check data flows directory
data_flows_dir = Rails.root.join('app/data_flows')
if Dir.exist?(data_flows_dir)
  puts "✓ Data flows directory exists"
  flow_count = Dir[data_flows_dir.join('**/*_flow.rb')].size
  puts "  - Data flow files: #{flow_count}"
else
  puts "✗ Data flows directory missing"
end

puts "\nInstallation verification complete!"
```

Run with:
```bash
rails runner script/verify_active_data_flow.rb
```

## Success Criteria

Installation is successful when:

- ✅ Gem is installed and loaded
- ✅ Generators are available
- ✅ Migration has been run
- ✅ Database table exists
- ✅ Engine is mounted in routes
- ✅ Dashboard is accessible
- ✅ Initializer is configured
- ✅ Data flows directory exists
- ✅ Logs show initialization messages

If all criteria are met, ActiveDataFlow is properly installed and ready to use!
