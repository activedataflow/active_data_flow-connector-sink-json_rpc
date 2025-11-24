# ActiveDataFlow Logging

This document explains the logging behavior in ActiveDataFlow.

## Log Levels

ActiveDataFlow supports four log levels:

- `:debug` - Detailed information for debugging
- `:info` - General informational messages (default)
- `:warn` - Warning messages
- `:error` - Error messages

## Configuration

Set the log level in your initializer:

```ruby
# config/initializers/active_data_flow.rb
ActiveDataFlow.configure do |config|
  config.log_level = :info  # or :debug, :warn, :error
end
```

## Log Messages

### Initialization Messages (Info Level)

These messages appear during Rails initialization:

```
[ActiveDataFlow] Initializing...
[ActiveDataFlow] Loading concerns and data flows...
[ActiveDataFlow] Found 3 data flow file(s)
[ActiveDataFlow] Registered data flow: UserSyncFlow
[ActiveDataFlow] Registered data flow: ProductSyncFlow
[ActiveDataFlow] Registered data flow: OrderSyncFlow
[ActiveDataFlow] Successfully registered 3 data flow(s)
[ActiveDataFlow] Initialization complete
```

### When Auto-Loading is Disabled

```
[ActiveDataFlow] Auto-loading disabled, skipping data flow registration
```

### When No Data Flows Found

```
[ActiveDataFlow] No data flow files found in /path/to/app/data_flows
```

### When Directory Doesn't Exist

```
[ActiveDataFlow] Data flows directory not found: /path/to/app/data_flows
```

## Debug Level Logging

Enable debug logging for more detailed information:

```ruby
ActiveDataFlow.configure do |config|
  config.log_level = :debug
end
```

**Additional debug messages:**

```
[ActiveDataFlow] Loaded engine concern: /path/to/concern.rb
[ActiveDataFlow] Loaded host concern: /path/to/host/concern.rb
[ActiveDataFlow] Skipped MyFlow (no register method)
```

**Error backtraces:**
```
[ActiveDataFlow] Failed to load/register data flow: undefined method 'foo'
/path/to/file.rb:10:in `register'
/path/to/file.rb:5:in `<class:MyFlow>'
...
```

## Error Messages

Errors are always logged regardless of log level:

### Load/Registration Errors

```
[ActiveDataFlow] Failed to load/register data flow /path/to/flow.rb: undefined method 'foo'
```

### Missing Class

```
[ActiveDataFlow] Could not find class MyFlow for /path/to/my_flow.rb
```

### Concern Loading Errors

```
Failed to load engine concern /path/to/concern.rb: syntax error
Failed to load host concern /path/to/concern.rb: uninitialized constant
```

## Log Output Examples

### Successful Startup (Info Level)

```
[ActiveDataFlow] Initializing...
[ActiveDataFlow] Loading concerns and data flows...
[ActiveDataFlow] Found 2 data flow file(s)
[ActiveDataFlow] Registered data flow: UserSyncFlow
[ActiveDataFlow] Registered data flow: ProductSyncFlow
[ActiveDataFlow] Successfully registered 2 data flow(s)
[ActiveDataFlow] Initialization complete
```

### Startup with Errors (Info Level)

```
[ActiveDataFlow] Initializing...
[ActiveDataFlow] Loading concerns and data flows...
[ActiveDataFlow] Found 3 data flow file(s)
[ActiveDataFlow] Registered data flow: UserSyncFlow
[ActiveDataFlow] Failed to load/register data flow /app/data_flows/broken_flow.rb: undefined method 'foo'
[ActiveDataFlow] Registered data flow: ProductSyncFlow
[ActiveDataFlow] Successfully registered 2 data flow(s)
[ActiveDataFlow] Initialization complete
```

### Debug Level Output

```
[ActiveDataFlow] Initializing...
[ActiveDataFlow] Loading concerns and data flows...
Loaded engine concern: /gems/active_data_flow/app/data_flows/concerns/active_record_2_active_record.rb
Loaded host concern: /app/data_flows/concerns/custom_concern.rb
[ActiveDataFlow] Found 2 data flow file(s)
[ActiveDataFlow] Registered data flow: UserSyncFlow
[ActiveDataFlow] Skipped HelperClass (no register method)
[ActiveDataFlow] Registered data flow: ProductSyncFlow
[ActiveDataFlow] Successfully registered 2 data flow(s)
[ActiveDataFlow] Initialization complete
```

## Filtering Logs

### In Development

View only ActiveDataFlow logs:

```bash
tail -f log/development.log | grep ActiveDataFlow
```

### In Production

Filter logs by tag:

```bash
grep "\[ActiveDataFlow\]" log/production.log
```

## Customizing Log Format

To customize the log format, you can monkey-patch the logger methods or use Rails' tagged logging:

```ruby
# config/initializers/active_data_flow.rb
Rails.application.configure do
  config.log_tags = [:request_id, :subdomain]
end
```

## Disabling Logs

To suppress ActiveDataFlow logs entirely:

```ruby
# Not recommended, but possible
Rails.logger.silence do
  # ActiveDataFlow initialization happens here
end
```

Or set log level to `:error`:

```ruby
ActiveDataFlow.configure do |config|
  config.log_level = :error  # Only show errors
end
```

## Troubleshooting

### Logs Not Appearing

1. **Check log level:**
   ```ruby
   puts ActiveDataFlow.configuration.log_level
   ```

2. **Check Rails logger:**
   ```ruby
   puts Rails.logger.level  # 0=debug, 1=info, 2=warn, 3=error
   ```

3. **Check log file:**
   ```bash
   tail -f log/development.log
   ```

### Too Many Logs

Reduce verbosity:

```ruby
ActiveDataFlow.configure do |config|
  config.log_level = :warn  # Only warnings and errors
end
```

### Missing Error Details

Enable debug mode for full backtraces:

```ruby
ActiveDataFlow.configure do |config|
  config.log_level = :debug
end
```

## Best Practices

1. **Use :info in production** - Provides visibility without overwhelming logs
2. **Use :debug in development** - Helps troubleshoot loading issues
3. **Monitor error logs** - Set up alerts for ActiveDataFlow errors
4. **Include context** - All logs are prefixed with `[ActiveDataFlow]` for easy filtering
5. **Review startup logs** - Check that all expected data flows are registered
