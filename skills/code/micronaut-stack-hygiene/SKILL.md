---
name: micronaut-stack-hygiene
description: Enforce Micronaut-correct annotations, imports, and bean patterns when writing or modifying Java code in a Micronaut project. Use this skill whenever the user is implementing, refactoring, or reviewing Java code in a project that declares Micronaut on the classpath (io.micronaut.* in pom.xml or build.gradle), even when the user does not mention Micronaut explicitly. Especially load when annotations like @Singleton, @Inject, @Factory, @ConfigurationProperties, @Value, @MicronautTest, @Property, @Bean, @Replaces, or @Primary appear in code under discussion, or when the user mentions beans, dependency injection, configuration classes, factories, or test property overrides.
---

# Micronaut Stack Hygiene

A skill for keeping Java code in a Micronaut project free of Spring-isms and aligned with idiomatic Micronaut patterns. The cost of getting this wrong is that the code often compiles — Spring annotations on the classpath happily coexist with Micronaut ones — but behaves incorrectly at runtime, in ways that are hard to diagnose.

## Minimum protocol

**On load.** For every Java file in scope, scan imports for any `org.springframework.*` and for the banned annotations in §2. Cite the full FQN at first use of any annotation from the §1 map.

**Stop on.** Existing Spring-isms in the file (`@Autowired`, `@Component`, `@Service`, `@SpringBootTest`, etc.) — that is drift, do not silently rewrite; report per `incremental-implementation-workflow` §12. Project `CLAUDE.md` §Code Style that contradicts this skill — CLAUDE.md wins.

**Expected output shape.** Code with explicit Micronaut FQN imports, no Spring imports, constructor injection preferred over field injection. When ambiguous (`@Value`, `@Primary`, `@Property`), the resolved FQN is named in the surrounding text or a one-line comment.

## When this skill applies

Active in any Java project where `io.micronaut.*` appears as a dependency. The framework is compile-time DI (AOT bean wiring, no runtime reflection), which makes the failure modes different from Spring: Spring annotations on a Micronaut class are silently ignored, not flagged at compile time.

Common triggers: writing a new `@Singleton`, refactoring a configuration class, adding a test, replacing a bean for testing, working with `@ConfigurationProperties`, or wiring up a factory method.

## 1. The Spring-Micronaut annotation map

These annotations share names across frameworks but live in different packages with different semantics. When using any of them, always cite the full import path explicitly.

| Concept | Micronaut (correct) | Spring (do NOT use in Micronaut code) |
|---|---|---|
| Singleton bean | `jakarta.inject.Singleton` | `org.springframework.stereotype.Component` |
| Constructor/field injection | `jakarta.inject.Inject` | `org.springframework.beans.factory.annotation.Autowired` |
| Configuration class with factory methods | `io.micronaut.context.annotation.Factory` | `org.springframework.context.annotation.Configuration` + `@Bean` |
| Factory method inside `@Factory` | `io.micronaut.context.annotation.Bean` | `org.springframework.context.annotation.Bean` |
| Externalized config binding | `io.micronaut.context.annotation.ConfigurationProperties` | `org.springframework.boot.context.properties.ConfigurationProperties` (different semantics) |
| Single property injection | `io.micronaut.context.annotation.Value` | `org.springframework.beans.factory.annotation.Value` (different semantics) |
| Test class annotation (JUnit 5) | `io.micronaut.test.extensions.junit5.annotation.MicronautTest` | `org.springframework.boot.test.context.SpringBootTest` |
| Test class annotation (Spock) | `io.micronaut.test.extensions.spock.annotation.MicronautTest` | — |
| Test property override | `io.micronaut.context.annotation.Property` | `org.springframework.test.context.TestPropertySource` |
| Bean replacement for tests | `io.micronaut.context.annotation.Replaces` (on a `@Bean` method, typically in a test class) | `@MockBean` (Spring Boot Test) |
| Primary bean among candidates | `io.micronaut.context.annotation.Primary` | `org.springframework.context.annotation.Primary` (same name, different runtime) |
| Bean validation constraints | `jakarta.validation.constraints.*` | `jakarta.validation.constraints.*` (same package; the surrounding stack differs) |

When in doubt about a package path, write the full FQN as a comment next to the import. Compile-time DI in Micronaut means the wrong import is often a silent no-op, not a build error.

## 2. Banned Spring patterns

These must never appear in a Micronaut codebase. Most compile if Spring is transitively on the classpath but cause runtime breakage or — worse — silent misbehavior.

- `@SpringBootApplication`
- `@RestController`, `@Controller` from Spring Web (Micronaut uses `io.micronaut.http.annotation.Controller`)
- `@Service`, `@Repository`, `@Component` (use `@Singleton`)
- `@Autowired` (use `@Inject` or, preferably, constructor injection)
- `@TestPropertySource` (use `@Property` or `@MicronautTest(propertySources = …)`)
- Spring's `@Value` and `@ConfigurationProperties` (different package, different binding)
- `@MockBean` from Spring Boot Test (use `@Bean` + `@Replaces` in the test class)
- `@SpringBootTest` (use `@MicronautTest`)
- Spring `@Transactional` from `org.springframework.transaction.annotation` (Micronaut provides its own transactional support via `io.micronaut.transaction.annotation.Transactional`)

If you find any of these in existing code, treat it as drift (see the workflow skill, §12). Do not silently rewrite; report and ask.

## 3. Positive Micronaut idioms

### Bean declaration

