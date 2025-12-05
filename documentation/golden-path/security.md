# Security Golden Path

> **"Security is not a product, but a process."**  
> — Bruce Schneier

---

## 1. Security Principles

### 1.1 Zero Trust Architecture

**Never trust, always verify**:
- ✅ Validate EVERY input (API requests, user input, IDP responses)
- ✅ Authenticate EVERY request (no unauthenticated endpoints for sensitive data)
- ✅ Authorize EVERY action (check permissions, not just authentication)
- ✅ Encrypt EVERYTHING in transit and at rest
- ❌ No implicit trust based on network location

---

### 1.2 Defense in Depth

**Multiple layers of security**:

```
Layer 1: Edge (WAF, DDoS protection, Rate limiting)
         ↓
Layer 2: API Gateway (TLS, JWT validation, Input validation)
         ↓
Layer 3: Application (RBAC, Business logic validation)
         ↓
Layer 4: Database (Row-level security, Encryption at rest)
```

---

## 2. Authentication & Authorization

### 2.1 JWT Validation

**Use the JWT gem for token validation**:

```ruby
# Gemfile
gem 'jwt'

# app/services/auth/token_validator.rb
module Auth
  class TokenValidator
    SECRET_KEY = Rails.application.credentials.jwt_secret!
    ALGORITHM = 'HS256'

    def self.validate_token(token)
      payload, = JWT.decode(
        token,
        SECRET_KEY,
        true,
        { algorithm: ALGORITHM }
      )

      # Validate claims
      raise 'Token expired' if payload['exp'] < Time.current.to_i
      raise 'Invalid issuer' unless payload['iss'] == 'igaworkflow'
      raise 'Invalid audience' unless payload['aud'] == 'api'

      payload
    rescue JWT::DecodeError => e
      raise "Invalid token: #{e.message}"
    end
  end
end

# Usage in ApplicationController
class ApplicationController < ActionController::API
  before_action :authenticate_request

  private

  def authenticate_request
    token = request.headers['Authorization']&.split(' ')&.last
    raise 'No token provided' unless token

    @current_user_payload = Auth::TokenValidator.validate_token(token)
  rescue => e
    render json: { error: e.message }, status: :unauthorized
  end

  def current_user_id
    @current_user_payload['sub']
  end
end
```

#### **Token Lifetime**:
- **Access Token**: 15 minutes (short-lived)
- **Refresh Token**: 7 days (revocable)
- **ID Token**: 15 minutes

#### **Token Storage**:
- **Access Token**: Memory only (never localStorage in browser)
- **Refresh Token**: HttpOnly, Secure, SameSite cookie
- **Never**: Store tokens in localStorage (XSS vulnerable)

---

### 2.2 Password Security

**Use BCrypt for password hashing** (Rails provides `has_secure_password`):

```ruby
# Gemfile (bcrypt is usually included in Rails)
gem 'bcrypt', '~> 3.1.7'

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  # This adds:
  # - password and password_confirmation virtual attributes
  # - password_digest column requirement
  # - validations
  # - authenticate method
  
  validates :password,
    length: { minimum: 12 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/,
      message: 'must include uppercase, lowercase, number, and special character'
    },
    if: -> { password.present? }
end

# Migration
class AddPasswordDigestToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :password_digest, :string, null: false
  end
end

# Usage - Creating a user
user = User.create(
  email: 'user@example.com',
  password: 'SecurePass123!',
  password_confirmation: 'SecurePass123!'
)

# Authentication
user = User.find_by(email: 'user@example.com')
if user&.authenticate('SecurePass123!')
  # Password is correct
else
  # Invalid password
end
```

**Password Policy**:
- Minimum length: 12 characters
- Must include: uppercase, lowercase, number, special character
- Use bcrypt cost 12 or higher

---

### 2.3 Role-Based Access Control (RBAC)

**Use Pundit gem for authorization**:

