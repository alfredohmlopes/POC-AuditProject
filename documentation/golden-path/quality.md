# Quality Golden Path

> **"Quality is not an act, it is a habit."**  
> — Aristotle

---

## 1. Testing Standards

### 1.1 Test Pyramid

```
         /\
        /E2E\ ← 10% - End-to-end tests (slow, expensive, brittle)
       /____\
      /      \
     / Integration\ ← 20% - Integration tests (medium speed, moderate cost)
    /__________\
   /            \
  /  Unit Tests  \ ← 70% - Unit tests (fast, cheap, reliable)
 /________________\
```

**Coverage Requirements**:
- **Overall Project**: ≥ 80%
- **Domain Layer**: ≥ 95% (pure business logic)
- **Service Layer**: ≥ 90% (application logic)
- **Infrastructure Layer**: ≥ 70% (adapters, repositories)

---

### 1.2 Unit Tests

**Purpose**: Test individual methods/classes in isolation

#### **Characteristics**:
- ✅ Fast (< 100ms per test)
- ✅ Isolated (no external dependencies)
- ✅ Deterministic (always same result)
- ✅ Mock all dependencies

#### **Example with RSpec**:
```ruby
# spec/services/user_service_spec.rb
require 'rails_helper'

RSpec.describe UserService do
  describe '#create_user' do
    let(:user_repository) { instance_double(UserRepository) }
    let(:user_validator) { instance_double(UserValidator) }
    let(:logger) { instance_double(Logger) }
    let(:service) { described_class.new(user_repository, user_validator, logger) }
    
    context 'with valid input' do
      let(:request) do
        {
          email: 'test@example.com',
          username: 'testuser'
        }
      end
      
      before do
        allow(user_validator).to receive(:validate).and_return(true)
        allow(user_repository).to receive(:create).and_return(
          User.new(id: 1, email: 'test@example.com', username: 'testuser')
        )
      end
      
      it 'creates a user successfully' do
        result = service.create_user(request)
        
        expect(result).to be_a(User)
        expect(result.email).to eq('test@example.com')
        expect(result.username).to eq('testuser')
      end
      
      it 'validates the user before creation' do
        service.create_user(request)
        expect(user_validator).to have_received(:validate)
      end
      
      it 'calls the repository with correct parameters' do
        service.create_user(request)
        expect(user_repository).to have_received(:create).with(hash_including(email: 'test@example.com'))
      end
    end
    
    context 'with invalid input' do
      let(:request) { { email: 'invalid', username: '' } }
      
      before do
        allow(user_validator).to receive(:validate).and_raise(ValidationError, 'Invalid email')
      end
      
      it 'raises a validation error' do
        expect { service.create_user(request) }.to raise_error(ValidationError, 'Invalid email')
      end
      
      it 'does not call the repository' do
        expect { service.create_user(request) }.to raise_error(ValidationError)
        expect(user_repository).not_to have_received(:create)
      end
    end
  end
end
```

---

### 1.3 Table-Driven Tests (Shared Examples)

**Use RSpec shared examples for testing multiple scenarios**:

```ruby
# spec/support/shared_examples/email_validation.rb
RSpec.shared_examples 'email validation' do |email, should_be_valid, error_type = nil|
  context "when email is '#{email}'" do
    it "#{should_be_valid ? 'accepts' : 'rejects'} the email" do
      if should_be_valid
        expect(subject.validate_email(email)).to be_truthy
      else
        expect { subject.validate_email(email) }.to raise_error(error_type)
      end
    end
  end
end

# spec/services/email_validator_spec.rb
require 'rails_helper'

RSpec.describe EmailValidator do
  subject { described_class.new }
  
  describe '#validate_email' do
    include_examples 'email validation', 'user@example.com', true
    include_examples 'email validation', 'userexample.com', false, InvalidEmailFormat
    include_examples 'email validation', 'user@', false, InvalidEmailFormat
    include_examples 'email validation', '', false, EmailRequired
    include_examples 'email validation', 'user+tag@example.com', true
    include_examples 'email validation', 'user.name@example.co.uk', true
    include_examples 'email validation', '@example.com', false, InvalidEmailFormat
  end
end

# Alternative: Using RSpec's built-in table syntax
RSpec.describe EmailValidator do
  describe '#validate_email' do
    [
      { email: 'user@example.com', valid: true },
      { email: 'userexample.com', valid: false, error: InvalidEmailFormat },
      { email: 'user@', valid: false, error: InvalidEmailFormat },
      { email: '', valid: false, error: EmailRequired },
      { email: 'user+tag@example.com', valid: true },
    ].each do |test_case|
      context "with email '#{test_case[:email]}'" do
        if test_case[:valid]
          it 'is valid' do
            expect(EmailValidator.validate(test_case[:email])).to be_truthy
          end
        else
          it "raises #{test_case[:error]}" do
            expect { EmailValidator.validate(test_case[:email]) }.to raise_error(test_case[:error])
          end
        end
      end
    end
  end
end
```

