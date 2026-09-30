---
applyTo: '**/*.java'
---

Provide project context and coding guidelines that AI should follow when generating Java code, answering questions, or reviewing changes. This document is specifically for **Java programming** and follows "Clean Code" principles.

## Related Documentation

**IMPORTANT**: All code must also comply with [code-review-JAVA-standards.md](code-review-JAVA-standards.md), which contains comprehensive mandatory code review rules organized by severity. Review those standards before submitting code.

---

## Java-Specific Guidelines

### Language Fundamentals
- **Java Version**: Use Java 8+ features (lambdas, streams, Optional)
- **Modern Java**: Prefer functional programming patterns when appropriate
- **Platform**: Code should be platform-independent (Write Once, Run Anywhere)
- **Standard Library**: Prefer java.util.concurrent over manual synchronization

### Naming Conventions (MANDATORY)

#### Packages
- **All lowercase**: `com.company.project.module`
- **Reverse domain**: Start with company domain name
- **Hierarchical**: Group by feature or architectural layer

#### Classes and Interfaces
- **PascalCase**: `CustomerService`, `OrderProcessor`
- **Nouns**: Classes represent things
- **Adjectives/Nouns**: Interfaces describe capabilities
- **Avoid prefixes**: No 'C' for classes.
- **Add prefix for interfaces**: interfaces always begin with 'I'

#### Methods
- **camelCase**: `calculateTotal`, `findById`, `processOrder`
- **Verbs**: Methods perform actions
- **Boolean getters**: `isActive()`, `hasPermission()`, `canAccess()`
- **JavaBeans**: `getProperty()`, `setProperty()` for accessor methods


#### Variables and Fields
- **camelCase**: `firstName`, `totalAmount`, `orderList`
- **Descriptive**: Full words, avoid abbreviations
- **Constants**: `UPPER_SNAKE_CASE` with `static final`
- **No single letters**: Except loop counters (`i`, `j`, `k`)

### Code Formatting (MANDATORY)
- **Prefer modern loops**: Prefer "foreach" style loops over iterator and variable "for (var i =" style loops.
- **Follow Eclipse formatting**: Prefer Eclipse standard formatting rules

#### Indentation and Braces
- **4 spaces per level** (never tabs)
- **Opening brace on same line**: `if (condition) {`
- **Closing brace on new line**: Aligned with keyword
- **Always use braces**: Even for single-line blocks

#### Line Length and Wrapping
- **Maximum 180 characters** per line
- **Break at logical points**: After comma, before operator
- **Indent continuations**: 8 spaces or two levels

#### Whitespace
- **After keywords**: `if (`, `for (`, `while (`, `catch (`
- **Around operators**: `a + b`, `x == y`
- **After commas**: `method(a, b, c)`
- **Blank lines**: Between methods, logical sections

### Type System and Generics

#### Use Generics (MANDATORY)
- **Type-safe collections**: `List<String>` not raw `List`
- **Avoid raw types**: Always parameterize generic types
- **Bounded wildcards**: Use `? extends T` or `? super T` appropriately

**Noncompliant:**
```java
List items = new ArrayList();  // Raw type
```

**Compliant:**
```java
List<String> items = new ArrayList<>();  // Type-safe
```

#### Diamond Operator (Java 7+)
```java
Map<String, List<Integer>> map = new HashMap<>();  // Use <>
```

### Object-Oriented Design (CRITICAL)

#### SOLID Principles
1. **Single Responsibility**: One class, one reason to change
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Subtypes must be substitutable for base types
4. **Interface Segregation**: Many specific interfaces over one general
5. **Dependency Inversion**: Depend on abstractions, not concretions

#### Encapsulation (MANDATORY)
- **Private fields**: Always make instance variables private
- **Public interface**: Expose only necessary methods
- **Defensive copies**: Return copies of mutable internal state
- **Immutability**: Prefer immutable objects

```java
public class Account {
    private double balance;  // Private
    
    public double getBalance() {  // Controlled access
        return balance;
    }
    
    protected void setBalance(double balance) {  // Protected modification
        if (balance >= 0) {
            this.balance = balance;
        }
    }
}
```