```ruby
# Gemfile
gem 'pundit'

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include Pundit::Authorization
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action' }, 
           status: :forbidden
  end
end

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.user_manager?
  end
  
  def show?
    user.admin? || user.user_manager? || record.id == user.id
  end
  
  def create?
    user.admin? || user.user_manager?
  end
  
  def update?
    user.admin? || (user.user_manager? && record.tenant_id == user.tenant_id)
  end
  
  def destroy?
    user.admin?
  end
end

# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def index
    authorize User  # Checks UserPolicy#index?
    @users = User.all
    render json: @users
  end
  
  def show
    @user = User.find(params[:id])
    authorize @user  # Checks UserPolicy#show?
    render json: @user
  end
  
  def create
    authorize User
    @user = User.create!(user_params)
    render json: @user, status: :created
  end
  
  def update
    @user = User.find(params[:id])
    authorize @user
    @user.update!(user_params)
    render json: @user
  end
end

# app/models/user.rb (role methods)
class User < ApplicationRecord
  enum role: { user: 0, user_manager: 1, admin: 2 }
  
  def admin?
    role == 'admin'
  end
  
  def user_manager?
    role == 'user_manager'
  end
end
```

---

## 3. Input Validation & Sanitization

### 3.1 Validate All Inputs

**Use Strong Parameters and ActiveModel Validations**:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      render json: @user, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :name, :role)
  end
end

# app/models/user.rb
class User < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, inclusion: { in: %w[user user_manager admin] }
  
  # Custom validation
  validate :email_must_be_company_domain
  
  private
  
  def email_must_be_company_domain
    return if email.blank?
    
    unless email.end_with?('@company.com')
      errors.add(:email, 'must be a company email address')
    end
  end
end

# Custom validator class
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A[^@\s]+@[^@\s]+\z/
      record.errors.add(attribute, (options[:message] || 'is not a valid email'))
    end
  end
end

# Usage
class User < ApplicationRecord
  validates :email, email: true
end
```

---

### 3.2 Prevent SQL Injection

**Always use parameterized queries (ActiveRecord does this by default)**:

```ruby
# ❌ Bad (SQL injection vulnerability)
def search_users(query)
  User.where("name LIKE '%#{query}%'")  # NEVER DO THIS
end

# ✅ Good (parameterized query)
def search_users(query)
  User.where("name LIKE ?", "%#{query}%")
end

# ✅ Better (using named bind variables)
def search_users(query)
  User.where("name LIKE :query", query: "%#{query}%")
end

# ✅ Best (using Arel for complex queries)
def search_users(query)
  User.where(User.arel_table[:name].matches("%#{query}%"))
end

# ✅ Using scopes
class User < ApplicationRecord
  scope :search_by_name, ->(query) { where("name LIKE ?", "%#{query}%") }
  scope :search_by_email, ->(query) { where("email LIKE ?", "%#{query}%") }
end

# Usage
users = User.search_by_name(params[:query])
```

**For raw SQL** (use sparingly):
```ruby
# ❌ Bad
sql = "SELECT * FROM users WHERE id = #{id}"
ActiveRecord::Base.connection.execute(sql)

# ✅ Good
sql = "SELECT * FROM users WHERE id = ?"
ActiveRecord::Base.connection.exec_query(sql, 'SQL', [[nil, id]])

# ✅ Better (use sanitize_sql)
sql = ActiveRecord::Base.sanitize_sql_array(
  ["SELECT * FROM users WHERE id = ?", id]
)
ActiveRecord::Base.connection.execute(sql)
```

---

### 3.3 Prevent XSS (Cross-Site Scripting)

**Rails automatically escapes output in ERB views**:

```erb
<!-- Rails automatically escapes HTML by default -->
<%= @user.name %>  <!-- Safe, auto-escaped -->

<!-- To render HTML intentionally (use with extreme caution) -->
<%== @user.bio %>  <!-- or -->
<%= raw @user.bio %>  <!-- Unescaped -->
<%= @user.bio.html_safe %>  <!-- Mark as safe -->

<!-- Sanitize user HTML input -->
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: %w[href] %>
```

**For JSON APIs** (ActionController::API):
```ruby
# ✅ Safe (Rails handles escaping)
render json: { name: params[:name] }