---

### 1.4 Integration Tests

**Purpose**: Test component interactions with real dependencies

#### **Characteristics**:
- ⚠️ Slower (seconds per test)
- ⚠️ Use real infrastructure (DB, Redis)
- ✅ Test actual integration points
- ✅ Use database cleaner for isolation

#### **Example**:
```ruby
# spec/integration/user_repository_spec.rb
require 'rails_helper'

RSpec.describe UserRepository, type: :integration do
  let(:repository) { described_class.new }
  
  describe '#create' do
    it 'persists user to database' do
      user_data = {
        email: 'test@example.com',
        username: 'testuser',
        name: 'Test User'
      }
      
      user = repository.create(user_data)
      
      expect(user).to be_persisted
      expect(user.id).not_to be_nil
      
      # Verify persistence
      found_user = User.find(user.id)
      expect(found_user.email).to eq('test@example.com')
      expect(found_user.username).to eq('testuser')
    end
    
    it 'enforces unique email constraint' do
      repository.create(email: 'duplicate@example.com', username: 'user1')
      
      expect {
        repository.create(email: 'duplicate@example.com', username: 'user2')
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
  
  describe '#find_by_email' do
    before do
      @user = repository.create(email: 'existing@example.com', username: 'existing')
    end
    
    it 'returns user when found' do
      found = repository.find_by_email('existing@example.com')
      expect(found.id).to eq(@user.id)
    end
    
    it 'returns nil when not found' do
      found = repository.find_by_email('nonexistent@example.com')
      expect(found).to be_nil
    end
  end
end
```

---

### 1.5 End-to-End Tests

**Purpose**: Test complete user workflows through the HTTP API

```ruby
# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  describe 'POST /users' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'newuser@example.com',
            username: 'newuser',
            password: 'SecurePass123!'
          }
        }
      end
      
      it 'creates a new user' do
        expect {
          post '/users', params: valid_params, as: :json
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(json_response['email']).to eq('newuser@example.com')
      end
    end
    
    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            email: 'invalid-email',
            username: ''
          }
        }
      end
      
      it 'returns validation errors' do
        post '/users', params: invalid_params, as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end
  end
  
  describe 'GET /users/:id' do
    let!(:user) { create(:user) }
    
    context 'when user exists' do
      it 'returns the user' do
        get "/users/#{user.id}", as: :json
        
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end
    end
    
    context 'when user does not exist' do
      it 'returns 404' do
        get '/users/999999', as: :json
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  private
  
  def json_response
    JSON.parse(response.body)
  end
end
```

---

## 2. Test Organization

### 2.1 Directory Structure

```
spec/
├── rails_helper.rb           # Rails-specific test configuration
├── spec_helper.rb            # RSpec configuration
├── support/
│   ├── factory_bot.rb       # FactoryBot setup
│   ├── database_cleaner.rb  # Database cleaning strategy
│   ├── shared_examples/     # Reusable test examples
│   └── helpers/             # Test helper modules
├── models/                  # Model unit tests
│   └── user_spec.rb
├── services/                # Service object tests
│   └── user_service_spec.rb
├── repositories/            # Repository tests
│   └── user_repository_spec.rb
├── policies/                # Pundit policy tests
│   └── user_policy_spec.rb
├── integration/             # Integration tests
│   └── user_repository_spec.rb
├── requests/                # API endpoint tests (E2E)
│   └── users_spec.rb
└── system/                  # Full browser tests (if needed)
    └── user_registration_spec.rb
```

---

### 2.2 Test Naming Conventions

**RSpec follows BDD-style naming**:

```ruby
RSpec.describe UserService do
  # describe = Class or method being tested
  describe '#create_user' do
    # context = Specific scenario/condition
    context 'when user is valid' do
      # it = Expected behavior
      it 'creates the user' do
        # Test implementation
      end
      
      it 'sends welcome email' do
        # Test implementation
      end
    end
    
    context 'when user is invalid' do
      it 'raises validation error' do
        # Test implementation
      end
      
      it 'does not save the user' do
        # Test implementation
      end
    end
  end
end
```