- Default scope is singleton via `@Singleton`. Multi-instance scope is explicit: `@Prototype`, `@RequestScope`, etc.
- Prefer **constructor injection over field injection**. Combined with `record` or `final` fields, this gives you immutability and testability without extra annotations.
- Avoid `@Inject` on fields unless interoperating with a framework that requires it (rare).

### Factory methods

Use `@Factory` for a class whose methods produce beans of types you don't own (third-party clients, SDK clients, etc.):

| Element | Annotation | Where |
|---|---|---|
| Factory class | `@Factory` (`io.micronaut.context.annotation.Factory`) | On the class |
| Producing method | `@Singleton` or `@Bean` (`io.micronaut.context.annotation.Bean`) | On the method |
| Conditional bean | `@Requires(...)` | On the method or class |

Do not use `@Configuration` from Spring — it is silently ignored by Micronaut's compile-time processor.

### Externalized configuration

- Bind YAML / properties / env to a `@ConfigurationProperties` class.
- Prefer **`record`** types for `@ConfigurationProperties` when the config is immutable (a getter-style record works in Micronaut 4+). When binding requires setters (rare), use a mutable class with explicit setters.
- Add `jakarta.validation.constraints.*` annotations on fields/parameters; combined with `@Validated` on the config bean (or globally), Micronaut validates at context init.
- Config binding failure should fail the context startup. Do not catch `BeanInstantiationException` to "recover" from a malformed config.

### Test property overrides

For a one-off override on a single test method:

```
@Test
@Property(name = "app.feature.enabled", value = "true")
void featureWorksWhenEnabled() { ... }
```

For a file-based override across an entire test class:

```
@MicronautTest(propertySources = "classpath:test-config.yml")
class MyServiceTest { ... }
```

`@Property` from `io.micronaut.context.annotation.Property` works on class level and method level. When applied at method level on `@ConfigurationProperties`-bound beans, it triggers a `RefreshEvent` that updates the bound configuration; this works in Micronaut 4+ without additional setup. Verify behavior if your bean has complex re-binding requirements.

### Bean replacement in tests

For replacing a real bean with a test double, declare a `@Bean` method in the test class annotated with `@Replaces(TargetType.class)`. This is the Micronaut equivalent of `@MockBean`:

```
@MicronautTest
class VehicleTest {
    @Bean
    @Replaces(EngineClient.class)
    EngineClient mockEngine() { return Mockito.mock(EngineClient.class); }

    @Inject Vehicle vehicle;
}
```

This avoids the need for runtime proxies. Do not look for `@MockBean` — Micronaut does not have it.

### Bean selection among candidates

When multiple beans implement an interface, mark the default with `@Primary` (`io.micronaut.context.annotation.Primary`). For named selection, use `@Named("...")` (`jakarta.inject.Named`) on both the producer and the injection point.

### Conditional beans

Use `@Requires(...)` (`io.micronaut.context.annotation.Requires`) for conditional bean wiring (env-specific, property-driven, classpath-based). Do not invent runtime `if`-based bean selection in factories; let `@Requires` handle it at compile time.

## 4. Anti-patterns to avoid

- **Mixing Spring and Micronaut annotations on the same class.** Compiles, but Micronaut's processor only sees its own. The Spring annotations become dead metadata that future readers will believe are active.
- **Using `@Autowired` "because it works".** It may or may not work depending on classpath; even when it works, it signals the author was thinking Spring. Use `@Inject` or constructor injection.
- **Calling `Micronaut.run(...)` in non-main contexts.** Only the application entry point should bootstrap the context. Inside Lambda handlers, the bootstrap pattern is different (see Lambda companion skills).
- **`@Value` on a field that needs validation.** Use `@ConfigurationProperties` with `jakarta.validation` constraints instead. `@Value` is for simple cases.
- **Reflection-based bean discovery.** Micronaut is AOT — if a bean isn't compile-time discoverable, it doesn't exist. Annotations not processed at compile time are invisible at runtime. This is the opposite of Spring's default.
- **Assuming open classes / proxies.** Micronaut doesn't proxy by default; subclassing for AOP requires explicit `@Around`-style advice. Pattern matching from Spring (final classes blocking proxies) doesn't translate.

## 5. Verification habit

When citing any annotation from the table in §1 or referencing a Micronaut feature, write the full FQN at first use within a file. Example: instead of `@Singleton`, write `jakarta.inject.Singleton` in the import block and ensure no `org.springframework.*` import sneaks in.

If a code section uses an annotation whose package is ambiguous from context (e.g. `@Value`, `@Primary`, `@Property`), grep the imports before committing:

- `grep -rn "import org.springframework" src/` should return zero results.
- `grep -rn "@Autowired\|@Component\|@Service\|@Repository" src/` should return zero results.

These checks fit naturally into a pre-commit hook or a CI lint step.

## Composability with other skills

This skill defines hygiene and idioms only. It does not cover:

- Build tooling (Maven, Gradle, shade plugin) — see Java/JVM build skills.
- Lambda packaging (fat jar, SnapStart, JVM cold start) — see Lambda companion skills.
- AWS integration patterns (SDK v2 clients, IAM) — see AWS companion skills.
- The implementation workflow itself (BDD, prereq → red → green, classification of failures) — see the `incremental-implementation-workflow` skill.

When this skill conflicts with project-level conventions in CLAUDE.md, CLAUDE.md wins. Defer to the project's ADR and Code Style sections; this skill is a fallback for projects whose CLAUDE.md does not fix these choices.
