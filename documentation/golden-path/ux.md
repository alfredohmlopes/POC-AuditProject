# UX/UI Golden Path

> **"Design is not just what it looks like and feels like. Design is how it works."**  
> — Steve Jobs

---

## 1. UX Principles

### 1.1 Core Principles

1. **User-Centric**: Design for developers (our users), not for ourselves
2. **Simplicity**: Make the simple things simple, and the complex things possible
3. **Consistency**: Consistent UI patterns, naming, and behaviors across all interfaces
4. **Accessibility**: WCAG 2.1 AA compliance minimum
5. **Performance**: Perceived performance matters as much as actual performance
6. **Feedback**: Always provide clear feedback for user actions

---

### 1.2 Developer Experience (DX) First

**Our users are developers**, so DX is UX:

| DX Aspect | Best Practice |
|-----------|---------------|
| **Documentation** | Clear, searchable, with runnable examples |
| **Error Messages** | Specific, actionable, with links to docs |
| **API Design** | Consistent naming, predictable behavior |
| **Onboarding** | First API call in < 15 minutes |
| **SDKs** | Typed, well-documented, with IntelliSense |

---

## 2. Admin Dashboard UX

### 2.1 Design System

**Use a consistent design system** (Tailwind CSS + shadcn/ui):

#### **Color Palette**:
```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',  // Primary blue
          600: '#2563eb',
          700: '#1d4ed8',
        },
        success: '#10b981',  // Green
        warning: '#f59e0b',  // Amber
        error: '#ef4444',    // Red
        neutral: {
          50: '#f9fafb',
          100: '#f3f4f6',
          500: '#6b7280',
          900: '#111827',
        },
      },
    },
  },
};
```

#### **Typography**:
- **Font**: Inter (or SF Pro, Roboto)
- **Headings**: Bold, clear hierarchy (H1: 32px, H2: 24px, H3: 18px)
- **Body**: 16px, line-height 1.5
- **Code**: JetBrains Mono, 14px

---

### 2.2 Component Library

**Build reusable components**:

