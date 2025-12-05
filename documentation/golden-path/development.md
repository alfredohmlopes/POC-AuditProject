# Development Golden Path

> **"Code is read much more often than it is written."**  
> — Guido van Rossum

---

## 1. Development Workflow

### 1.1 Git Workflow (Trunk-Based Development)

**Branch Strategy**:
- `main`: Production-ready code, always deployable
- `feature/*`: Short-lived feature branches (max 2-3 days)
- `hotfix/*`: Emergency production fixes

**Rules**:
- ✅ Small, frequent commits to main (via PR)
- ✅ Feature flags for incomplete features
- ❌ No long-lived feature branches (kills collaboration)
- ❌ No direct commits to main (always via PR)

---

### 1.2 Commit Messages (Conventional Commits)

**Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no functional change)
- `test`: Adding or updating tests
- `docs`: Documentation changes
- `chore`: Build scripts, dependencies, tooling
- `perf`: Performance improvement
- `security`: Security fix

**Examples**:
```
feat(auth): implement PKCE support for OAuth2 flow

Added code verifier generation and validation for
Authorization Code flow with PKCE (RFC 7636).

Closes #42
```

```
fix(user): prevent duplicate user creation race condition

Added unique constraint on (tenant_id, email) and
retry logic for concurrent user registration.

Fixes #89
```

---

### 1.3 Pull Request Process

#### **PR Checklist** (must be completed before review):
- [ ] Tests added/updated (unit + integration)
- [ ] Documentation updated (README, API docs, inline comments)
- [ ] No hardcoded values (use constants or config)
- [ ] i18n keys exist for all user-facing messages
- [ ] Linter passes (`bundle exec rubocop`)
- [ ] Code coverage ≥ 80% for new code
- [ ] Breaking changes documented in PR description
- [ ] Database migrations included (if schema changed)

#### **PR Size Guidelines**:
- **Ideal**: < 300 lines changed
- **Maximum**: < 500 lines changed
- **Too Large**: > 500 lines (split into smaller PRs)

#### **Review Process**:
1. **Self-Review**: Author reviews own code in GitHub UI before requesting review
2. **Automated Checks**: CI must pass (tests, linting, coverage)
3. **Peer Review**: At least 1 approval from team member
4. **Security Review**: Required for auth, crypto, or security-related changes
5. **Merge**: Squash and merge (keep main history clean)

---

### 1.4 Code Review Standards

#### **What Reviewers Check**:
- [ ] **Correctness**: Does it solve the problem?
- [ ] **Architecture**: Follows Clean Architecture and SOLID principles?
- [ ] **Security**: No security vulnerabilities (SQL injection, XSS, etc.)?
- [ ] **Performance**: No N+1 queries, unnecessary allocations?
- [ ] **Readability**: Clear naming, appropriate comments?
- [ ] **Tests**: Adequate test coverage, edge cases handled?
- [ ] **Error Handling**: Errors properly wrapped and logged?
- [ ] **i18n**: No hardcoded user-facing strings?

#### **Review Tone**:
- Be kind and constructive
- Explain the "why" behind suggestions
- Nitpicks: Prefix with "nit:" (non-blocking)
- Blocking issues: Clearly state "This must be fixed before merge"

---

## 2. Coding Standards

### 2.1 Ruby on Rails Style Guide

