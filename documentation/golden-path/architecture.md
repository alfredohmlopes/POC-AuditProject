# Architecture Golden Path

> **"Good architecture makes the system easy to understand, easy to develop, easy to maintain, and easy to deploy."**  
> — Robert C. Martin (Uncle Bob)

---

## 1. Core Principles

### 1.1 Clean Architecture (The Law)

**The Dependency Rule**: Source code dependencies must only point **inwards**, toward higher-level policies.

```
┌─────────────────────────────────────────┐
│   Infrastructure Layer (Adapters)      │ ← Frameworks, DB, HTTP, External APIs
│   - HTTP Handlers                       │
│   - Database Repositories               │
│   - External API Clients                │
└─────────────────────────────────────────┘
             ↓ depends on
┌─────────────────────────────────────────┐
│   Service Layer (Application Logic)    │ ← Use Cases, Business Rules
│   - Auth Service                        │
│   - User Service                        │
│   - Tenant Service                      │
└─────────────────────────────────────────┘
             ↓ depends on
┌─────────────────────────────────────────┐
│   Domain Layer (Entities & Interfaces) │ ← Pure Business Logic
│   - User Entity                         │
│   - Repository Interfaces               │
│   - Domain Events                       │
└─────────────────────────────────────────┘
```

#### Rules:
1. **Domain Layer**: MUST have ZERO external dependencies (no SQL, no HTTP, no frameworks)
2. **Service Layer**: Can depend on Domain, but NOT on Infrastructure
3. **Infrastructure Layer**: Implements interfaces defined in Domain/Service layers
4. **Dependencies**: Always point INWARD (Infrastructure → Service → Domain)

---

### 1.2 SOLID Principles

#### **S - Single Responsibility Principle**
> A class should have one, and only one, reason to change.

**❌ Bad**:
```ruby
# UserService does too many things
class UserService
  def initialize
    @db = ActiveRecord::Base.connection
  end

  def create_user(user)
    # Validates user
    # Sends email
    # Logs audit
    # Saves to DB
  end
end
```

**✅ Good**:
```ruby
# Each service has ONE responsibility
class UserService
  def initialize(repo:, validator:, email_service:, audit_service:)
    @repo = repo
    @validator = validator
    @email_service = email_service
    @audit_service = audit_service
  end

  def create_user(user)
    # Orchestrates, delegates to specialized services
    @validator.validate!(user)
    @repo.create(user)
    @email_service.send_welcome_email(user.email)
    @audit_service.log_user_created(user.id)
    user
  rescue ValidationError => e
    raise e
  end
end
```

---

#### **O - Open/Closed Principle**
> Entities should be open for extension, but closed for modification.

**✅ Use Strategy Pattern for IDP abstraction**:
```ruby
# Closed for modification (module interface doesn't change)
module IdentityProviderAdapter
  def create_user(request)
    raise NotImplementedError, "#{self.class} must implement #create_user"
  end
end

# Open for extension (add new IDPs without changing existing code)
class KeycloakAdapter
  include IdentityProviderAdapter
  # implementation
end

class OryAdapter
  include IdentityProviderAdapter
  # implementation
end

class ZitadelAdapter
  include IdentityProviderAdapter
  # implementation
end
```

---

#### **L - Liskov Substitution Principle**
> Subtypes must be substitutable for their base types.

**❌ Bad**:
```ruby
module Repository
  def get(id)
    raise NotImplementedError
  end

  def save(user)
    raise NotImplementedError
  end
end

class ReadOnlyRepository
  include Repository

  def save(user)
    raise "Not implemented" # ❌ Violates LSP!
  end
end
```

**✅ Good**:
```ruby
# Separate modules for different capabilities
module UserReader
  def get(id)
    raise NotImplementedError
  end
end

module UserWriter
  def save(user)
    raise NotImplementedError
  end
end

class UserRepository
  include UserReader
  include UserWriter
  
  # implements both read and write methods
end
```

---

#### **I - Interface Segregation Principle**
> Many client-specific interfaces are better than one general-purpose interface.

**❌ Bad**:
```ruby
module UserRepository
  def create(user); end
  def get_by_id(id); end
  def update(user); end
  def delete(id); end
  def search(query); end
  def bulk_import(users); end
  def export; end
  # ... 20 more methods
end
```

**✅ Good**:
```ruby
module UserReader
  def get_by_id(id)
    raise NotImplementedError
  end

  def search(query)
    raise NotImplementedError
  end
end

module UserWriter
  def create(user)
    raise NotImplementedError
  end

  def update(user)
    raise NotImplementedError
  end

  def delete(id)
    raise NotImplementedError
  end
end

module UserBulkOperations
  def bulk_import(users)
    raise NotImplementedError
  end

  def export
    raise NotImplementedError
  end
end

# Compose as needed
class UserRepository
  include UserReader
  include UserWriter
  
  # implements only read and write methods
end
```

