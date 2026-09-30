---
applyTo: '**/*.java'
---

# Code Review Standards for Java Programming

## Overview

This document contains comprehensive mandatory code review rules for **Java programming**. All code must comply with these standards before merge and follow the principles outlined in "Clean Code: A Handbook of Agile Software Craftsmanship" by Robert C. Martin.

**Severity Indicators**:
- **BLOCKER**: Must be fixed immediately - blocks release
- **CRITICAL**: Must be fixed before merge - causes bugs, security issues, or compilation failures
- **MAJOR**: Should be fixed - impacts performance, maintainability, or quality
- **MINOR**: Recommended to fix - improves code quality and consistency
- **INFO**: Information or low-priority improvements

**Related Documentation**: See [general-java-instructions.md](general-java-instructions.md) for quick-reference coding guidelines, best practices, and project structure requirements.

---

## Standards Overview

This document enforces:
1. Naming Conventions (MANDATORY)
2. Code Formatting (MANDATORY)
3. Class Design (CRITICAL)
4. Method Design (MAJOR)
5. Exception Handling (CRITICAL)
6. Concurrency (CRITICAL)
7. Performance (MAJOR)
8. Security (CRITICAL)
9. Testing (MANDATORY)
10. Clean Code Principles (MANDATORY)

---

## 1. Naming Conventions (MANDATORY)

### Package Names
- **All lowercase**: `com.company.project.module`
- **Reverse domain naming**: Start with company domain
- **Descriptive hierarchy**: Organize by feature/layer

**Noncompliant:**
```java
package Com.Company.Project;
package project;  // Missing company namespace
```

**Compliant:**
```java
package com.company.project.service;
package com.company.project.repository;
```

### Class Names
- **PascalCase**: `CustomerService`, `OrderRepository`
- **Nouns or noun phrases**: Represent entities
- **Descriptive**: Clear purpose from name
- **Avoid generic names**: Not `Manager`, `Helper`, `Util` alone

**Noncompliant:**
```java
public class customerservice { }  // Wrong case
public class Data { }  // Too generic
public class DoStuff { }  // Verb, not noun
```

**Compliant:**
```java
public class CustomerService { }
public class OrderProcessor { }
public class PaymentValidator { }
```

### Interface Names
- **PascalCase**: `Serializable`, `Comparable`
- **Adjectives or nouns**: Describe capability or contract
- **Avoid 'I' prefix**: Use descriptive names instead

**Noncompliant:**
```java
public interface ICustomerService { }  // Avoid 'I' prefix
```

**Compliant:**
```java
public interface CustomerService { }
public interface Readable { }
public interface PaymentProcessor { }
```

### Method Names
- **camelCase**: `calculateTotal`, `findById`
- **Verbs or verb phrases**: Describe action
- **Boolean methods**: Start with `is`, `has`, `can`, `should`
- **Getters/Setters**: Follow JavaBeans convention

**Noncompliant:**
```java
public int Total() { }  // Wrong case
public boolean active() { }  // Should be isActive()
public void customer() { }  // Not a verb
```

**Compliant:**
```java
public int calculateTotal() { }
public boolean isActive() { }
public Customer findCustomer() { }
public boolean hasPermission() { }
```

### Variable Names
- **camelCase**: `firstName`, `totalAmount`
- **Descriptive**: Avoid abbreviations except common ones
- **No single letters**: Except loop counters (`i`, `j`, `k`)
- **Constants**: `UPPER_SNAKE_CASE`

**Noncompliant:**
```java
int d;  // Days? Distance? Unclear
String fn;  // firstName abbreviated
final int max = 100;  // Should be uppercase for const
```

**Compliant:**
```java
int daysSinceCreation;
String firstName;
final int MAX_RETRY_COUNT = 100;
```

---

## 2. Code Formatting (MANDATORY)

### Indentation and Spacing
- **4 spaces per level** (never tabs)
- **Opening brace on same line** (Java convention)
- **Closing brace on new line**, aligned with statement
- **Blank line between methods**
- **Space after keywords**: `if (`, `for (`, `while (`
- **No space after method names**: `method(`

**Compliant:**
```java
public void processOrder(Order order) {
    if (order.isValid()) {
        calculateTotal(order);
    }
}

public void calculateTotal(Order order) {
    // Implementation
}
```

### Line Length
- **Maximum 120 characters** per line
- **Break long lines** at logical points
- **Indent continuation lines** by 8 spaces or two levels

### Whitespace
- One blank line between method definitions
- One blank line between logical sections within methods
- No multiple consecutive blank lines
- No trailing whitespace

---

## 3. Class Design (CRITICAL)