#### Favor Composition Over Inheritance
- **Composition**: More flexible, easier to test
- **Inheritance**: Only for true "is-a" relationships
- **Interface-based design**: Program to interfaces

### Method Design (MAJOR)

#### Keep Methods Small
- **Maximum 20-30 lines**: One level of abstraction
- **Single purpose**: Do one thing well
- **Descriptive names**: Name reveals intent

#### Parameters and Return Values
- **Maximum 3-4 parameters**: Use parameter objects for more
- **Return values over out parameters**: More functional style
- **Use Optional<T>**: For potentially absent values (Java 8+)
- **Never return null**: Use `Optional.empty()` or empty collections

```java
// Good: Returns Optional
public Optional<Customer> findById(Long id) {
    // Returns Optional.empty() if not found
}

// Good: Returns empty collection, never null
public List<Order> findOrdersByCustomer(Long customerId) {
    List<Order> orders = repository.find(customerId);
    return orders != null ? orders : Collections.emptyList();
}
```

### Exception Handling (CRITICAL)

#### Prefer Checked Exceptions
- **RuntimeException**: For programming errors
- **Checked exceptions**: Only for recoverable conditions
- **Don't catch and ignore**: Always log or rethrow

#### Try-With-Resources (Java 7+)
```java
try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
    return reader.readLine();
}  // Automatically closes reader
```

#### Exception Best Practices
- **Catch specific exceptions**: Not `Exception` or `Throwable`
- **Preserve stack traces**: Include cause in new exceptions
- **Meaningful messages**: Explain what went wrong
- **Avoid decorator words**: Don't unnecessarily add prefixes and formatting like "error", "warning", "info".
- **Include important context data**: Include important context data to allow caller to understand root cause
- **Preserve inner exception**: When wrapping exceptions, always preserve inner exception
- **Log at boundary**: Log exceptions once, at appropriate level

```java
try {
    processData();
} catch (IOException e) {
    logger.error("Failed to process data file", e);
    throw new DataProcessingException("Failed to process data", e);
}
```

### Collections and Streams (Java 8+)

#### Use Appropriate Collections
- **ArrayList**: Default list implementation
- **LinkedList**: When frequent insertions/deletions at ends
- **HashSet**: Unique elements, no order
- **LinkedHashSet**: Unique elements, insertion order
- **TreeSet**: Sorted unique elements
- **HashMap**: Default map implementation
- **ConcurrentHashMap**: Thread-safe map

#### Stream API
- **Prefer streams**: For collection processing (Java 8+)
- **Immutable operations**: Streams don't modify source
- **Lazy evaluation**: Operations deferred until terminal operation

```java
List<String> activeCustomers = customers.stream()
    .filter(Customer::isActive)
    .map(Customer::getName)
    .collect(Collectors.toList());
```

### Concurrency (CRITICAL)

#### Thread Safety
- **Document thread safety**: In class Javadoc
- **Immutable by default**: Thread-safe automatically
- **Use java.util.concurrent**: Over manual synchronization
- **Avoid shared mutable state**: Biggest concurrency challenge

#### Concurrency Utilities
- **Executors**: For thread pools
- **ConcurrentHashMap**: Thread-safe map
- **AtomicInteger/Long**: For counters
- **CountDownLatch/CyclicBarrier**: For coordination
- **CompletableFuture**: For async programming (Java 8+)

```java
// Good: Use Atomic types for thread-safe counters
private final AtomicInteger counter = new AtomicInteger(0);

public void increment() {
    counter.incrementAndGet();
}

// Good: Use CompletableFuture for async
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> fetchData())
    .thenApply(data -> processData(data))
    .exceptionally(ex -> handleError(ex));
```

### Functional Programming (Java 8+)

#### Lambda Expressions
```java
// Method reference (preferred when possible)
list.forEach(System.out::println);

// Lambda expression
list.stream()
    .filter(x -> x > 10)
    .map(x -> x * 2)
    .forEach(System.out::println);
```

#### Functional Interfaces
- Use built-in functional interfaces: `Function`, `Predicate`, `Consumer`, `Supplier`
- Create custom functional interfaces with `@FunctionalInterface`