---

#### **D - Dependency Inversion Principle**
> Depend on abstractions, not concretions.

**❌ Bad**:
```ruby
class UserService
  def initialize
    @db = PostgresDB.new # ❌ Concrete dependency
  end
end
```

**✅ Good**:
```ruby
# Abstract interface using module
module UserRepository
  def create(user)
    raise NotImplementedError
  end
end

class UserService
  def initialize(repo:)
    @repo = repo # ✅ Depends on abstraction
  end

  def create_user(user)
    @repo.create(user)
  end
end

# Infrastructure layer provides concrete implementation
class PostgresUserRepository
  include UserRepository

  def initialize(db_connection)
    @db = db_connection
  end

  def create(user)
    # PostgreSQL-specific implementation
    @db.execute("INSERT INTO users ...")
  end
end
```

---

## 2. Domain-Driven Design (DDD) Patterns

### 2.1 Entities vs Value Objects

**Entity**: Has identity, lifecycle, mutable
```ruby
class User
  attr_accessor :id, :email, :created_at

  def initialize(id:, email:, created_at: Time.current)
    @id = id           # Identity
    @email = email
    @created_at = created_at
  end
end
```

**Value Object**: Immutable, defined by attributes, no identity
```ruby
class EmailAddress
  attr_reader :value

  def initialize(email)
    raise ArgumentError, 'Invalid email' unless valid_email?(email)
    @value = email
  end

  def to_s
    @value
  end

  private

  def valid_email?(email)
    email.match?(/\A[^@\s]+@[^@\s]+\z/)
  end
end
```

---

### 2.2 Aggregates & Aggregate Roots

**Aggregate**: Cluster of entities treated as a single unit for data changes

```ruby
# User is the Aggregate Root
class User
  attr_accessor :id, :email, :mfa_enrollments, :sessions

  def initialize(id:, email:)
    @id = id
    @email = email
    @mfa_enrollments = []  # Part of User aggregate
    @sessions = []         # Part of User aggregate
  end
end

# MFAEnrollment cannot exist without User
class MFAEnrollment
  attr_accessor :id, :user_id, :type

  def initialize(id:, user_id:, type:)
    @id = id
    @user_id = user_id  # Foreign key to aggregate root
    @type = type
  end
end
```

**Rule**: Always access child entities through the aggregate root.

---

### 2.3 Repositories

**One repository per aggregate root**:
```ruby
module UserRepository
  # User CRUD
  def create(user)
    raise NotImplementedError
  end

  def get_by_id(id)
    raise NotImplementedError
  end

  def update(user)
    raise NotImplementedError
  end

  # MFA operations go through User repository
  def add_mfa_enrollment(user_id, enrollment)
    raise NotImplementedError
  end

  def remove_mfa_enrollment(user_id, enrollment_id)
    raise NotImplementedError
  end
end

# ❌ Don't create MFARepository - MFA is not an aggregate root
```

---

### 2.4 Domain Events

**Decouple side effects using events**:
```ruby
# Using ActiveSupport::Notifications (Rails built-in)
class DomainEvent
  attr_reader :occurred_at, :event_type

  def initialize
    @occurred_at = Time.current
  end

  def event_type
    self.class.name.underscore
  end
end

class UserCreatedEvent < DomainEvent
  attr_reader :user_id, :email, :tenant_id

  def initialize(user_id:, email:, tenant_id:)
    super()
    @user_id = user_id
    @email = email
    @tenant_id = tenant_id
  end
end

# In UserService
class UserService
  def create_user(request)
    user = build_user(request)
    @repo.create(user)

    # Publish event (async)
    event = UserCreatedEvent.new(
      user_id: user.id,
      email: user.email,
      tenant_id: user.tenant_id
    )
    ActiveSupport::Notifications.instrument('user.created', event: event)

    user
  end
end

# Event handlers listen and react
class WelcomeEmailHandler
  def initialize(email_service)
    @email_service = email_service
  end

  def self.subscribe
    ActiveSupport::Notifications.subscribe('user.created') do |_name, _start, _finish, _id, payload|
      new(EmailService.new).handle(payload[:event])
    end
  end

  def handle(event)
    @email_service.send_welcome_email(event.email) if event.is_a?(UserCreatedEvent)
  end
end
```

---

## 3. Package Structure

### 3.1 Standard Layout