### Single Responsibility Principle (SOLID)
- **One reason to change**: Each class has single responsibility
- **Cohesive**: All methods relate to class purpose

**Noncompliant:**
```java
public class Customer {
    public void save() { }  // Database responsibility
    public void sendEmail() { }  // Email responsibility
    public void generateInvoice() { }  // Billing responsibility
}
```

**Compliant:**
```java
public class Customer {
    private String name;
    private String email;
    // Only customer data and behavior
}

public class CustomerRepository {
    public void save(Customer customer) { }
}

public class EmailService {
    public void sendEmail(Customer customer, String message) { }
}
```

### Encapsulation (CRITICAL)
- **Private fields**: Always use private for instance variables
- **Public methods**: Expose only necessary interface
- **Defensive copies**: Return copies of mutable objects

**Noncompliant:**
```java
public class Account {
    public double balance;  // Should be private
    public List<Transaction> transactions;  // Mutable, exposed
}
```

**Compliant:**
```java
public class Account {
    private double balance;
    private List<Transaction> transactions;
    
    public double getBalance() {
        return balance;
    }
    
    public List<Transaction> getTransactions() {
        return Collections.unmodifiableList(transactions);
    }
}
```

### Immutability (MAJOR)
- **Prefer immutable objects**: Use `final` fields
- **No setters**: Initialize in constructor
- **Thread-safe by default**: Immutable objects are inherently thread-safe

**Compliant:**
```java
public final class Money {
    private final BigDecimal amount;
    private final Currency currency;
    
    public Money(BigDecimal amount, Currency currency) {
        this.amount = amount;
        this.currency = currency;
    }
    
    // Only getters, no setters
}
```

### Composition Over Inheritance (MAJOR)
- **Favor composition**: More flexible than inheritance
- **Use inheritance only for "is-a"**: True subtype relationships
- **Avoid deep hierarchies**: Maximum 3-4 levels

---

## 4. Method Design (MAJOR)

### Method Size (CRITICAL)
- **Maximum 20-30 lines**: Keep methods small and focused
- **One level of abstraction**: Don't mix high and low-level operations
- **Extract methods**: Break large methods into smaller ones

**Noncompliant:**
```java
public void processOrder(Order order) {
    // 100 lines of mixed validation, calculation, persistence, notification
}
```

**Compliant:**
```java
public void processOrder(Order order) {
    validateOrder(order);
    calculateTotal(order);
    saveOrder(order);
    notifyCustomer(order);
}
```

### Parameter Count (MAJOR)
- **Maximum 3-4 parameters**: Too many indicates design issue
- **Use parameter objects**: Group related parameters

**Noncompliant:**
```java
public void createUser(String firstName, String lastName, 
                      String email, String phone, String address, 
                      String city, String state, String zip) { }
```

**Compliant:**
```java
public void createUser(UserInfo userInfo, Address address) { }
```

### Return Values (MAJOR)
- **Prefer returning values**: Over modifying parameters
- **Use Optional<T>**: For potentially null returns (Java 8+)
- **Avoid returning null**: Use Optional, empty collections, or null object pattern

**Noncompliant:**
```java
public Customer findById(Long id) {
    return null;  // Forces null checks everywhere
}
```

**Compliant:**
```java
public Optional<Customer> findById(Long id) {
    // Returns Optional.empty() if not found
}

public List<Order> findOrders() {
    return Collections.emptyList();  // Never return null
}
```

---

## 5. Exception Handling (CRITICAL)

### Use Specific Exceptions
- **Catch specific exceptions**: Don't catch Exception or Throwable
- **Create custom exceptions**: For domain-specific errors
- **Preserve stack traces**: Use `throw new Exception(e)`

**Noncompliant:**
```java
try {
    // code
} catch (Exception e) {  // Too broad
    throw new RuntimeException("Error");  // Lost original exception
}
```

**Compliant:**
```java
try {
    // code
} catch (IOException e) {
    throw new DataAccessException("Failed to read file", e);
}
```

### Don't Ignore Exceptions (BLOCKER)
- **Never catch and ignore**: Always log or rethrow
- **Document why empty**: If truly nothing to do (rare)

**Noncompliant:**
```java
try {
    riskyOperation();
} catch (Exception e) {
    // Silent failure - NEVER do this
}
```

**Compliant:**
```java
try {
    riskyOperation();
} catch (SpecificException e) {
    logger.error("Operation failed", e);
    throw new ServiceException("Failed to process", e);
}
```

### Use Try-With-Resources (CRITICAL)
- **Always use for AutoCloseable**: Ensures proper resource cleanup
- **Prefer over finally blocks**: For resource management