```tsx
// components/ui/Button.tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  children: React.ReactNode;
}

export function Button({ 
  variant = 'primary', 
  size = 'md',
  loading = false,
  disabled = false,
  onClick,
  children 
}: ButtonProps) {
  const baseClasses = 'rounded-lg font-medium transition-colors';
  
  const variantClasses = {
    primary: 'bg-primary-600 text-white hover:bg-primary-700',
    secondary: 'bg-neutral-200 text-neutral-900 hover:bg-neutral-300',
    danger: 'bg-error text-white hover:bg-red-600',
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };
  
  return (
    <button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`}
      onClick={onClick}
      disabled={disabled || loading}
    >
      {loading ? <Spinner /> : children}
    </button>
  );
}
```

---

### 2.3 Layout Patterns

#### **Dashboard Layout**:
```
┌────────────────────────────────────────────┐
│  Header (Logo, Search, User Menu)         │
├──────┬─────────────────────────────────────┤
│      │                                     │
│ Side │  Main Content Area                  │
│ Nav  │                                     │
│      │  ┌────────────────────────────────┐ │
│      │  │  Breadcrumbs                   │ │
│      │  └────────────────────────────────┘ │
│      │  ┌────────────────────────────────┐ │
│      │  │  Page Title + Actions          │ │
│      │  └────────────────────────────────┘ │
│      │  ┌────────────────────────────────┐ │
│      │  │                                │ │
│      │  │  Content (Table, Form, etc.)   │ │
│      │  │                                │ │
│      │  └────────────────────────────────┘ │
└──────┴─────────────────────────────────────┘
```

---

### 2.4 Data Tables

**Best practices for user lists and data grids**:

```tsx
// components/UserTable.tsx
export function UserTable({ users }: { users: User[] }) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Email</TableHead>
          <TableHead>Name</TableHead>
          <TableHead>Status</TableHead>
          <TableHead>Created</TableHead>
          <TableHead className="text-right">Actions</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {users.map((user) => (
          <TableRow key={user.id}>
            <TableCell className="font-medium">{user.email}</TableCell>
            <TableCell>{user.name}</TableCell>
            <TableCell>
              <Badge variant={user.blocked ? 'destructive' : 'success'}>
                {user.blocked ? 'Blocked' : 'Active'}
              </Badge>
            </TableCell>
            <TableCell>{formatDate(user.createdAt)}</TableCell>
            <TableCell className="text-right">
              <DropdownMenu>
                <DropdownMenuTrigger>•••</DropdownMenuTrigger>
                <DropdownMenuContent>
                  <DropdownMenuItem>View</DropdownMenuItem>
                  <DropdownMenuItem>Edit</DropdownMenuItem>
                  <DropdownMenuItem className="text-red-600">
                    Delete
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

**Features**:
- ✅ Sortable columns
- ✅ Searchable/filterable
- ✅ Pagination (show 25/50/100 per page)
- ✅ Bulk actions (select multiple users)
- ✅ Loading states

---

### 2.5 Forms

**Form best practices**:

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const userSchema = z.object({
  email: z.string().email('Invalid email address'),
  name: z.string().min(1, 'Name is required'),
  username: z.string().min(3, 'Username must be at least 3 characters'),
});

type UserFormData = z.infer<typeof userSchema>;

export function CreateUserForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<UserFormData>({
    resolver: zodResolver(userSchema),
  });
  
  const onSubmit = async (data: UserFormData) => {
    try {
      await api.users.create(data);
      toast.success('User created successfully');
      // Redirect or refresh
    } catch (error) {
      toast.error('Failed to create user');
    }
  };
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          {...register('email')}
          aria-invalid={!!errors.email}
        />
        {errors.email && (
          <p className="text-sm text-error mt-1">{errors.email.message}</p>
        )}
      </div>
      
      <div>
        <Label htmlFor="name">Name</Label>
        <Input id="name" {...register('name')} />
        {errors.name && (
          <p className="text-sm text-error mt-1">{errors.name.message}</p>
        )}
      </div>
      
      <Button type="submit" loading={isSubmitting}>
        Create User
      </Button>
    </form>
  );
}
```

**Form principles**:
- ✅ Inline validation (show errors on blur, not on initial render)
- ✅ Clear error messages
- ✅ Disabled submit button while loading
- ✅ Success/error toast notifications
- ✅ Keyboard navigation support (Tab, Enter)

---

## 3. Accessibility (WCAG 2.1 AA)

### 3.1 Keyboard Navigation

**All interactive elements must be keyboard-accessible**:

```tsx
// ✅ Good: Keyboard-accessible
<button onClick={handleClick} className="...">
  Delete
</button>

// ❌ Bad: Not keyboard-accessible
<div onClick={handleClick}>Delete</div>

// ✅ Good: If you must use div, add keyboard support
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyPress={(e) => e.key === 'Enter' && handleClick()}
>
  Delete
</div>
```

---

### 3.2 Color Contrast

**Minimum contrast ratios** (WCAG AA):
- Normal text: 4.5:1
- Large text (18px+): 3:1

**Tools**:
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Chrome DevTools Lighthouse

---

### 3.3 ARIA Labels

**Use semantic HTML first, ARIA second**:

```tsx
// ✅ Good: Semantic HTML
<button onClick={handleDelete}>Delete User</button>

// ✅ Good: ARIA label for icon-only button
<button onClick={handleDelete} aria-label="Delete user">
  <TrashIcon />
</button>

// ✅ Good: ARIA live region for dynamic content
<div aria-live="polite" aria-atomic="true">
  {isLoading ? 'Loading users...' : `${users.length} users found`}
</div>
```

---

### 3.4 Focus Management

**Visible focus indicators**:

```css
/* Ensure focus is visible */
button:focus-visible {
  outline: 2px solid theme('colors.primary.500');
  outline-offset: 2px;
}

/* Don't remove focus entirely */
/* ❌ Bad: button:focus { outline: none; } */
```

---

## 4. Performance

### 4.1 Perceived Performance

**Loading States**:

```tsx
// Skeleton loading (better than spinner)
export function UserListSkeleton() {
  return (
    <div className="space-y-2">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="animate-pulse flex items-center space-x-4">
          <div className="h-10 w-10 bg-neutral-200 rounded-full" />
          <div className="flex-1 space-y-2">
            <div className="h-4 bg-neutral-200 rounded w-3/4" />
            <div className="h-3 bg-neutral-200 rounded w-1/2" />
          </div>
        </div>
      ))}
    </div>
  );
}

// Usage
{isLoading ? <UserListSkeleton /> : <UserTable users={users} />}
```

---

### 4.2 Optimistic UI Updates

**Update UI immediately, sync with server in background**:

```tsx
const handleToggleBlock = async (userId: string) => {
  // Optimistically update UI
  setUsers(users.map(u => 
    u.id === userId ? { ...u, blocked: !u.blocked } : u
  ));
  
  try {
    // Sync with server
    await api.users.toggleBlock(userId);
    toast.success('User updated');
  } catch (error) {
    // Revert on failure
    setUsers(users.map(u => 
      u.id === userId ? { ...u, blocked: !u.blocked } : u
    ));
    toast.error('Failed to update user');
  }
};
```

---

### 4.3 Code Splitting

**Lazy load routes**:

```tsx
import { lazy, Suspense } from 'react';