**Follow**:
- [Ruby Style Guide](https://rubystyle.guide/) (Community-driven)
- [Rails Style Guide](https://rails.rubystyle.guide/)
- [RuboCop](https://rubocop.org/) (Linter and formatter)

#### **Naming Conventions**:
- **Files**: Snake_case (e.g., `user_service.rb`, `authentication_controller.rb`)
- **Classes/Modules**: PascalCase (e.g., `UserService`, `AuthenticationController`)
- **Methods/Variables**: snake_case (e.g., `create_user`, `user_name`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `STATUS_ACTIVE`, `MAX_RETRIES`)
- **Private methods**: Prefix with `private` keyword

#### **Method Length**:
- **Ideal**: < 10 lines
- **Maximum**: < 25 lines
- **Too Long**: > 25 lines (refactor into smaller methods)

#### **File Organization**:
```ruby
# 1. Frozen string literal comment
# frozen_string_literal: true

# 2. Module/Class documentation
# Service for managing user operations
class UserService
  # 3. Constants
  STATUS_ACTIVE = 'active'
  STATUS_INACTIVE = 'inactive'

  # 4. Class methods
  def self.build(repo:, validator:)
    new(repo: repo, validator: validator)
  end

  # 5. Initialize
  def initialize(repo:, validator:)
    @repo = repo
    @validator = validator
  end

  # 6. Public instance methods
  def create_user(user)
    @validator.validate!(user)
    @repo.create(user)
  end

  # 7. Private methods
  private

  def log_creation(user)
    Rails.logger.info("User created: #{user.id}")
  end
end
```

---

### 2.2 Error Handling

#### **Always handle exceptions**:
```ruby
# ❌ Bad
user = service.get_by_id(id) rescue nil

# ✅ Good
begin
  user = service.get_by_id(id)
rescue Errors::UserNotFound => e
  raise "Failed to get user: #{e.message}"
end
```

#### **Use specific exception classes**:
```ruby
class UserService
  def create_user(request)
    validate_request!(request)
    @repo.create(request)
  rescue ValidationError => e
    raise "Validation failed: #{e.message}"
  rescue ActiveRecord::RecordNotUnique => e
    raise Errors::UserAlreadyExists, "User already exists"
  rescue => e
    raise "Failed to create user: #{e.message}"
  end

  private

  def validate_request!(request)
    raise ValidationError, 'Email is required' if request.email.blank?
  end
end
```

#### **Use custom exceptions for known cases**:
```ruby
# app/models/errors.rb
module Errors
  class UserNotFound < StandardError; end
  class UserAlreadyExists < StandardError; end
  class ValidationError < StandardError; end
end

# Check with rescue
begin
  user = service.find_user(id)
rescue Errors::UserNotFound
  # Handle specific error
  Rails.logger.warn("User not found: #{id}")
  nil
end
```

---

### 2.3 Request Context

#### **Use Current Attributes for request-scoped data**:
```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :tenant, :request_id
end

# In middleware or controller
class ApplicationController < ActionController::API
  before_action :set_current_attributes

  private

  def set_current_attributes
    Current.user = current_user
    Current.tenant = current_tenant
    Current.request_id = request.uuid
  end
end

# Access in services
class UserService
  def create_user(params)
    user = User.new(params)
    user.created_by = Current.user.id
    user.tenant_id = Current.tenant.id
    @repo.create(user)
  end
end
```

#### **Don't store request state in instance variables (across requests)**:
```ruby
# ❌ Bad (not thread-safe for concurrent requests)
class UserService
  attr_accessor :current_user
  
  def create_user(params)
    # @current_user might be from different request!
  end
end

# ✅ Good (use Current attributes)
class UserService
  def create_user(params)
    user = User.new(params)
    user.created_by = Current.user.id  # Thread-safe
    @repo.create(user)
  end
end
```

---

### 2.4 Logging Standards

#### **Structured Logging** (using semantic_logger or lograge):
```ruby
# With Rails default logger
Rails.logger.info "User created",
  user_id: user.id,
  email: user.email,
  tenant_id: user.tenant_id

# With semantic_logger (recommended)
Rails.logger.info('User created', user_id: user.id, email: user.email)

# ❌ Bad (string interpolation loses structure)
Rails.logger.info("User #{user.id} created with email #{user.email}")
```

#### **Log Levels**:
- **ERROR**: System failure, requires immediate attention
  - Database connection lost, unhandled exceptions, IDP unreachable
- **WARN**: Recoverable issue, potential problem
  - Invalid login attempt, rate limit hit, deprecated API used
- **INFO**: Significant lifecycle events
  - Server started, user logged in, configuration changed
- **DEBUG**: Granular flow details (dev/staging only)
  - Method entry/exit, variable values, detailed traces

#### **Never Log PII**:
```ruby
# ❌ Bad
Rails.logger.info("User login", password: password)

# ✅ Good
Rails.logger.info('User login',
  user_id: user_id,
  ip_address: request.remote_ip
)
```

#### **Configure structured logging (config/application.rb)**:
```ruby
# Using lograge for structured JSON logs
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
config.lograge.custom_options = lambda do |event|
  {
    user_id: Current.user&.id,
    tenant_id: Current.tenant&.id,
    request_id: event.payload[:request_id]
  }
end
```

---

## 3. Testing Standards

### 3.1 Test Pyramid

```
       /\
      /  \
     / E2E \ ← 10% (slow, brittle, expensive)
    /______\
   /        \
  / Integration\ ← 20% (medium speed, moderate cost)
 /____________\
/              \
/  Unit Tests  \ ← 70% (fast, cheap, reliable)
/________________\
```

#### **Coverage Requirements**:
- **Overall**: ≥ 80%
- **Domain Layer**: ≥ 95% (pure logic, easy to test)
- **Service Layer**: ≥ 90%
- **Infrastructure Layer**: ≥ 70% (integration tests)

---

### 3.2 Unit Tests

**Structure**: Arrange-Act-Assert (AAA) or RSpec's Given-When-Then

```ruby
# spec/services/user_service_spec.rb
require 'rails_helper'

RSpec.describe UserService do
  describe '#create_user' do
    it 'creates a user successfully with valid input' do
      # Arrange
      mock_repo = instance_double(UserRepository)
      allow(mock_repo).to receive(:create).and_return(true)

      mock_validator = instance_double(UserValidator)
      allow(mock_validator).to receive(:validate!).and_return(true)

      service = described_class.new(repo: mock_repo, validator: mock_validator)

      request = { email: 'test@example.com', name: 'Test User' }

      # Act
      result = service.create_user(request)

      # Assert
      expect(result).to be_truthy
      expect(mock_repo).to have_received(:create).with(request)
      expect(mock_validator).to have_received(:validate!).with(request)
    end
  end
end
```

#### **Table-Driven Tests** (for multiple scenarios):
```ruby
# spec/validators/email_validator_spec.rb
require 'rails_helper'

RSpec.describe EmailValidator do
  describe '.valid_email?' do
    [
      { email: 'user@example.com', expected: true, description: 'valid email' },
      { email: 'userexample.com', expected: false, description: 'missing @' },
      { email: 'user@', expected: false, description: 'missing domain' },
      { email: '', expected: false, description: 'empty string' },
      { email: 'user+tag@example.com', expected: true, description: 'plus addressing' }
    ].each do |test_case|
      context "with #{test_case[:description]}" do
        it "returns #{test_case[:expected]}" do
          result = described_class.valid_email?(test_case[:email])
          expect(result).to eq(test_case[:expected])
        end
      end
    end
  end
end

# Alternative using RSpec's shared examples
RSpec.shared_examples 'email validation' do |email, should_be_valid|
  it "#{should_be_valid ? 'accepts' : 'rejects'} #{email.inspect}" do
    result = EmailValidator.valid_email?(email)
    expect(result).to eq(should_be_valid)
  end
end

RSpec.describe EmailValidator do
  describe '.valid_email?' do
    include_examples 'email validation', 'user@example.com', true
    include_examples 'email validation', 'userexample.com', false
    include_examples 'email validation', 'user@', false
    include_examples 'email validation', '', false
    include_examples 'email validation', 'user+tag@example.com', true
  end
end
```

---

### 3.3 Integration Tests

**Test real dependencies** (database, Redis, external APIs):

```ruby
# spec/integration/user_repository_spec.rb
require 'rails_helper'

RSpec.describe UserRepository, type: :integration do
  let(:repository) { described_class.new(ActiveRecord::Base.connection) }

  describe '#create and #get_by_id' do
    it 'creates and retrieves a user from database' do
      # Create user
      user_data = {
        id: SecureRandom.uuid,
        tenant_id: SecureRandom.uuid,
        email: 'test@example.com',
        created_at: Time.current
      }

      repository.create(user_data)

      # Retrieve user
      retrieved = repository.get_by_id(user_data[:id])
### 6.1 Inline Comments

**When to comment**:
- ✅ **Why**, not **what** (code shows what, comments explain why)
- ✅ Complex algorithms or business logic
- ✅ Non-obvious edge cases or workarounds
- ❌ Obvious code (don't comment self-explanatory code)

```ruby
# ❌ Bad (obvious)
# Increment counter
counter += 1

# ✅ Good (explains why)
# We must cache tokens for 5 minutes to avoid overwhelming the IDP
# with introspection requests on every API call
token_cache.write(token, claims, expires_in: 5.minutes)
```

### 6.2 Package Documentation

**Every package should have a doc.go**:

```ruby
# app/services/user_service.rb

# Service for user management operations.
#
# The user service orchestrates user CRUD operations by delegating
# to the configured Identity Provider adapter and persisting metadata
# in the local database.
#
# @example Creating a user
#   service = UserService.new(user_repo, logger)
#   user = service.create_user(email: 'user@example.com', name: 'John Doe')
#
class UserService
  # Creates a new user
  #
  # @param params [Hash] User parameters
  # @option params [String] :email User's email address
  # @option params [String] :name User's full name
  # @return [User] The created user
  # @raise [ValidationError] if parameters are invalid
  def create_user(params)
    # Implementation
  end
end
```

---

## 7. Continuous Integration (CI)

### 7.1 CI Pipeline (GitHub Actions)

```yaml
name: CI

on: [push, pull_request]
---

## 8. Performance Best Practices

### 8.1 Avoid N+1 Queries

```ruby
# ❌ Bad: N+1 query
class UserService
  def get_users_with_roles(user_ids)
    users = []
    user_ids.each do |id|
      user = User.find(id)
      user.roles = Role.where(user_id: id).to_a  # N queries!
      users << user
    end
    users
  end
end

# ✅ Good: Eager loading with ActiveRecord
class UserService
  def get_users_with_roles(user_ids)
    User.includes(:roles).where(id: user_ids).to_a  # 1-2 queries with JOIN
  end
end

# ✅ Alternative: Use preload for separate queries
class UserService
  def get_users_with_roles(user_ids)
    User.preload(:roles).where(id: user_ids).to_a  # 2 queries (efficient for large datasets)
  end
end
```

### 8.2 Use Connection Pooling

```ruby
# config/database.yml
production:
  adapter: postgresql
  pool: <%= ENV.fetch("DB_POOL_SIZE") { 25 } %>  # Max concurrent connections
  timeout: 5000  # Connection timeout (ms)
  connect_timeout: 2  # Connection establishment timeout
  checkout_timeout: 5  # Pool checkout timeout

# config/initializers/database.rb
ActiveRecord::Base.connection_pool.with_connection do |conn|
  conn.execute("SET statement_timeout = '30s'")  # Query timeout
end
```

### 8.3 Implement Caching

```ruby
# Gemfile
gem 'redis-rails'  # or use Rails.cache with Redis store

class UserService
  def get_by_id(id)
    # Check cache first (Rails.cache uses configured cache store)
    Rails.cache.fetch("user:#{id}", expires_in: 5.minutes) do
      # Cache miss: fetch from repository
      User.find(id)
    end
  end
  
  # Alternative: Manual cache management
  def get_by_id_manual(id)
    cache_key = "user:#{id}"
    
    # Check cache
    cached = Rails.cache.read(cache_key)
    return cached if cached
    
    # Fetch from database
    user = User.find(id)
    
    # Store in cache (TTL: 5 minutes)
    Rails.cache.write(cache_key, user, expires_in: 5.minutes)
    
    user
  end
end
```

---

## 9. Definition of Done

Before marking a task as complete, verify:

- [ ] **Code**: Follows style guide, Clean Architecture, SOLID principles
- [ ] **Tests**: Unit tests (≥80% coverage), integration tests for critical paths
- [ ] **Linting**: `bundle exec rubocop` passes with zero offenses
- [ ] **Documentation**: README updated, API docs generated, inline comments added
- [ ] **i18n**: All user-facing strings use i18n keys (keys exist in locales)
- [ ] **Logging**: Structured logs, appropriate levels, no PII logged
- [ ] **Error Handling**: Errors wrapped, domain errors mapped to HTTP codes
- [ ] **Performance**: No N+1 queries, connection pooling configured
- [ ] **Security**: No hardcoded secrets, input validation, SQL injection prevented
- [ ] **Migrations**: Database migrations included (if schema changed)
- [ ] **PR**: Created, self-reviewed, peer-reviewed, CI passed

---

**Remember**: "Quality is not an act, it is a habit." — Aristotle
