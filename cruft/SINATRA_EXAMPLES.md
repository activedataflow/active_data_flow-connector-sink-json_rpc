# Sinatra JSON-RPC Examples

This directory contains two related demonstration projects showcasing different approaches to JSON-RPC communication using the Sinatra web framework.

## Projects Overview

### 1. sinatra-json-rpc-demo
**Repository**: https://github.com/magenticmarketactualskill/sinatra-json-rpc-demo  
**Type**: Traditional JSON-RPC 2.0 implementation  
**Purpose**: Demonstrates standard JSON-RPC communication patterns

**Key Features**:
- Full JSON-RPC 2.0 specification compliance
- Client-server architecture with separate Sinatra applications
- Three example RPC methods (calculator, string manipulation, data storage)
- Web interface for interactive testing
- Comprehensive error handling and logging
- Support for both named and positional parameters

**Use Cases**:
- Learning JSON-RPC protocol fundamentals
- Reference implementation for JSON-RPC servers
- Educational example for web API development
- Testing JSON-RPC client-server communication

### 2. sinatra-json-rpc-ld
**Repository**: https://github.com/magenticmarketactualskill/sinatra-json-rpc-ld  
**Type**: JSON-RPC enhanced with JSON-LD (Linked Data)  
**Purpose**: Demonstrates semantic web integration with JSON-RPC

**Key Features**:
- JSON-RPC 2.0 with JSON-LD semantic enhancement
- Support for multiple vocabularies (Schema.org, Good Relations, GeoSPARQL)
- Semantic validation and context management
- Enhanced error handling with semantic context
- Vocabulary-specific data processing
- Context resolution (inline and URL-referenced)

**Use Cases**:
- Semantic web application development
- Linked Data API implementation
- Vocabulary-based data validation
- Educational example for JSON-LD integration

## Architecture Comparison

| Feature | sinatra-json-rpc-demo | sinatra-json-rpc-ld |
|---------|----------------------|---------------------|
| **Protocol** | JSON-RPC 2.0 | JSON-RPC 2.0 + JSON-LD |
| **Data Format** | Plain JSON | JSON-LD with semantic context |
| **Validation** | Parameter type checking | Semantic vocabulary validation |
| **Error Handling** | Standard JSON-RPC errors | Semantic error responses |
| **Vocabularies** | None | Schema.org, Good Relations, GeoSPARQL |
| **Context Management** | N/A | Full JSON-LD context support |
| **Server Port** | 4567 | 4569 |
| **Client Port** | 4568 | 4568 |

## Quick Start

### Traditional JSON-RPC Demo
```bash
cd sinatra-json-rpc-demo
./install_dependencies.sh
./start_demo.sh
# Visit http://localhost:4568 for web interface
# Server API: http://localhost:4567/jsonrpc
```

### JSON-RPC-LD Demo
```bash
cd sinatra-json-rpc-ld
./install_dependencies.sh
./start_demo.sh
# Visit http://localhost:4568 for web interface
# Server API: http://localhost:4569/jsonrpc
```

## Example Requests

### Traditional JSON-RPC
```json
{
  "jsonrpc": "2.0",
  "method": "calculator.add",
  "params": [5, 3],
  "id": 1
}
```

### JSON-RPC-LD
```json
{
  "jsonrpc": "2.0",
  "method": "manage_person",
  "params": {
    "@context": {
      "@vocab": "http://schema.org/",
      "Person": "Person",
      "name": "name",
      "email": "email"
    },
    "@type": "Person",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "id": 1
}
```

## Development Workflow

### Setting up as GitHub Repositories

1. **Run the setup script**:
   ```bash
   cd submodules/examples
   ./setup_github_repos.sh
   ```

2. **Create repositories on GitHub**:
   - Create `sinatra-json-rpc-demo` repository
   - Create `sinatra-json-rpc-ld` repository

3. **Push to GitHub**:
   ```bash
   cd sinatra-json-rpc-demo
   git push -u origin main
   
   cd ../sinatra-json-rpc-ld
   git push -u origin main
   ```

### Submoduler Configuration

Both projects include `.submoduler.ini` files with:
- Project metadata and descriptions
- Dependency specifications
- Available scripts and commands
- Feature documentation
- Example usage information

## Educational Value

### Learning Path
1. **Start with sinatra-json-rpc-demo** to understand JSON-RPC fundamentals
2. **Progress to sinatra-json-rpc-ld** to explore semantic web concepts
3. **Compare implementations** to see how JSON-LD enhances traditional JSON-RPC

### Key Concepts Demonstrated
- **JSON-RPC Protocol**: Request/response patterns, error handling
- **Semantic Web**: JSON-LD, vocabularies, context management
- **Web APIs**: RESTful endpoints, parameter validation
- **Client-Server Architecture**: Separation of concerns, communication patterns
- **Error Handling**: Graceful degradation, meaningful error messages

## Testing

Both projects include comprehensive test suites:

### Automated Testing
```bash
# Traditional JSON-RPC
cd sinatra-json-rpc-demo && ./test_demo.sh

# JSON-RPC-LD
cd sinatra-json-rpc-ld && ./test_demo.sh
```

### Manual Testing
- Web interfaces for interactive testing
- Example requests and expected responses
- Error scenario testing

## Contributing

These projects serve as educational examples and reference implementations. Contributions should focus on:
- Improving documentation and examples
- Adding new vocabulary support (JSON-RPC-LD)
- Enhancing error handling and validation
- Performance optimizations
- Additional test cases

## License

Both projects are provided as educational examples and demonstrations.