**Noncompliant:**
```java
BufferedReader reader = null;
try {
    reader = new BufferedReader(new FileReader(file));
    // Use reader
} finally {
    if (reader != null) {
        reader.close();  // Can throw exception
    }
}
```

**Compliant:**
```java
try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
    // Use reader - automatically closed
}
```

### Custom Exceptions (MAJOR)
- **Extend appropriate base**: RuntimeException or Exception
- **Include cause**: Constructor with Throwable parameter
- **Provide context**: Meaningful error messages

**Compliant:**
```java
public class OrderProcessingException extends RuntimeException {
    public OrderProcessingException(String message) {
        super(message);
    }
    
    public OrderProcessingException(String message, Throwable cause) {
        super(message, cause);
    }
}
```

---

## 6. Concurrency (CRITICAL)

### Thread Safety (CRITICAL)
- **Document thread safety**: Class-level Javadoc
- **Synchronize mutable shared state**: Use synchronized or concurrent collections
- **Prefer immutability**: Thread-safe by default
- **Use java.util.concurrent**: Over synchronized blocks

**Noncompliant:**
```java
public class Counter {
    private int count = 0;  // Not thread-safe
    
    public void increment() {
        count++;  // Race condition
    }
}
```

**Compliant:**
```java
public class Counter {
    private final AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        count.incrementAndGet();  // Thread-safe
    }
}
```

### Avoid Synchronized(this) (MAJOR)
- **Use private locks**: Better control over synchronization
- **Avoid exposing locks**: Prevents external interference

**Noncompliant:**
```java
public synchronized void method() {  // Exposes lock
    // code
}
```

**Compliant:**
```java
private final Object lock = new Object();

public void method() {
    synchronized (lock) {  // Private lock
        // code
    }
}
```

### Use Concurrent Collections (MAJOR)
- **ConcurrentHashMap**: Over synchronized Map
- **CopyOnWriteArrayList**: For read-heavy scenarios
- **BlockingQueue**: For producer-consumer patterns

---

## 7. Performance (MAJOR)

### String Concatenation (MAJOR)
- **Use StringBuilder**: For loops or multiple concatenations
- **String.format() for readability**: When appropriate

**Noncompliant:**
```java
String result = "";
for (int i = 0; i < 1000; i++) {
    result += i;  // Creates 1000 String objects
}
```

**Compliant:**
```java
StringBuilder result = new StringBuilder();
for (int i = 0; i < 1000; i++) {
    result.append(i);
}
```

### Collection Size (MINOR)
- **Specify initial capacity**: When size known
- **Use isEmpty()**: Instead of `size() == 0`

**Compliant:**
```java
List<String> items = new ArrayList<>(expectedSize);

if (items.isEmpty()) {  // More efficient than size() == 0
    // handle empty
}
```

### Avoid Premature Optimization (INFO)
- **Profile before optimizing**: Don't guess at bottlenecks
- **Readable first**: Then optimize if needed
- **Measure impact**: Verify optimization helps

---

## 8. Security (CRITICAL)

### Input Validation (CRITICAL)
- **Validate all input**: Never trust user input
- **Whitelist over blacklist**: Define what's allowed
- **Sanitize output**: Prevent injection attacks

**Noncompliant:**
```java
public User getUser(String userId) {
    return executeQuery("SELECT * FROM users WHERE id = " + userId);
    // SQL injection vulnerability
}
```

**Compliant:**
```java
public User getUser(String userId) {
    return jdbcTemplate.queryForObject(
        "SELECT * FROM users WHERE id = ?",
        new Object[]{userId},
        userRowMapper
    );
}
```

### Sensitive Data (CRITICAL)
- **Don't log passwords**: Or sensitive information
- **Use char[] for passwords**: Not String (can be cleared)
- **Encrypt sensitive data**: At rest and in transit

**Noncompliant:**
```java
logger.info("User logged in with password: " + password);
String password = getPassword();  // String is immutable
```

**Compliant:**
```java
logger.info("User logged in");
char[] password = getPassword();  // Can be cleared
Arrays.fill(password, '\0');  // Clear after use
```

### Use Security Libraries (CRITICAL)
- **Don't roll your own crypto**: Use standard libraries
- **BCrypt for passwords**: Not MD5 or SHA-1
- **Use HTTPS**: For all sensitive communications

---

## 9. Testing (MANDATORY)

### Unit Test Requirements
- **Test all public methods**: Comprehensive coverage
- **Test edge cases**: Boundaries, nulls, empty collections
- **Test failure scenarios**: Exception paths
- **Isolated tests**: No dependencies on other tests
- **Fast tests**: Unit tests should run in milliseconds

### Test Naming (MANDATORY)
- **Descriptive names**: Describe what's being tested
- **Pattern**: `methodName_condition_expectedResult`