### Resource Management

#### Always Close Resources
- **Use try-with-resources**: For AutoCloseable resources
- **Close in reverse order**: Of creation
- **Handle close exceptions**: Appropriately

#### Avoid Finalizers
- **NEVER use finalize()**: Unreliable, deprecated in Java 9
- **Use try-with-resources**: Or explicit close() methods
- **Use cleaners as last resort**: If try-with-resources pattern is inappropriate, rely on Cleaner, never finalize()

### Performance Considerations

#### String Operations
- **StringBuilder**: For concatenation in loops
- **String.format()**: For readability with few concatenations
- **Immutable strings**: Cache when possible
- **Avoid StringBuffer**: Avoid StringBuffer unless absolutely necessary for thread safety. Consider API redesign if StringBuffer seems appropriate.

#### Collection Sizing
- **Initial capacity**: When size known
- **ArrayList over LinkedList**: For most use cases
- **Use isEmpty()**: Not `size() == 0`

#### Lazy Initialization
```java
public class Singleton {
    private static class Holder {
        private static final Singleton INSTANCE = new Singleton();
    }
    
    public static Singleton getInstance() {
        return Holder.INSTANCE;  // Thread-safe, lazy
    }
}
```

### Security Best Practices (CRITICAL)

#### Input Validation
- **Validate all input**: Never trust user data
- **Whitelist validation**: Define what's acceptable
- **Parameterized queries**: Prevent SQL injection
- **Sanitize output**: Prevent XSS

#### Sensitive Data
- **Don't log passwords**: Or other sensitive data
- **Use char[]**: For passwords, not String
- **Clear sensitive data**: After use
- **Encrypt at rest**: Use standard libraries
- **Don't have default password values**: Variables used as passwords should only ever be initialized to null.

#### Dependencies
- **Keep updated**: Patch security vulnerabilities

### Documentation (MANDATORY)

#### Javadoc
- **Public API**: Document all public classes and methods
- **Purpose and usage**: Explain what and why, not how
- **Parameters and returns**: Use @param, @return, @throws
- **Examples**: For complex methods

```java
/**
 * Calculates the total amount for an order including tax and shipping.
 * 
 * @param order the order to calculate total for, must not be null
 * @param taxRate the tax rate to apply (0.0 to 1.0)
 * @return the total amount including tax and shipping
 * @throws IllegalArgumentException if order is null or taxRate is invalid
 */
public BigDecimal calculateTotal(Order order, double taxRate) {
    // Implementation
}
```

#### Code Comments
- **Explain why, not what**: The "how" should be understood by reading the code
- **Keep updated**: Or remove outdated comments
- **TODO/FIXME**: Track technical debt
- **No commented code**: Use source control
- **Keep copyrights up to date**: Update copyright header comments with current year of when changes are made

### Testing Standards (MANDATORY)

#### Unit Testing with JUnit
- **Test all public methods**: Comprehensive coverage
- **Arrange-Act-Assert**: Clear test structure
- **Descriptive names**: `methodName_condition_expectedResult`
- **One concept per test**: Focused assertions

```java
@Test
public void calculateTotal_withValidItems_returnsSum() {
    // Arrange
    Order order = new Order();
    order.addItem(new Item(10.0));
    order.addItem(new Item(20.0));
    
    // Act
    double total = orderService.calculateTotal(order);
    
    // Assert
    assertEquals(30.0, total, 0.01);
}
```

#### Test Organization
- **Parallel structure**: Tests mirror main code structure
- **Test classes**: Match production class name with `Test` suffix
- **@Before/@After**: Setup and teardown
- **@BeforeClass/@AfterClass**: One-time setup

#### Mocking
- **Use Mockito**: For mocking dependencies
- **Mock external systems**: Databases, APIs, file systems
- **Verify interactions**: When behavior matters
- **Avoid over-mocking**: Test real objects when simple

```java
@Test
public void processOrder_callsPaymentService() {
    // Arrange
    PaymentService mockPayment = mock(PaymentService.class);
    when(mockPayment.charge(any())).thenReturn(true);
    OrderService service = new OrderService(mockPayment);
    
    // Act
    service.processOrder(order);
    
    // Assert
    verify(mockPayment).charge(order.getTotal());
}
```

