# Auditing & Compliance Golden Path

> **"In God we trust, all others must bring data."**  
> — W. Edwards Deming

---

## 1. Audit Logging Principles

### 1.1 What to Audit

**Log ALL state-changing actions**:

| Category | Events to Log |
|----------|---------------|
| **Authentication** | Login (success/failure), logout, password reset, MFA enrollment |
| **Authorization** | Permission granted/revoked, role assigned/removed |
| **User Management** | User created/updated/deleted, account locked/unlocked |
| **Tenant Management** | Tenant created/updated/deleted, configuration changed |
| **Data Access** | Sensitive data viewed/exported (PII, secrets) |
| **System Events** | Configuration changes, key rotation, service start/stop |

---

### 1.2 Audit Log Schema

**The 5 W's (Who, What, When, Where, Why)**:

```ruby
# app/models/audit_log.rb
class AuditLog < ApplicationRecord
  # WHO: Actor information
  belongs_to :actor, polymorphic: true, optional: true
  belongs_to :tenant
  
  # WHAT: Action details
  belongs_to :resource, polymorphic: true, optional: true
  
  # Enum for actor types
  enum actor_type: { user: 0, service: 1, system: 2 }
  
  # Validations
  validates :action, presence: true
  validates :ip_address, presence: true
  
  # Scopes for common queries
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :by_actor, ->(actor_id) { where(actor_id: actor_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { order(created_at: :desc) }
end
```

---

### 1.3 Database Schema

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_audit_logs.rb
class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs, id: :uuid do |t|
      # Multi-tenancy
      t.uuid :tenant_id, null: false
      
      # WHO: Actor information
      t.references :actor, polymorphic: true, type: :uuid
      t.integer :actor_type, null: false, default: 0
      t.string :actor_email
      
      # WHAT: Action details
      t.string :action, null: false
      t.references :resource, polymorphic: true, type: :uuid
      
      # WHEN: Timestamp (created_at)
      
      # WHERE: Context
      t.string :ip_address, null: false
      t.string :user_agent
      t.string :location
      
      # Result
      t.boolean :success, null: false, default: true
      t.string :error_code
      t.text :error_message
      
      # Change tracking (JSONB for PostgreSQL)
      t.jsonb :changes_before
      t.jsonb :changes_after
      t.jsonb :metadata
      
      t.timestamps null: false, index: true
    end
    
    # Indexes for common queries
    add_index :audit_logs, :tenant_id
    add_index :audit_logs, :action
    add_index :audit_logs, [:actor_type, :actor_id]
    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :created_at
    add_index :audit_logs, :success
    
    # Composite index for common query pattern
    add_index :audit_logs, [:tenant_id, :created_at]
    add_index :audit_logs, [:tenant_id, :action, :created_at]
  end
end
```

---

## 2. Implementation Patterns

### 2.1 Service Object Pattern

**Explicit audit logging in service objects**:

```ruby
# app/services/user_service.rb
class UserService
  def initialize(user_repository, audit_logger, current_user, request)
    @user_repository = user_repository
    @audit_logger = audit_logger
    @current_user = current_user
    @request = request
  end
  
  def create_user(params)
    user = nil
    error = nil
    
    begin
      # Perform action
      user = @user_repository.create(params)
      success = true
    rescue => e
      error = e
      success = false
      raise
    ensure
      # Always log audit event
      @audit_logger.log(
        action: 'user.created',
        actor: @current_user,
        resource: user,
        success: success,
        error: error,
        changes_after: user&.attributes,
        request: @request
      )
    end
    
    user
  end
  
  def update_user(user_id, params)
    user = User.find(user_id)
    changes_before = user.attributes.dup
    
    begin
      user.update!(params)
      success = true
    rescue => e
      error = e
      success = false
      raise
    ensure
      @audit_logger.log(
        action: 'user.updated',
        actor: @current_user,
        resource: user,
        success: success,
        error: error,
        changes_before: changes_before,
        changes_after: user.attributes,
        request: @request
      )
    end
    
    user
  end
