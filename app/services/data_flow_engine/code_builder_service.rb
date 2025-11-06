require 'open3'
require 'tmpdir'
require 'fileutils'

module DataFlowEngine
  class CodeBuilderService
    attr_reader :lambda_configuration

    def initialize(lambda_configuration)
      @lambda_configuration = lambda_configuration
    end

    # Build deployment package for the Lambda function
    def build
      case lambda_configuration.code_language
      when 'ruby'
        build_ruby
      when 'go'
        build_go
      when 'rust'
        build_rust
      else
        { success: false, error: "Unsupported language: #{lambda_configuration.code_language}" }
      end
    end

    # Build Ruby Lambda package
    def build_ruby
      Dir.mktmpdir do |dir|
        # Write handler code
        File.write(File.join(dir, 'handler.rb'), lambda_configuration.function_code)

        # Create Gemfile if dependencies are specified
        if lambda_configuration.metadata['dependencies'].present?
          create_gemfile(dir, lambda_configuration.metadata['dependencies'])
          install_ruby_dependencies(dir)
        end

        # Create ZIP package
        zip_path = create_zip_package(dir)

        {
          success: true,
          package_path: zip_path,
          language: 'ruby',
          size: File.size(zip_path)
        }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # Build Go Lambda package
    def build_go
      Dir.mktmpdir do |dir|
        # Write Go source code
        File.write(File.join(dir, 'main.go'), lambda_configuration.function_code)

        # Create go.mod if not present
        create_go_mod(dir) unless lambda_configuration.function_code.include?('module ')

        # Download dependencies
        run_command('go mod download', dir)

        # Build for Lambda (Linux AMD64)
        env = { 'GOOS' => 'linux', 'GOARCH' => 'amd64', 'CGO_ENABLED' => '0' }
        output_path = File.join(dir, 'bootstrap')
        
        result = run_command("go build -o #{output_path} main.go", dir, env)
        return { success: false, error: result[:error] } unless result[:success]

        # Create ZIP package
        zip_path = create_zip_package(dir, ['bootstrap'])

        {
          success: true,
          package_path: zip_path,
          language: 'go',
          size: File.size(zip_path),
          binary_size: File.size(output_path)
        }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # Build Rust Lambda package
    def build_rust
      Dir.mktmpdir do |dir|
        # Create Cargo project structure
        src_dir = File.join(dir, 'src')
        FileUtils.mkdir_p(src_dir)

        # Write Rust source code
        File.write(File.join(src_dir, 'main.rs'), lambda_configuration.function_code)

        # Create Cargo.toml
        create_cargo_toml(dir)

        # Build for Lambda (Linux MUSL)
        result = run_command(
          'cargo build --release --target x86_64-unknown-linux-musl',
          dir
        )
        return { success: false, error: result[:error] } unless result[:success]

        # Copy binary and rename to bootstrap
        binary_path = File.join(dir, 'target', 'x86_64-unknown-linux-musl', 'release', 
                               lambda_configuration.metadata['binary_name'] || 'lambda')
        bootstrap_path = File.join(dir, 'bootstrap')
        FileUtils.cp(binary_path, bootstrap_path)

        # Create ZIP package
        zip_path = create_zip_package(dir, ['bootstrap'])

        {
          success: true,
          package_path: zip_path,
          language: 'rust',
          size: File.size(zip_path),
          binary_size: File.size(bootstrap_path)
        }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # Build Docker image for containerized Lambda
    def build_docker_image(tag = 'latest')
      return { success: false, error: 'Not a container-based language' } unless lambda_configuration.requires_container?

      Dir.mktmpdir do |dir|
        # Write source code
        write_source_files(dir)

        # Generate Dockerfile
        dockerfile_content = generate_dockerfile
        File.write(File.join(dir, 'Dockerfile'), dockerfile_content)

        # Build Docker image
        image_name = "#{lambda_configuration.function_name}:#{tag}"
        result = run_command("docker build -t #{image_name} .", dir)

        if result[:success]
          {
            success: true,
            image_name: image_name,
            dockerfile: dockerfile_content
          }
        else
          { success: false, error: result[:error] }
        end
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    # Create Gemfile for Ruby dependencies
    def create_gemfile(dir, dependencies)
      gemfile_content = "source 'https://rubygems.org'\n\n"
      dependencies.each do |gem_name, version|
        gemfile_content += "gem '#{gem_name}'"
        gemfile_content += ", '#{version}'" if version
        gemfile_content += "\n"
      end

      File.write(File.join(dir, 'Gemfile'), gemfile_content)
    end

    # Install Ruby dependencies
    def install_ruby_dependencies(dir)
      run_command('bundle install --path vendor/bundle', dir)
    end

    # Create go.mod file
    def create_go_mod(dir)
      mod_content = <<~GOMOD
        module #{lambda_configuration.function_name}

        go 1.21

        require github.com/aws/aws-lambda-go v1.41.0
      GOMOD

      File.write(File.join(dir, 'go.mod'), mod_content)
    end

    # Create Cargo.toml file
    def create_cargo_toml(dir)
      toml_content = <<~TOML
        [package]
        name = "#{lambda_configuration.function_name.parameterize.underscore}"
        version = "0.1.0"
        edition = "2021"

        [dependencies]
        lambda_runtime = "0.8"
        tokio = { version = "1", features = ["full"] }
        serde = { version = "1", features = ["derive"] }
        serde_json = "1"

        [[bin]]
        name = "bootstrap"
        path = "src/main.rs"
      TOML

      File.write(File.join(dir, 'Cargo.toml'), toml_content)
    end

    # Create ZIP package
    def create_zip_package(dir, files = nil)
      zip_path = File.join(Dir.tmpdir, "#{lambda_configuration.function_name}-#{Time.now.to_i}.zip")
      
      Dir.chdir(dir) do
        if files
          run_command("zip -r #{zip_path} #{files.join(' ')}", dir)
        else
          run_command("zip -r #{zip_path} .", dir)
        end
      end

      zip_path
    end

    # Run shell command
    def run_command(command, working_dir = nil, env = {})
      stdout, stderr, status = Open3.capture3(env, command, chdir: working_dir)

      if status.success?
        { success: true, output: stdout }
      else
        { success: false, error: stderr, output: stdout }
      end
    end

    # Write source files for Docker build
    def write_source_files(dir)
      case lambda_configuration.code_language
      when 'go'
        File.write(File.join(dir, 'main.go'), lambda_configuration.function_code)
        create_go_mod(dir)
      when 'rust'
        src_dir = File.join(dir, 'src')
        FileUtils.mkdir_p(src_dir)
        File.write(File.join(src_dir, 'main.rs'), lambda_configuration.function_code)
        create_cargo_toml(dir)
      end
    end

    # Generate Dockerfile
    def generate_dockerfile
      ecr_service = EcrService.new(lambda_configuration.data_flow)
      ecr_service.send(:generate_dockerfile, lambda_configuration)
    end
  end
end