### Project Structure

#### Maven/Gradle Standard Layout
```
src/
├── main/
│   ├── java/
│   │   └── com/company/project/
│   │       ├── controller/
│   │       ├── service/
│   │       ├── repository/
│   │       └── model/
│   └── resources/
│       └── application.properties
└── test/
    ├── java/
    │   └── com/company/project/
    │       ├── controller/
    │       ├── service/
    │       └── repository/
    └── resources/
```

#### Package Organization
- **By feature**: Preferred for larger projects
- **By layer**: For smaller projects
- **Domain-driven**: Group by business domain

### Build and Dependencies

#### Maven Example
```xml
<properties>
    <java.version>11</java.version>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
</properties>

<dependencies>
    <!-- Keep minimal and up-to-date -->
</dependencies>
```

#### Gradle Example
```groovy
java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

dependencies {
    // Keep minimal and up-to-date
}
```

### Logging

#### Use SLF4J
Prefer SLF4j over log4j when selecting logging framework

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MyClass {
    private static final Logger logger = LoggerFactory.getLogger(MyClass.class);
    
    public void method() {
        logger.info("Processing started");
        logger.debug("Debug details: {}", details);
        logger.error("Error occurred", exception);
    }
}
```

#### Logging Levels
- **ERROR**: Errors requiring attention
- **WARN**: Warnings, degraded functionality
- **INFO**: Important business events
- **DEBUG**: Detailed diagnostic information
- **TRACE**: Very detailed diagnostic information

---

## Modern Java Features (Java 8+)

### Optional
```java
Optional<Customer> customer = findById(id);
customer.ifPresent(c -> sendEmail(c));
String name = customer.map(Customer::getName).orElse("Unknown");
```

### Stream API
```java
List<String> names = customers.stream()
    .filter(Customer::isActive)
    .map(Customer::getName)
    .sorted()
    .collect(Collectors.toList());
```

### CompletableFuture
```java
CompletableFuture<String> future = CompletableFuture
    .supplyAsync(() -> fetchData())
    .thenApply(this::transform)
    .thenAccept(this::process);
```

### Local Variable Type Inference (Java 10+)
```java
var list = new ArrayList<String>();  // Type inferred
var customer = findCustomer(id);     // Use judiciously
```

---

## Sonarqube Compliance (MANDATORY)

### Code Quality Rules
- **Cognitive complexity**: Maximum 15 per method
- **No code duplication**: Extract to methods
- **Fix all blockers/critical**: Before merge
- **Method length**: Maximum 20-30 lines
- **Parameter count**: Maximum 3-4 parameters

### Security Rules
- **No hardcoded credentials**: Use configuration
- **SQL injection prevention**: Strictly use parameterized queries. No string concentation of paramaters
- **No sensitive data in logs**: Filter sensitive information
- **Strong cryptography**: Use standard libraries

---

## Summary

Key principles for Java development:

✅ **Naming**: PascalCase classes, camelCase methods, descriptive names
✅ **Formatting**: 4 spaces, braces on same line, max 120 chars
✅ **OOP**: Encapsulation, SOLID principles, composition over inheritance
✅ **Methods**: Small (20-30 lines), max 3-4 params, use Optional
✅ **Exceptions**: Specific catches, try-with-resources, never ignore
✅ **Collections**: Generics, Stream API, appropriate data structures
✅ **Concurrency**: Document thread safety, use java.util.concurrent
✅ **Modern Java**: Lambdas, streams, Optional, CompletableFuture
✅ **Testing**: JUnit, Mockito, comprehensive coverage, Arrange-Act-Assert
✅ **Security**: Validate input, protect sensitive data, parameterized queries
✅ **Clean Code**: Meaningful names, small methods, DRY, explain why not what

Use code quality tools to validate code quality and security. Follow "Clean Code: A Handbook of Agile Software Craftsmanship" by Robert C. Martin. Refer to [code-review-JAVA-standards.md](code-review-JAVA-standards.md) for comprehensive mandatory standards.