```
IGAWorkflow/
├── app/
│   ├── controllers/                  # ← INFRASTRUCTURE (HTTP)
│   │   ├── api/
│   │   │   ├── auth_controller.rb
│   │   │   └── users_controller.rb
│   │   └── application_controller.rb
│   ├── models/                       # ← DOMAIN LAYER
│   │   ├── concerns/                 # Shared modules
│   │   ├── user.rb                   # Entity
│   │   ├── tenant.rb
│   │   └── value_objects/
│   │       └── email_address.rb
│   ├── services/                     # ← APPLICATION LOGIC (SERVICE LAYER)
│   │   ├── auth/
│   │   │   └── authentication_service.rb
│   │   ├── users/
│   │   │   └── user_service.rb
│   │   └── tenants/
│   │       └── tenant_service.rb
│   ├── repositories/                 # ← INFRASTRUCTURE (Persistence)
│   │   ├── user_repository.rb
│   │   └── tenant_repository.rb
│   ├── adapters/                     # ← INFRASTRUCTURE (External Services)
│   │   └── idp/
│   │       ├── keycloak_adapter.rb
│   │       ├── ory_adapter.rb
│   │       └── adapter_factory.rb
│   ├── middleware/                   # HTTP middleware
│   │   ├── authentication.rb
│   │   └── rate_limiter.rb
│   └── validators/                   # Validation logic
│       └── user_validator.rb
├── config/
│   ├── application.rb                # Main configuration
│   ├── database.yml
│   ├── routes.rb
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   └── initializers/
│       ├── cors.rb
│       └── inflections.rb
├── db/
│   ├── migrate/                      # Database migrations
│   │   └── 20250101000001_create_users.rb
│   └── schema.rb
├── lib/
│   ├── crypto/                       # Shared utilities
│   └── logger/
├── spec/                             # Tests (RSpec)
│   ├── models/
│   ├── services/
│   ├── requests/                     # Integration tests
│   └── support/
├── public/                           # Static files
├── Gemfile                           # Dependencies
└── config.ru                         # Rack configuration
```

---

### 3.2 Dependency Injection

**Use constructor injection**:
```ruby
# config/initializers/dependencies.rb
Rails.application.config.after_initialize do
  # Infrastructure
  db = ActiveRecord::Base.connection
  cache = Redis.new(url: ENV['REDIS_URL'])
  logger = Rails.logger

  # Repositories
  user_repo = UserRepository.new(db)
  tenant_repo = TenantRepository.new(db)

  # IDP Adapters
  idp_factory = IdpAdapterFactory.new(tenant_repo, logger)

  # Services (Register as singletons)
  Rails.application.config.user_service = UserService.new(
    repo: user_repo,
    logger: logger
  )

  Rails.application.config.auth_service = AuthService.new(
    idp_factory: idp_factory,
    cache: cache,
    logger: logger
  )
end

# In controllers, access services
class Api::UsersController < ApplicationController
  def initialize
    super
    @user_service = Rails.application.config.user_service
  end

  def create
    user = @user_service.create_user(user_params)
    render json: user, status: :created
  end
end
```

---

## 4. Architectural Patterns

### 4.1 Adapter Pattern (for IDP abstraction)

```ruby
# Domain defines the interface (module)
module IdentityProviderAdapter
  def create_user(request)
    raise NotImplementedError
  end

  def get_user(user_id)
    raise NotImplementedError
  end
end

# Infrastructure provides implementations
class KeycloakAdapter
  include IdentityProviderAdapter

  def initialize(client, config)
    @client = client
    @config = config
  end

  def create_user(request)
    # Translate request to Keycloak format
    kc_user = map_to_keycloak_user(request)

    # Call Keycloak API
    user_id = @client.create_user(@config.realm, kc_user)

    # Fetch and translate response back
    created_user = @client.get_user_by_id(@config.realm, user_id)
    map_from_keycloak_user(created_user)
  rescue KeycloakError => e
    raise map_keycloak_error(e)
  end

  private

  def map_to_keycloak_user(request)
    # mapping logic
  end

  def map_from_keycloak_user(kc_user)
    # mapping logic
  end

  def map_keycloak_error(error)
    # error mapping logic
  end
end
```

---

### 4.2 Repository Pattern

```ruby
# Domain defines interface (module)
module UserRepository
  def create(user)
    raise NotImplementedError
  end

  def get_by_id(id)
    raise NotImplementedError
  end

  def get_by_email(tenant_id, email)
    raise NotImplementedError
  end

  def update(user)
    raise NotImplementedError
  end

  def delete(id)
    raise NotImplementedError
  end
end

# Infrastructure implements
class PostgresUserRepository
  include UserRepository

  def initialize(db_connection)
    @db = db_connection
  end

  def create(user)
    sql = <<-SQL
      INSERT INTO users (id, tenant_id, email, created_at)
      VALUES (?, ?, ?, ?)
    SQL
    @db.execute(sql, user.id, user.tenant_id, user.email, user.created_at)
  end

  def get_by_id(id)
    sql = "SELECT * FROM users WHERE id = ?"
    result = @db.execute(sql, id).first
    map_to_user(result) if result
  end

  private

  def map_to_user(row)
    User.new(
      id: row['id'],
      tenant_id: row['tenant_id'],
      email: row['email'],
      created_at: row['created_at']
    )
  end
end
```