const UserList = lazy(() => import('./pages/UserList'));
const UserDetail = lazy(() => import('./pages/UserDetail'));

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route
          path="/users"
          element={
            <Suspense fallback={<LoadingSpinner />}>
              <UserList />
            </Suspense>
          }
        />
        <Route
          path="/users/:id"
          element={
            <Suspense fallback={<LoadingSpinner />}>
              <UserDetail />
            </Suspense>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}
```

---

## 5. Error Handling

### 5.1 Error Messages

**User-friendly, actionable error messages**:

```tsx
// ❌ Bad
"Error: 500 Internal Server Error"

// ✅ Good
"We couldn't create the user. Please check the email address and try again."

// ✅ Even better (with action)
<Alert variant="destructive">
  <AlertCircle className="h-4 w-4" />
  <AlertTitle>User creation failed</AlertTitle>
  <AlertDescription>
    The email address is already in use. Please use a different email or{' '}
    <a href="/users/search?email={email}" className="underline">
      view the existing user
    </a>.
  </AlertDescription>
</Alert>
```

---

### 5.2 Empty States

**Design for empty states**:

```tsx
export function EmptyUserList() {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <UsersIcon className="h-16 w-16 text-neutral-400 mb-4" />
      <h3 className="text-lg font-semibold mb-2">No users yet</h3>
      <p className="text-neutral-500 mb-4">
        Get started by creating your first user.
      </p>
      <Button onClick={() => navigate('/users/new')}>
        <PlusIcon className="mr-2" /> Create User
      </Button>
    </div>
  );
}
```

---

## 6. Responsive Design

### 6.1 Mobile-First

**Use responsive breakpoints**:

```tsx
<div className="
  grid 
  grid-cols-1 
  sm:grid-cols-2 
  lg:grid-cols-3 
  xl:grid-cols-4 
  gap-4
">
  {/* Cards */}
</div>
```

**Breakpoints** (Tailwind default):
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px

---

### 6.2 Mobile Navigation

**Hamburger menu for mobile**:

```tsx
export function Navigation() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  return (
    <>
      {/* Desktop nav: hidden on mobile */}
      <nav className="hidden md:flex space-x-4">
        <NavLink to="/users">Users</NavLink>
        <NavLink to="/tenants">Tenants</NavLink>
      </nav>
      
      {/* Mobile hamburger: hidden on desktop */}
      <button
        className="md:hidden"
        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        aria-label="Toggle menu"
      >
        <MenuIcon />
      </button>
      
      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed inset-0 bg-white z-50">
          {/* Mobile nav links */}
        </div>
      )}
    </>
  );
}
```

---

## 7. Micro-Interactions

### 7.1 Hover Effects

```css
/* Button hover */
.button {
  @apply transition-colors duration-200;
}

.button:hover {
  @apply bg-primary-700;
}

/* Card hover */
.card {
  @apply transition-transform duration-200;
}

.card:hover {
  @apply transform scale-105 shadow-lg;
}
```

---

### 7.2 Animations

**Use sparingly, keep subtle**:

```tsx
import { motion } from 'framer-motion';

export function Toast({ message }: { message: string }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 50 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 50 }}
      className="bg-white shadow-lg rounded-lg p-4"
    >
      {message}
    </motion.div>
  );
}
```

---

## 8. Documentation UX

### 8.1 Structure

```
docs/
├── getting-started/
│   ├── quick-start.md      # First API call in 15 minutes
│   ├── installation.md
│   └── configuration.md
├── guides/
│   ├── oauth2-flows.md
│   ├── user-management.md
│   └── multi-tenancy.md
├── api-reference/
│   └── openapi.yaml         # Auto-generated
└── examples/
    ├── react-spa.md
    └── nodejs-backend.md
```

---

### 8.2 Code Examples

**Always include runnable examples**:

````markdown
## Creating a User

```bash
curl -X POST https://api.ciam.example.com/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "name": "Jane Doe"
  }'
```

**Response**:
```json
{
  "id": "user_abc123",
  "email": "user@example.com",
  "name": "Jane Doe",
  "created_at": "2025-11-28T14:00:00Z"
}
```
````

---

## 9. UX Checklist

### 9.1 Before Launch

- [ ] **Accessibility**: WCAG 2.1 AA compliance checked (Lighthouse audit)
- [ ] **Keyboard Navigation**: All actions keyboard-accessible
- [ ] **Loading States**: Loading indicators for all async actions
- [ ] **Error Handling**: User-friendly error messages
- [ ] **Empty States**: Designed for zero-data scenarios
- [ ] **Responsive**: Works on mobile, tablet, desktop
- [ ] **Performance**: Lighthouse score ≥ 90
- [ ] **Consistency**: Uses design system components
- [ ] **Forms**: Inline validation, clear error messages
- [ ] **Feedback**: Toast notifications for success/error

---

**Remember**: "Simplicity is the ultimate sophistication." — Leonardo da Vinci