# ⚠️ Be careful with html_safe in JSON
# Only use if you're certain the content is safe
render json: { html: @content.html_safe }
```

**Backend**:
- ✅ Validate and sanitize all inputs
- ✅ Use Content Security Policy (CSP) headers
-  ✅ Encode output (Rails does this automatically)

**Frontend** (React):
```jsx
// ✅ React auto-escapes by default
<div>{user.name}</div>

// ❌ Dangerous: dangerouslySetInnerHTML (avoid unless necessary)
<div dangerouslySetInnerHTML={{__html: userInput}} />

// ✅ If you must render HTML, sanitize first
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{__html: DOMPurify.sanitize(userInput)}} />
```

---

## 4. Cryptography

### 4.1 Encryption Standards

**Use**:
- ✅ TLS 1.3 (or TLS 1.2 minimum) for transport
- ✅ AES-256-GCM for encryption at rest
- ✅ RSA-4096 or ECDSA P-256 for asymmetric crypto
- ❌ No DES, 3DES, RC4 (deprecated/broken)

#### **Encrypt Sensitive Data**:
```ruby
# Rails provides ActiveSupport::MessageEncryptor
class ClientSecret
  def self.encrypt(secret)
    key = ActiveSupport::KeyGenerator.new(
      Rails.application.credentials.secret_key_base
    ).generate_key('client_secrets', 32)
    
    encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')
    encryptor.encrypt_and_sign(secret)
  end
  
  def self.decrypt(encrypted_secret)
    key = ActiveSupport::KeyGenerator.new(
      Rails.application.credentials.secret_key_base
    ).generate_key('client_secrets', 32)
    
    encryptor = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')
    encryptor.decrypt_and_verify(encrypted_secret)
  end
end

# Usage
encrypted = ClientSecret.encrypt('my-secret-value')
decrypted = ClientSecret.decrypt(encrypted)

# Or use Rails encrypted attributes (Rails 7+)
class Client < ApplicationRecord
  encrypts :secret
end
```

---

### 4.2 Secrets Management

**Never commit secrets**:

```ruby
# ❌ Bad: Hardcoded secret
JWT_SECRET = "my-super-secret-key"

# ✅ Good: Load from Rails credentials
# Run: rails credentials:edit
jwt_secret = Rails.application.credentials.jwt_secret!

# ✅ Better: Environment-specific credentials
# config/credentials/production.yml.enc
jwt_secret = Rails.application.credentials.jwt_secret!

# ✅ Best: Use Doppler, Vault, AWS Secrets Manager
# Gemfile
gem 'aws-sdk-secretsmanager'

# config/initializers/secrets.rb
if Rails.env.production?
  client = Aws::SecretsManager::Client.new(region: 'us-east-1')
  secret = client.get_secret_value(secret_id: "jwt-secret")
  Rails.application.credentials.jwt_secret = secret.secret_string
end
```

**Secrets Checklist**:
- [ ] All secrets in Rails credentials (encrypted)
- [ ] Secrets rotated regularly (every 90 days)
- [ ] Secrets never logged or exposed in errors
- [ ] Secrets encrypted at rest
- [ ] `.env` files in `.gitignore` (if using dotenv gem)

---

## 5. Network Security

### 5.1 TLS/HTTPS

**Enforce HTTPS everywhere**:

```ruby
# config/environments/production.rb
Rails.application.configure do
  # Force all access to the app over SSL
  config.force_ssl = true
  
  # Set HSTS header
  config.ssl_options = {
    hsts: {
      expires: 1.year,
      subdomains: true,
      preload: true
    }
  }
end

# config/application.rb (security headers middleware)
config.middleware.insert_before 0, Rack::Attack
config.middleware.use Rack::Deflater
config.middleware.use Secure::Headers

# app/middleware/secure_headers.rb (custom middleware)
class SecureHeaders
  def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, response = @app.call(env)
    
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['X-Frame-Options'] = 'DENY'
    headers['X-XSS-Protection'] = '1; mode=block'
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    headers['Content-Security-Policy'] = "default-src 'self'"
    
    [status, headers, response]
  end