**Output**:
```
UserService
  #create_user
    when user is valid
      creates the user
      sends welcome email
    when user is invalid
      raises validation error
      does not save the user
```

---

## 3. Code Quality Tools

### 3.1 Linting (RuboCop)

**Install and configure RuboCop**:

```ruby
# Gemfile
group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
end
```

**.rubocop.yml**:
```yaml
require:
  - rubocop-rails
  - rubocop-rspec
  - rubocop-performance

AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable
  Exclude:
    - 'db/schema.rb'
    - 'db/migrate/*'
    - 'bin/*'
    - 'node_modules/**/*'
    - 'vendor/**/*'

# Style preferences
Style/StringLiterals:
  EnforcedStyle: single_quotes

Style/Documentation:
  Enabled: false  # Enable in production apps

# Metrics
Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/**/*'

Metrics/MethodLength:
  Max: 15
  Exclude:
    - 'db/migrate/*'

Metrics/ClassLength:
  Max: 150

# Rails-specific
Rails/FilePath:
  EnforcedStyle: arguments

# RSpec-specific
RSpec/ExampleLength:
  Max: 10

RSpec/MultipleExpectations:
  Max: 5
```

**Run RuboCop**:
```bash
# Check all files
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -A

# Check specific files
bundle exec rubocop app/services/user_service.rb

# Generate TODO list for existing violations
bundle exec rubocop --auto-gen-config
```

---

### 3.2 Code Coverage (SimpleCov)

**Install SimpleCov**:

```ruby
# Gemfile
group :test do
  gem 'simplecov', require: false
  gem 'simplecov-json', require: false
end
```

**spec/rails_helper.rb** (at the very top):
```ruby
# frozen_string_literal: true

require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Controllers', 'app/controllers'
  add_group 'Repositories', 'app/repositories'
  add_group 'Policies', 'app/policies'
  
  minimum_coverage 80
  minimum_coverage_by_file 70
  
  # Refuse to merge results if minimum coverage not met
  refuse_coverage_drop
end

# Rest of rails_helper.rb
require 'spec_helper'
# ...
```

**View coverage report**:
```bash
# Run tests
bundle exec rspec

# Open coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
start coverage/index.html  # Windows
```

---

### 3.3 Static Analysis

**Additional quality tools**:

```ruby
# Gemfile
group :development, :test do
  gem 'brakeman', require: false  # Security scanner
  gem 'reek', require: false      # Code smell detector
  gem 'rails_best_practices', require: false
  gem 'bundler-audit', require: false
end
```

**Run static analysis**:
```bash
# Security scan
bundle exec brakeman -A -q

# Code smells
bundle exec reek app/

# Best practices
bundle exec rails_best_practices .

# Dependency vulnerabilities
bundle audit check --update
```

---

### 3.4 Continuous Integration

**.github/workflows/ci.yml**:
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      
      - name: Setup Database
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load
      
      - name: Run RuboCop
        run: bundle exec rubocop --parallel
      
      - name: Run Brakeman
        run: bundle exec brakeman -A -q
      
      - name: Run RSpec
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
          REDIS_URL: redis://localhost:6379/0
        run: |
          bundle exec rspec --format progress --format json --out rspec-results.json
      
      - name: Upload coverage results
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage.json
          fail_ci_if_error: true
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/.last_run.json | jq -r '.result.line')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage ($COVERAGE%) is below 80%"
            exit 1
          fi
```

---

## 4. Performance Testing

### 4.1 Benchmarking

**Use Ruby's built-in Benchmark module**:

```ruby
# spec/benchmarks/user_query_benchmark.rb
require 'benchmark'

RSpec.describe 'User Query Performance' do
  it 'fetches users efficiently' do
    # Create test data
    create_list(:user, 1000)
    
    time = Benchmark.measure do
      User.includes(:roles).where(active: true).limit(100).to_a
    end
    
    expect(time.real).to be < 0.1  # Should complete in under 100ms
  end
end

# Or use benchmark-ips for iterations per second
require 'benchmark/ips'

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)
  
  x.report('eager loading') do
    User.includes(:roles).limit(100).to_a
  end
  
  x.report('lazy loading') do
    User.limit(100).map(&:roles)
  end
  
  x.compare!
end
```

---

### 4.2 N+1 Query Detection

**Use Bullet gem**:

```ruby
# Gemfile
group :development, :test do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end

