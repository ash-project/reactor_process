# Usage Rules for Reactor Process

This file contains essential information for AI coding agents when working with the `reactor_process` library.

## Essential Setup

1. **Always include the extension** when defining a Reactor that uses process steps:
   ```elixir
   defmodule MyReactor do
     use Reactor, extensions: [Reactor.Process]
   end
   ```

2. **Middleware is automatically added** - don't manually add `Reactor.Process.Middleware`

## Critical Constraints

1. **`start_link` steps MUST run synchronously** - they automatically set `async?: false`
2. **Process steps require the middleware** - will fail with `MissingMiddlewareError` if extension not used
3. **All timeouts are in milliseconds** - default termination timeout is 5000ms (5 seconds)

## Step Types and Required Arguments

### start_link
- **Required**: `child_spec` 
- **Purpose**: Links process to Reactor process (not supervisor)
- **Auto-cleanup**: Terminates process on undo by default

### start_child  
- **Required**: `supervisor`, `child_spec`
- **Purpose**: Adds child to supervisor
- **Module options**: `Supervisor` (default) or `DynamicSupervisor`

### terminate_child
- **Required**: `supervisor`, `child_id`
- **Important**: Use PID for `child_id` with DynamicSupervisor, use ID atom with regular Supervisor
- **Module options**: `Supervisor` (default) or `DynamicSupervisor`

### restart_child
- **Required**: `supervisor`, `child_id`
- **Limitation**: Only works with regular Supervisor (not DynamicSupervisor)

### delete_child
- **Required**: `supervisor`, `child_id`
- **Purpose**: Removes child spec from supervisor

### count_children
- **Required**: `supervisor`
- **Returns**: Map with `:active`, `:specs`, `:supervisors`, `:workers` counts

### process_exit
- **Required**: `process`, `reason`
- **Purpose**: Send exit signal to any process (not supervisor-managed)

## Supervisor Reference Types

All supervisor arguments accept:
- PID: `supervisor_pid`
- Atom: `:my_supervisor` 
- Global: `{:global, :name}`
- Via: `{:via, Registry, {MyRegistry, "key"}}`
- Remote: `{:node1@host, :supervisor_name}`

## Child Specification Patterns

### Simple module
```elixir
child_spec :worker do
  module MyWorker
end
```

### Module with options
```elixir
child_spec :server do
  module {MyServer, [port: 4000]}
end
```

### Dynamic specification
```elixir
child_spec :dynamic do
  module input(:base_module)
  transform fn {mod, opts}, inputs ->
    {mod, Keyword.put(opts, :name, inputs.worker_name)}
  end
end
```

## Common Failure Modes and Solutions

### 1. MissingMiddlewareError
- **Cause**: Using process steps without `Reactor.Process` extension
- **Solution**: Add `extensions: [Reactor.Process]` to `use Reactor`

### 2. Already started/present errors
- **Cause**: Trying to start existing processes/specs
- **Solution**: Set `fail_on_already_started?: false` or `fail_on_already_present?: false`

### 3. DynamicSupervisor child_id confusion
- **Cause**: Using atom ID instead of PID for DynamicSupervisor operations
- **Solution**: Use the actual process PID returned from `start_child` for subsequent operations

### 4. Timeout errors during termination
- **Cause**: Default 5s timeout too short for graceful shutdown
- **Solution**: Increase `termination_timeout` option

## Best Practices

1. **Use `wait_for` for dependencies** between process steps
2. **Set appropriate timeouts** for long-running processes  
3. **Handle already-started scenarios** gracefully in production code
4. **Use `fail_on_not_found?: false`** for cleanup operations that might run multiple times
5. **Configure undo behaviour** appropriately:
   - `terminate_on_undo?: true` for `start_link` and `start_child` (cleanup)
   - `restart_on_undo?: true` for `terminate_child` (recovery)

## Error Handling Patterns

### Graceful degradation
```elixir
start_child :optional_service do
  supervisor input(:supervisor)
  child_spec result(:service_spec)
  fail_on_already_started? false
end
```

### Cleanup operations
```elixir
terminate_child :cleanup do
  supervisor input(:supervisor)
  child_id input(:worker_id)
  fail_on_not_found? false
end
```

### Health checks
```elixir
count_children :health_check do
  supervisor input(:supervisor)
end

restart_child :heal_if_needed do
  supervisor input(:supervisor)
  child_id input(:worker_id)
end
```

## Integration with Regular Supervisor vs DynamicSupervisor

### Regular Supervisor
- Use atom IDs for child identification
- Supports `restart_child` and `delete_child`
- Children must be pre-defined in supervisor spec OR added via `start_child`

### DynamicSupervisor  
- Use PIDs for child identification in terminate operations
- Does NOT support `restart_child` or `delete_child`
- Children added dynamically via `start_child`
- Set `module: DynamicSupervisor` in step options

## Performance Considerations

- Process steps run synchronously by design
- Use `wait_for` strategically to minimise blocking  
- Consider supervisor restart strategies when designing process hierarchies
- Monitor supervisor child counts for health metrics