---

### 4.3 Factory Pattern (for multi-IDP)

```ruby
class AdapterFactory
  def initialize(tenant_repo, logger)
    @tenant_repo = tenant_repo
    @cache = {}
    @logger = logger
  end

  def get_adapter(tenant_id)
    tenant = @tenant_repo.get_by_id(tenant_id)
    raise "Tenant not found" unless tenant

    case tenant.idp_type
    when 'keycloak'
      KeycloakAdapter.new(tenant.idp_config, @logger)
    when 'ory'
      OryAdapter.new(tenant.idp_config, @logger)
    else
      raise "Unsupported IDP type: #{tenant.idp_type}"
    end
  end
end
```

---

## 5. Error Handling Architecture

### 5.1 Domain Errors

```ruby
# app/models/errors.rb
module Errors
  class UserNotFound < StandardError; end
  class UserAlreadyExists < StandardError; end
  class InvalidEmail < StandardError; end
end
```

### 5.2 Service Layer Error Wrapping

```ruby
class UserService
  def get_by_email(email)
    user = @repo.get_by_email(email)
    raise Errors::UserNotFound, 'User not found' if user.nil?
    user
  rescue ActiveRecord::RecordNotFound
    raise Errors::UserNotFound, 'User not found'
  rescue => e
    raise "Failed to get user: #{e.message}"
  end
end
```

### 5.3 HTTP Error Mapping

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  rescue_from Errors::UserNotFound, with: :render_not_found
  rescue_from Errors::UserAlreadyExists, with: :render_conflict
  rescue_from Errors::InvalidEmail, with: :render_bad_request
  rescue_from StandardError, with: :render_internal_error

  private

  def render_not_found(exception)
    render json: { code: 'user_not_found', message: 'User not found' }, status: :not_found
  end

  def render_conflict(exception)
    render json: { code: 'user_exists', message: 'User already exists' }, status: :conflict
  end

  def render_bad_request(exception)
    render json: { code: 'invalid_email', message: 'Invalid email format' }, status: :bad_request
  end

  def render_internal_error(exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))
    render json: { code: 'internal_error', message: 'Internal server error' }, status: :internal_server_error
  end
end
```

---

## 6. Configuration Management

### 6.1 Environment-Based Config

```ruby
# config/application.rb
module IGAWorkflow
  class Application < Rails::Application
    config.load_defaults 7.0

    # Server Configuration
    config.server_port = ENV.fetch('PORT', '3000')
    config.server_read_timeout = ENV.fetch('SERVER_READ_TIMEOUT', '10').to_i
    config.server_write_timeout = ENV.fetch('SERVER_WRITE_TIMEOUT', '10').to_i

    # Database Configuration (config/database.yml handles this)
    config.database_url = ENV.fetch('DATABASE_URL')
    config.db_pool_size = ENV.fetch('DB_POOL_SIZE', '5').to_i
    config.db_timeout = ENV.fetch('DB_TIMEOUT', '5000').to_i

    # Redis Configuration
    config.redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')

    # IDP Configuration
    config.idp_type = ENV.fetch('IDP_TYPE', 'keycloak')
    config.idp_url = ENV.fetch('IDP_URL')

    # Logging
    config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym
    config.log_formatter = ::Logger::Formatter.new

    # Middleware
    config.api_only = true
  end
end

# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("DB_POOL_SIZE", 5) %>
  timeout: <%= ENV.fetch("DB_TIMEOUT", 5000) %>

development:
  <<: *default
  database: igaworkflow_development
  url: <%= ENV.fetch("DATABASE_URL", "postgresql://localhost/igaworkflow_development") %>

test:
  <<: *default
  database: igaworkflow_test

production:
  <<: *default
  url: <%= ENV.fetch("DATABASE_URL") { raise "DATABASE_URL must be set" } %>
```

---

## 7. Checklist: Architecture Review

Before merging any feature, verify:

- [ ] **Clean Architecture**: Dependencies point inward (Infrastructure → Service → Domain)
- [ ] **SOLID**: Single responsibility, modules/interfaces not implementations, no LSP violations
- [ ] **Domain Purity**: Domain layer has zero external dependencies
- [ ] **Dependency Injection**: No global variables, all dependencies injected via constructor
- [ ] **Error Handling**: Domain errors defined, properly raised/rescued, mapped to HTTP codes
- [ ] **Interfaces**: Small, focused modules/interfaces (ISP)
- [ ] **Repository Pattern**: One repo per aggregate root
- [ ] **Config**: No hardcoded values, all config from environment
- [ ] **Package Structure**: Follows standard layout

---

**Principle**: "Architecture is about intent, not frameworks. A good architecture allows you to defer decisions about frameworks, databases, and web servers until the last possible moment."