end
```

---

### 5.2 CORS Configuration

**Whitelist specific origins**:

```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://app.example.com', 'https://admin.example.com'
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400
  end
end

# ❌ Bad: Allow all origins (vulnerable to CSRF)
# origins '*'
```

---

### 5.3 Rate Limiting

**Protect against brute force and DDoS**:

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
class Rack::Attack
  # Global rate limit: 100 requests per minute per IP
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end
  
  # Endpoint-specific limit: 5 login attempts per 15 minutes
  throttle('logins/ip', limit: 5, period: 15.minutes) do |req|
    if req.path == '/auth/login' && req.post?
      req.ip
    end
  end
  
  # Throttle by email param
  throttle('logins/email', limit: 5, period: 15.minutes) do |req|
    if req.path == '/auth/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end
  
  # Block suspicious IPs
  blocklist('block suspicious ips') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 5.minutes, bantime: 1.hour) do
      req.path == '/auth/login' && req.post?
    end
  end
end

# config/application.rb
config.middleware.use Rack::Attack
```

---

## 6. Audit Logging & Monitoring

### 6.1 Security Audit Log

**Log all security-relevant events**:

```ruby
# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :resource, polymorphic: true, optional: true
  
  enum actor_type: { user: 0, service: 1, system: 2 }
  
  validates :action, presence: true
  validates :ip_address, presence: true
end

# db/migrate/...create_audit_logs.rb
class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.references :actor, polymorphic: true, type: :uuid
      t.integer :actor_type, null: false, default: 0
      t.string :action, null: false
      t.references :resource, polymorphic: true, type: :uuid
      t.string :ip_address, null: false
      t.string :user_agent
      t.boolean :success, null: false, default: true
      t.text :failure_reason
      t.jsonb :metadata
      t.timestamps
      
      t.index :tenant_id
      t.index :action
      t.index :created_at
    end
  end
end

# app/services/audit_logger.rb
class AuditLogger
  def self.log(action:, actor:, resource: nil, success: true, failure_reason: nil, request: nil)
    AuditLog.create!(
      action: action,
      actor: actor,
      resource: resource,
      tenant_id: actor&.tenant_id,
      success: success,
      failure_reason: failure_reason,
      ip_address: request&.remote_ip || 'unknown',
      user_agent: request&.user_agent
    )
  end
end

# Usage in service objects
class UserService
  def delete_user(user_id, current_user, request)
    user = User.find(user_id)
    
    # Perform action
    user.destroy!
    
    # Audit log
    AuditLogger.log(
      action: 'user.deleted',
      actor: current_user,
      resource: user,
      success: true,
      request: request
    )
  rescue => e
    AuditLogger.log(
      action: 'user.deleted',
      actor: current_user,
      resource: user,
      success: false,
      failure_reason: e.message,
      request: request
    )
    raise
  end
end
```

---

### 6.2 Security Monitoring Alerts

**Alert on suspicious activity**:

| Event | Threshold | Alert Level |
|-------|-----------|-------------|
| Failed login attempts | > 5 in 15 minutes (same IP) | WARNING |
| Account creation spike | > 100/hour (same IP) | CRITICAL |
| Admin permission change | Any | INFO |
| Token validation failure | > 10% error rate | WARNING |
| Database connection failure | Any | CRITICAL |

---

## 7. Dependency Security

### 7.1 Dependency Scanning

**Regularly scan for vulnerabilities**:

```bash
# Gemfile
group :development do
  gem 'bundler-audit', require: false
  gem 'brakeman', require: false
end

# Bundle audit (checks for known vulnerabilities)
bundle audit check --update

# Brakeman (static analysis security scanner)
brakeman -A -q

# In CI/CD (GitHub Actions)
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - name: Bundle Audit
        run: |
          gem install bundler-audit
          bundle audit check --update
      - name: Brakeman
        run: |
          gem install brakeman
          brakeman -A -q
```

---

### 7.2 Keep Dependencies Updated