**Compliant:**
```java
@Test
public void calculateTotal_withValidItems_returnsCorrectSum() {
    // Arrange
    Order order = new Order();
    order.addItem(new Item(10.0));
    order.addItem(new Item(20.0));
    
    // Act
    double total = orderService.calculateTotal(order);
    
    // Assert
    assertEquals(30.0, total, 0.01);
}

@Test
public void calculateTotal_withEmptyOrder_returnsZero() {
    Order order = new Order();
    assertEquals(0.0, orderService.calculateTotal(order), 0.01);
}

@Test(expected = IllegalArgumentException.class)
public void calculateTotal_withNullOrder_throwsException() {
    orderService.calculateTotal(null);
}
```

### Test Organization (MANDATORY)
- **Arrange-Act-Assert pattern**: Clear three-phase structure
- **One assertion per test**: Or closely related assertions
- **Use @Before/@After**: For setup and teardown

**Compliant:**
```java
public class OrderServiceTest {
    private OrderService orderService;
    private Order testOrder;
    
    @Before
    public void setUp() {
        orderService = new OrderService();
        testOrder = new Order();
    }
    
    @After
    public void tearDown() {
        // Cleanup if needed
    }
    
    @Test
    public void testMethod() {
        // Arrange
        // Act
        // Assert
    }
}
```

### Mock External Dependencies (MAJOR)
- **Use mocking frameworks**: Mockito, EasyMock
- **Don't test external systems**: Mock databases, APIs
- **Verify interactions**: When appropriate

**Compliant:**
```java
@Test
public void processOrder_callsPaymentService() {
    // Arrange
    PaymentService mockPaymentService = mock(PaymentService.class);
    OrderService orderService = new OrderService(mockPaymentService);
    Order order = new Order();
    
    // Act
    orderService.processOrder(order);
    
    // Assert
    verify(mockPaymentService).processPayment(order);
}
```

---

## 10. Clean Code Principles (MANDATORY)

### Meaningful Names (CRITICAL)
- **Reveal intention**: Name should explain why it exists
- **Avoid noise words**: Info, Data, Manager without context
- **Pronounceable names**: Easy to discuss
- **Searchable names**: No magic numbers, single letters

### Functions Do One Thing (CRITICAL)
- **Single responsibility**: One level of abstraction
- **Small**: Maximum 20-30 lines
- **Top to bottom**: Read like a narrative

### Comments (MAJOR)
- **Explain why, not what**: Code explains what
- **Keep updated**: Or remove
- **Avoid commented code**: Use source control

**Noncompliant:**
```java
// Check if employee is eligible
if (e.age > 65 && e.yearsOfService > 20) {  // What does this mean?
```

**Compliant:**
```java
if (employee.isEligibleForRetirement()) {  // Self-documenting
```

### Don't Repeat Yourself (DRY) (MAJOR)
- **Extract common code**: Into reusable methods
- **Avoid copy-paste**: Refactor instead

### Error Handling is One Thing (MAJOR)
- **Separate error handling**: From business logic
- **Try-catch blocks**: Are ugly, extract body

---

## Sonarqube Compliance (MANDATORY)

### Cognitive Complexity
- **Maximum 15**: Per method
- **Break complex methods**: Into smaller methods
- **Reduce nesting**: Use early returns

### Code Duplication
- **No duplicate code blocks**: Minimum 3 lines
- **Extract to methods**: Reuse common logic

### Code Smells
- **Fix all blockers/critical**: Before merge
- **Address major issues**: Timely resolution
- **Review info/minor**: Consider fixing

---

## Summary

All Java code must comply with these standards before merge:

✅ **Naming**: PascalCase classes, camelCase methods/variables, descriptive names
✅ **Formatting**: 4 spaces, consistent style, 120 char lines
✅ **Classes**: Single responsibility, encapsulation, immutability
✅ **Methods**: Small (20-30 lines), max 3-4 params, meaningful returns
✅ **Exceptions**: Specific catches, never ignore, try-with-resources
✅ **Concurrency**: Thread-safe, use concurrent collections, document safety
✅ **Performance**: StringBuilder for concatenation, appropriate collections
✅ **Security**: Validate input, protect sensitive data, use security libraries
✅ **Testing**: Comprehensive unit tests, descriptive names, mock dependencies
✅ **Clean Code**: Meaningful names, small functions, DRY, explain why not what
✅ **Sonarqube**: Fix blockers/critical, low cognitive complexity, no duplication

Use code quality tools to validate code quality and security before submitting for review. Follow "Clean Code" principles and refer to [general-java-instructions.md](general-java-instructions.md) for additional quick-reference guidelines.