# config/environments/test.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.raise = true  # Raise error in tests
end
```

**Example test with N+1 detection**:
```ruby
RSpec.describe UsersController, type: :request do
  it 'avoids N+1 queries when fetching users' do
    create_list(:user, 10)
    
    expect {
      get '/users', as: :json
    }.not_to exceed_query_limit(3)  # Using n_plus_one_control gem
  end
end
```

---

## 5. Documentation

### 5.1 Code Documentation (YARD)

**Use YARD for API documentation**:

```ruby
# Gemfile
group :development do
  gem 'yard', require: false
end

# Example documented class
# @example Creating a user
#   service = UserService.new(repo, validator)
#   user = service.create_user(email: 'user@example.com')
#
class UserService
  # Creates a new user in the system
  #
  # @param params [Hash] User attributes
  # @option params [String] :email User's email address
  # @option params [String] :username Unique username
  # @option params [String] :password User's password
  #
  # @return [User] The created user
  # @raise [ValidationError] if params are invalid
  # @raise [DuplicateError] if email already exists
  #
  # @example
  #   service.create_user(
  #     email: 'user@example.com',
  #     username: 'johndoe',
  #     password: 'SecurePass123!'
  #   )
  def create_user(params)
    # Implementation
  end
end
```

**Generate documentation**:
```bash
# Generate docs
bundle exec yard doc

# Start documentation server
bundle exec yard server
```

---

### 5.2 API Documentation

**Use rswag for OpenAPI/Swagger docs**:

```ruby
# Gemfile
group :development, :test do
  gem 'rswag-specs'
end

group :development do
  gem 'rswag-api'
  gem 'rswag-ui'
end

# spec/requests/users_spec.rb
require 'swagger_helper'

RSpec.describe 'Users API' do
  path '/users' do
    post 'Creates a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, format: :email },
          username: { type: :string },
          password: { type: :string, format: :password, minimum: 12 }
        },
        required: ['email', 'username', 'password']
      }
      
      response '201', 'user created' do
        let(:user) { { email: 'user@example.com', username: 'johndoe', password: 'SecurePass123!' } }
        run_test!
      end
      
      response '422', 'invalid request' do
        let(:user) { { email: 'invalid' } }
        run_test!
      end
    end
  end
end

# Generate Swagger JSON
bundle exec rake rswag:specs:swaggerize
```

---

## 6. Code Review Checklist

Before merging:

### 6.1 Code Quality
- [ ] **RuboCop passes**: `bundle exec rubocop` (zero offenses)
- [ ] **Tests pass**: `bundle exec rspec` (all green)
- [ ] **Coverage**: ≥ 80% overall, ≥ 70% per file
- [ ] **No N+1 queries**: Bullet gem raises no errors
- [ ] **Security scan passes**: `bundle exec brakeman -A -q` (no issues)
- [ ] **No code smells**: `bundle exec reek app/` (acceptable level)

### 6.2 Testing
- [ ] **Unit tests**: All public methods tested
- [ ] **Integration tests**: Critical paths covered
- [ ] **Edge cases**: Tested (nil, empty, invalid inputs)
- [ ] **Error cases**: Exception handling tested
- [ ] **Mocks verified**: All mock expectations asserted

### 6.3 Documentation
- [ ] **YARD comments**: Complex methods documented
- [ ] **README updated**: If behavior changed
- [ ] **API docs updated**: If endpoints changed
- [ ] **CHANGELOG**: Updated with changes

### 6.4 Performance
- [ ] **Query optimization**: No missing indexes
- [ ] **Caching**: Implemented where appropriate
- [ ] **Pagination**: Large datasets paginated

---

## 7. Definition of Done

A feature is "done" when:

1. ✅ **Code complete** and follows Ruby style guide
2. ✅ **RuboCop passes** (zero offenses)
3. ✅ **All tests pass** (unit + integration + E2E)
4. ✅ **Code coverage ≥ 80%** (SimpleCov)
5. ✅ **No N+1 queries** (Bullet gem)
6. ✅ **Security scan passes** (Brakeman, bundle-audit)
7. ✅ **Code reviewed** and approved by peer
8. ✅ **Documentation updated** (YARD, API docs, README)
9. ✅ **CI/CD pipeline passes** (all checks green)
10. ✅ **Deployed to staging** and smoke tested

---

**Related Documentation**:
- [Architecture Golden Path](./architecture.md) - SOLID, DDD, Clean Architecture
- [Development Golden Path](./development.md) - Coding standards, Testing
- [Security Golden Path](./security.md) - Security testing, Dependency scanning