**Update strategy**:
- **Security patches**: Apply immediately (within 48 hours)
- **Minor versions**: Update monthly
- **Major versions**: Evaluate carefully, test thoroughly

```bash
# Update all gems
bundle update

# Update specific gem
bundle update rails

# Check outdated gems
bundle outdated
```

---

## 8. Incident Response

### 8.1 Security Incident Process

1. **Detect**: Monitoring alerts, user reports, security scans
2. **Assess**: Severity (Critical / High / Medium / Low)
3. **Contain**: Isolate affected systems, revoke compromised tokens
4. **Eradicate**: Remove vulnerability, patch systems
5. **Recover**: Restore service, verify security
6. **Post-Mortem**: Document incident, improve processes

---

### 8.2 Breach Notification

**If PII is compromised**:
- [ ] Notify affected users within 72 hours (GDPR requirement)
- [ ] Notify regulatory authorities if required
- [ ] Publish security advisory (transparency builds trust)
- [ ] Implement fixes and preventive measures

---

## 9. Compliance & Certifications

### 9.1 GDPR Compliance

**Data Privacy Requirements**:
- [ ] **Data Minimization**: Only collect necessary data
- [ ] **Right to Access**: Users can download their data (export API)
- [ ] **Right to Erasure**: Users can request deletion (hard delete)
- [ ] **Data Portability**: Export data in machine-readable format (JSON)
- [ ] **Consent Management**: Explicit consent for data processing
- [ ] **Data Breach Notification**: 72-hour notification requirement

---

### 9.2 SOC 2 Compliance

**Trust Services Criteria**:
- **Security**: Firewall, encryption, access controls
- **Availability**: Uptime SLA, disaster recovery, backups
- **Processing Integrity**: Input validation, error handling
- **Confidentiality**: Encryption, access controls, NDAs
- **Privacy**: GDPR compliance, privacy policy

---

## 10. Security Checklist

### 10.1 Code Review Security Checklist

Before merging any code:

- [ ] **Authentication**: All sensitive endpoints require valid JWT
- [ ] **Authorization**: Permission checks implemented (Pundit policies)
- [ ] **Input Validation**: All inputs validated with Strong Parameters and ActiveModel
- [ ] **SQL Injection**: Parameterized queries used (ActiveRecord defaults)
- [ ] **XSS Prevention**: Inputs sanitized, Rails auto-escaping enabled
- [ ] **CSRF Protection**: Rails CSRF protection enabled
- [ ] **Secrets**: No hardcoded secrets, loaded from Rails credentials
- [ ] **Encryption**: Sensitive data encrypted (Rails encrypted attributes)
- [ ] **Rate Limiting**: Rack::Attack configured for auth endpoints
- [ ] **Audit Logging**: Security events logged
- [ ] **Error Messages**: No sensitive data leaked in errors
- [ ] **Dependencies**: No known vulnerabilities (`bundle audit` passes)

---

### 10.2 Deployment Security Checklist

Before production deployment:

- [ ] **TLS**: HTTPS enforced (`config.force_ssl = true`), valid certificate, TLS 1.2+ only
- [ ] **Secrets**: All secrets in Rails credentials or secret manager
- [ ] **Database**: Encryption at rest enabled, strong password, no public access
- [ ] **Redis**: Password protected, no public access
- [ ] **Network**: Firewall configured, only necessary ports open
- [ ] **Monitoring**: Security alerts configured (failed logins, high error rates)
- [ ] **Backups**: Automated encrypted backups, tested restore process
- [ ] **Access Control**: Principle of least privilege, MFA for admin access
- [ ] **Logging**: Centralized logging, retention policy defined
- [ ] **Incident Response**: Runbook created, team trained

---

## 11. Security Resources

### 11.1 Essential Reading

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Related Documentation**:
- [Architecture Golden Path](./architecture.md) - SOLID, DDD, Clean Architecture
- [Development Golden Path](./development.md) - Testing, i18n, Migrations
- [Auditing Golden Path](./auditing.md) - Audit logging standards
- [Quality Golden Path](./quality.md) - Testing and code quality