end
```

---

### 2.2 Audit Logger Service

**Centralized audit logging logic**:

```ruby
# app/services/audit_logger.rb
class AuditLogger
  def self.log(action:, actor:, resource: nil, success: true, error: nil, changes_before: nil, changes_after: nil, request: nil, metadata: {})
    AuditLog.create!(
      # Actor
      tenant_id: actor&.tenant_id,
      actor: actor,
      actor_type: determine_actor_type(actor),
      actor_email: actor&.email,
      
      # Action
      action: action,
      resource: resource,
      
      # Context
      ip_address: request&.remote_ip || 'unknown',
      user_agent: request&.user_agent,
      location: geolocate(request&.remote_ip),
      
      # Result
      success: success,
      error_code: error&.class&.name,
      error_message: sanitize_error(error),
      
      # Changes
      changes_before: changes_before,
      changes_after: changes_after,
      metadata: metadata
    )
  rescue => e
    # Never let audit logging fail the main request
    Rails.logger.error("Failed to create audit log: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    # Send to error tracking (Sentry, Rollbar, etc.)
    Sentry.capture_exception(e) if defined?(Sentry)
  end
  
  private
  
  def self.determine_actor_type(actor)
    case actor
    when User
      :user
    when ServiceAccount
      :service
    else
      :system
    end
  end
  
  def self.sanitize_error(error)
    return nil unless error
    
    # Remove sensitive data from error messages
    message = error.message
    message = message.gsub(/password[=:]?\s*\S+/i, 'password=[REDACTED]')
    message = message.gsub(/token[=:]?\s*\S+/i, 'token=[REDACTED]')
    message.truncate(500)
  end
  
  def self.geolocate(ip_address)
    return nil unless ip_address && ip_address != 'unknown'
    
    # Use geocoder gem or external service
    result = Geocoder.search(ip_address).first
    return nil unless result
    
    {
      city: result.city,
      country: result.country,
      latitude: result.latitude,
      longitude: result.longitude
    }
  rescue => e
    Rails.logger.warn("Geolocation failed for #{ip_address}: #{e.message}")
    nil
  end
end
```

---

### 2.3 ActiveRecord Callbacks Pattern

**Automatic audit logging for models**:

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern
  
  included do
    after_create :audit_create
    after_update :audit_update
    after_destroy :audit_destroy
    
    # Store changes before update
    before_update :store_changes_for_audit
  end
  
  private
  
  def audit_create
    enqueue_audit_log(
      action: "#{model_name.param_key}.created",
      changes_after: auditable_attributes
    )
  end
  
  def audit_update
    return unless @_audit_changes.present?
    
    enqueue_audit_log(
      action: "#{model_name.param_key}.updated",
      changes_before: @_audit_changes_before,
      changes_after: auditable_attributes,
      metadata: { changed_fields: @_audit_changes.keys }
    )
  end
  
  def audit_destroy
    enqueue_audit_log(
      action: "#{model_name.param_key}.deleted",
      changes_before: auditable_attributes
    )
  end
  
  def store_changes_for_audit
    @_audit_changes = changes
    @_audit_changes_before = @_audit_changes.transform_values(&:first)
  end
  
  def enqueue_audit_log(action:, changes_before: nil, changes_after: nil, metadata: {})
    AuditLogJob.perform_later(
      action: action,
      actor: Current.user,
      resource: self,
      changes_before: changes_before,
      changes_after: changes_after,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      metadata: metadata
    )
  end
  
  def auditable_attributes
    # Override in model to specify which attributes to audit
    attributes.except('created_at', 'updated_at')
  end
end

# app/models/user.rb
class User < ApplicationRecord
  include Auditable
  
  # Override to specify sensitive fields to exclude/mask
  def auditable_attributes
    attributes.except('password_digest', 'created_at', 'updated_at')
  end
end

# app/models/current.rb (Thread-safe request attributes)
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :ip_address, :user_agent, :request_id
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :set_current_attributes
  
  private
  
  def set_current_attributes
    Current.user = current_user
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.request_id = request.uuid
  end
end
```

---

### 2.4 Background Job Pattern

**Async audit logging with ActiveJob**:

```ruby
# app/jobs/audit_log_job.rb
class AuditLogJob < ApplicationJob
  queue_as :audit_logs
  
  def perform(action:, actor:, resource: nil, changes_before: nil, changes_after: nil, ip_address:, user_agent:, metadata: {})
    AuditLog.create!(
      action: action,
      actor: actor,
      resource: resource,
      tenant_id: actor&.tenant_id,
      actor_type: determine_actor_type(actor),
      actor_email: actor&.email,
      ip_address: ip_address,
      user_agent: user_agent,
      changes_before: changes_before,
      changes_after: changes_after,
      metadata: metadata,
      success: true
    )
  rescue => e
    Rails.logger.error("Audit log job failed: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    
    # Don't retry - too risky to create duplicate audit logs
    # Instead, log to separate failure table or monitoring system
  end
  
  private
  
  def determine_actor_type(actor)
    case actor
    when User then :user
    when ServiceAccount then :service
    else :system
    end
  end
end

# config/sidekiq.yml (if using Sidekiq)
:queues:
  - audit_logs
  - default
  - mailers
```

---

## 3. Compliance Features

### 3.1 GDPR Right to Access

**Allow users to export their audit history**:

```ruby
# app/services/gdpr/data_export_service.rb
module GDPR
  class DataExportService
    def export_user_data(user)
      {
        user: user_data(user),
        audit_logs: audit_logs(user),
        exported_at: Time.current.iso8601
      }.to_json
    end
    
    private
    
    def user_data(user)
      user.as_json(except: [:password_digest])
    end
    
    def audit_logs(user)
      AuditLog.where(actor: user)
               .or(AuditLog.where(resource: user))
               .order(created_at: :desc)
               .limit(10_000)
               .as_json
    end
  end
end

# app/controllers/api/gdpr_controller.rb
class Api::GdprController < ApplicationController
  def export_data
    service = GDPR::DataExportService.new
    data = service.export_user_data(current_user)
    
    # Log data export
    AuditLogger.log(
      action: 'user.data_exported',
      actor: current_user,
      resource: current_user,
      request: request,
      metadata: { export_size: data.bytesize }
    )
    
    send_data data,
              filename: "user_data_#{current_user.id}_#{Time.current.to_i}.json",
              type: 'application/json',
              disposition: 'attachment'
  end
end
```

---

### 3.2 GDPR Right to Erasure

**Handle user deletion and data pseudonymization**:

```ruby
# app/services/gdpr/erasure_service.rb
module GDPR
  class ErasureService
    def erase_user(user)
      ActiveRecord::Base.transaction do
        # Pseudonymize audit logs (keep for compliance but remove PII)
        pseudonymize_audit_logs(user)
        
        # Delete user data
        user.destroy!
        
        # Log erasure action
        AuditLogger.log(
          action: 'user.erased',
          actor: user,
          resource: user,
          metadata: { gdpr_erasure: true }
        )
      end
    end
    
    private
    
    def pseudonymize_audit_logs(user)
      # Replace PII with anonymous identifiers
      AuditLog.where(actor: user).update_all(
        actor_email: "deleted-user-#{user.id}@deleted.local",
        ip_address: '0.0.0.0',
        user_agent: '[DELETED]'
      )
      
      # Update changes_before and changes_after to remove PII
      AuditLog.where(actor: user).find_each do |log|
        log.changes_before = pseudonymize_json(log.changes_before) if log.changes_before
        log.changes_after = pseudonymize_json(log.changes_after) if log.changes_after
        log.save!
      end
    end
    
    def pseudonymize_json(data)
      return nil unless data
      
      data.transform_values do |value|
        case value
        when String
          value.include?('@') ? '[DELETED]' : value
        else
          value
        end
      end
    end
  end
end
```

---

### 3.3 Retention Policy

**Automatic audit log cleanup**:

```ruby
# app/jobs/audit_log_cleanup_job.rb
class AuditLogCleanupJob < ApplicationJob
  queue_as :maintenance
  
  # Run daily to clean up old audit logs
  def perform
    # Keep audit logs for 1 year (GDPR minimum 6 months, SOC 2 requires 1 year)
    retention_period = 1.year.ago
    
    # Delete in batches to avoid long-running transactions
    loop do
      deleted_count = AuditLog.where('created_at < ?', retention_period)
                               .limit(1000)
                               .delete_all
      
      break if deleted_count.zero?
      
      Rails.logger.info("Deleted #{deleted_count} audit logs older than #{retention_period}")
      sleep 1 # Avoid overwhelming database
    end
  end
end

# config/schedule.rb (if using whenever gem for cron)
every :day, at: '2:00am' do
  runner 'AuditLogCleanupJob.perform_later'
end
```

---

## 4. Querying Audit Logs

### 4.1 Common Audit Queries

```ruby
# app/services/audit_query_service.rb
class AuditQueryService
  # Get all actions by a specific user
  def self.user_actions(user, limit: 100)
    AuditLog.where(actor: user)
            .recent
            .limit(limit)
  end
  
  # Get all actions on a specific resource
  def self.resource_history(resource, limit: 100)
    AuditLog.where(resource: resource)
            .recent
            .limit(limit)
  end
  
  # Failed login attempts for a user
  def self.failed_logins(email, since: 24.hours.ago)
    AuditLog.where(action: 'user.login')
            .where(actor_email: email)
            .where(success: false)
            .where('created_at >= ?', since)
            .count
  end
  
  # Suspicious activity: multiple failed logins from same IP
  def self.suspicious_ips(threshold: 5, since: 1.hour.ago)
    AuditLog.where(action: 'user.login')
            .where(success: false)
            .where('created_at >= ?', since)
            .group(:ip_address)
            .having('COUNT(*) >= ?', threshold)
            .count
  end
  
  # Admin actions in tenant
  def self.admin_actions(tenant_id, since: 7.days.ago)
    AuditLog.where(tenant_id: tenant_id)
            .where(action: ['role.assigned', 'permission.granted', 'user.deleted'])
            .where('created_at >= ?', since)
            .recent
  end
  
  # Data exports (GDPR compliance tracking)
  def self.data_exports(since: 30.days.ago)
    AuditLog.where(action: 'user.data_exported')
            .where('created_at >= ?', since)
            .recent
  end
end
```

---

### 4.2 Audit Log API

```ruby
# app/controllers/api/audit_logs_controller.rb
class Api::AuditLogsController < ApplicationController
  before_action :require_admin
  
  def index
    @audit_logs = AuditLog.by_tenant(current_tenant.id)
                          .page(params[:page])
                          .per(50)
    
    # Filter by action if provided
    @audit_logs = @audit_logs.by_action(params[:action]) if params[:action].present?
    
    # Filter by actor if provided
    @audit_logs = @audit_logs.by_actor(params[:actor_id]) if params[:actor_id].present?
    
    # Filter by date range
    if params[:start_date].present?
      @audit_logs = @audit_logs.where('created_at >= ?', params[:start_date])
    end
    
    if params[:end_date].present?
      @audit_logs = @audit_logs.where('created_at <= ?', params[:end_date])
    end
    
    render json: @audit_logs
  end
  
  def show
    @audit_log = AuditLog.find(params[:id])
    authorize @audit_log  # Using Pundit
    
    render json: @audit_log
  end
end
```

---

## 5. Monitoring & Alerting

### 5.1 Security Alerts

**Monitor audit logs for suspicious patterns**:

```ruby
# app/services/security_monitor.rb
class SecurityMonitor
  # Called periodically or after each audit log creation
  def self.check_for_threats
    check_brute_force_attacks
    check_privilege_escalation
    check_mass_data_access
  end
  
  private
  
  def self.check_brute_force_attacks
    # Alert on > 10 failed logins in 5 minutes
    suspicious_ips = AuditQueryService.suspicious_ips(threshold: 10, since: 5.minutes.ago)
    
    suspicious_ips.each do |ip, count|
      alert(
        severity: :warning,
        title: 'Potential Brute Force Attack',
        message: "#{count} failed login attempts from IP #{ip}",
        metadata: { ip: ip, count: count }
      )
    end
  end
  
  def self.check_privilege_escalation
    # Alert on admin role assignment
    recent_role_changes = AuditLog.where(action: 'role.assigned')
                                   .where('created_at >= ?', 1.hour.ago)
                                   .where("metadata->>'role' = ?", 'admin')
    
    recent_role_changes.each do |log|
      alert(
        severity: :info,
        title: 'Admin Role Assigned',
        message: "User #{log.resource_id} granted admin privileges by #{log.actor_email}",
        metadata: log.attributes
      )
    end
  end
  
  def self.check_mass_data_access
    # Alert on > 100 data exports in 1 hour
    export_count = AuditLog.where(action: 'user.data_exported')
                           .where('created_at >= ?', 1.hour.ago)
                           .count
    
    if export_count > 100
      alert(
        severity: :critical,
        title: 'Unusual Data Export Activity',
        message: "#{export_count} data exports in the past hour",
        metadata: { count: export_count }
      )
    end
  end
  
  def self.alert(severity:, title:, message:, metadata: {})
    # Send to monitoring service (PagerDuty, Slack, etc.)
    Rails.logger.warn("[SECURITY ALERT] #{severity.upcase}: #{title} - #{message}")
    
    # Example: Send to Slack
    SlackNotifier.notify(
      channel: '#security-alerts',
      severity: severity,
      title: title,
      message: message,
      metadata: metadata
    )
  end
end

# Run periodically
# config/schedule.rb
every 5.minutes do
  runner 'SecurityMonitor.check_for_threats'
end
```

---

## 6. Testing Audit Logs

### 6.1 Unit Tests

```ruby
# spec/services/audit_logger_spec.rb
require 'rails_helper'

RSpec.describe AuditLogger do
  describe '.log' do
    let(:user) { create(:user) }
    let(:request) { double('request', remote_ip: '192.168.1.1', user_agent: 'Test Browser') }
    
    it 'creates an audit log record' do
      expect {
        described_class.log(
          action: 'user.created',
          actor: user,
          request: request
        )
      }.to change(AuditLog, :count).by(1)
    end
    
    it 'stores actor information' do
      described_class.log(
        action: 'user.login',
        actor: user,
        request: request
      )
      
      log = AuditLog.last
      expect(log.actor).to eq(user)
      expect(log.actor_email).to eq(user.email)
    end
    
    it 'never fails the calling code' do
      allow(AuditLog).to receive(:create!).and_raise(StandardError)
      
      expect {
        described_class.log(action: 'test', actor: user, request: request)
      }.not_to raise_error
    end
  end
end
```

---

### 6.2 Integration Tests

```ruby
# spec/integration/audit_logging_spec.rb
require 'rails_helper'

RSpec.describe 'Audit Logging', type: :integration do
  let(:admin) { create(:user, :admin) }
  
  it 'logs user creation' do
    expect {
      UserService.new.create_user(
        email: 'newuser@example.com',
        username: 'newuser'
      )
    }.to change(AuditLog, :count).by(1)
    
    log = AuditLog.last
    expect(log.action).to eq('user.created')
    expect(log.success).to be true
  end
  
  it 'logs failed user creation' do
    expect {
      UserService.new.create_user(email: 'invalid')
    }.to raise_error(ValidationError)
    
    log = AuditLog.last
    expect(log.action).to eq('user.created')
    expect(log.success).to be false
    expect(log.error_code).to eq('ValidationError')
  end
end
```

---

## 7. Compliance Checklist

### 7.1 GDPR Compliance

- [ ] **Right to Access**: Users can export their data (audit logs included)
- [ ] **Right to Erasure**: User deletion pseudonymizes audit logs
- [ ] **Data Minimization**: Only log necessary information
- [ ] **Data Retention**: Audit logs retained for 1 year, then deleted
- [ ] **Consent**: Audit logging disclosed in privacy policy
- [ ] **Breach Notification**: Monitoring alerts for suspicious activity

---

### 7.2 SOC 2 Compliance

- [ ] **Audit Trail**: All security-relevant events logged
- [ ] **Immutability**: Audit logs cannot be modified (use append-only storage)
- [ ] **Retention**: Minimum 1 year retention
- [ ] **Monitoring**: Real-time alerts for security events
- [ ] **Access Control**: Audit log access restricted to admins
- [ ] **Regular Review**: Weekly audit log reviews documented

---

### 7.3 ISO 27001 Compliance

- [ ] **Event Logging**: All access to sensitive data logged
- [ ] **Clock Synchronization**: All timestamps use UTC
- [ ] **Log Protection**: Audit logs encrypted at rest
- [ ] **Log Review**: Automated monitoring with manual review
- [ ] **Backup**: Audit logs backed up separately
- [ ] **Incident Response**: Audit logs used for forensics

---

**Related Documentation**:
- [Security Golden Path](./security.md) - Security monitoring
- [Architecture Golden Path](./architecture.md) - Event-driven architecture
- [Development Golden Path](./development.md) - Background jobs
