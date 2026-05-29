---
name: jvm-fatjar-deploy-verification
description: Verify that a Java fat/uber jar produced by Maven Shade Plugin is structurally sound before deploying it to AWS Lambda, container scratch images, or any environment where the artifact runs without your local classpath. Use this skill whenever you build a fat jar for deployment, configure or troubleshoot maven-shade-plugin, or face runtime errors like NoClassDefFoundError, "Property doesn't exist", PropertySourceLoader not found, or other "works in IDE but fails when deployed" symptoms. Especially load when you see suspiciously small thin jars under 10 MB for a typical Spring or Micronaut app, missing application.yml at runtime, or META-INF/services entries lost after shading.
---

# JVM Fat Jar Deploy Verification

A skill for catching the four cascading failure modes that turn a fat jar build into "compiles green, deploys broken". Each failure on its own is recoverable in minutes; cascading they cost hours, because each symptom masks the next.

## When this skill applies

Active in any Java project that produces a fat/uber jar via Maven Shade Plugin for deployment to:
- AWS Lambda (JVM runtime with SnapStart or cold start)
- Container scratch / distroless images
- Any environment that runs the jar directly with `java -jar <artifact>` and no pre-built classpath

The skill assumes Maven. Gradle equivalents exist (`shadowJar` plugin); the principles transfer but the configuration syntax does not.

## Prerequisites

Tools assumed available in the shell:
- `mvn`
- `unzip` (or `jar` from the JDK)
- `bash`, `grep`, `wc`, `stat`
- `java` (for boot verification)

All standard on any Linux/macOS dev machine and any CI runner.

## The four cascading failure modes

These were observed in production and documented in a real session diary. Each fails in a different runtime symptom, which is what makes them so expensive: you fix one, hit the next, think it's an unrelated bug, repeat.

| # | Failure | Symptom at runtime | Root cause |
|---|---|---|---|
| 1 | Thin jar deployed instead of fat | `NoClassDefFoundError` on any non-JDK class | CI pipeline picks up `target/*.jar` (the original module jar) before or instead of the shaded one |
| 2 | Fat jar missing `application.yml` | `Property doesn't exist` on bean wiring | Maven Shade resource filtering excluded YAML files from the root |
| 3 | `META-INF/services` overwritten | `NoSuchProviderException`, "no PropertySourceLoader registered", Jackson modules missing | Shade plugin without `ServicesResourceTransformer` keeps only the last service file for each interface |
| 4 | Required runtime dependency missing | `ClassNotFoundException` on a specific class (e.g. SnakeYAML) | Dependency declared transitively, excluded somewhere up the tree, never made it into the shaded jar |

## Verification: what to add to the build

After `mvn package`, run a verification script that asserts the four properties. The script lives in the repo (typically `scripts/verify-fatjar.sh`) and is invoked either as a Maven `exec-maven-plugin` step or as a separate CI job after build.

### Check 1: shaded jar exists at the expected name

The shaded jar typically has a suffix like `-shaded`, `-all`, or `-uber`. If the build silently produced only the original (thin) jar, the wrong artifact gets deployed. Assert by name pattern, not by globbing all `*.jar`.

```bash
SHADED_JAR=$(find target -maxdepth 1 -name "*-shaded.jar" -type f | head -n 1)
if [ -z "$SHADED_JAR" ]; then
  echo "FAIL: no shaded jar found in target/" >&2
  exit 1
fi
```

If your shade configuration uses `<finalName>` to replace the original artifact, adjust the pattern accordingly. Whatever it is, the check must assert the exact expected name, not "any jar will do".

### Check 2: size threshold

A correctly shaded jar containing a Micronaut or Spring Boot application plus its dependencies is at least 10 MB, typically 20–50 MB. A 300–500 KB jar is a thin jar. The size check is cheap and catches failure #1 immediately.

```bash
MIN_SIZE_BYTES=10000000  # 10 MB; tune for the project
SIZE=$(stat -c%s "$SHADED_JAR" 2>/dev/null || stat -f%z "$SHADED_JAR")
if [ "$SIZE" -lt "$MIN_SIZE_BYTES" ]; then
  echo "FAIL: shaded jar size $SIZE bytes is below threshold $MIN_SIZE_BYTES" >&2
  exit 1
fi
```

The `stat -c%s` form is GNU coreutils; `stat -f%z` is BSD (macOS). The fallback above handles both.

### Check 3: critical resources at classpath root

If the application reads `application.yml` (or `application.properties`, or another resource expected at the classpath root), assert it survived the shade. Without this check, failure #2 only manifests at the first bean wiring.

```bash
if ! unzip -p "$SHADED_JAR" application.yml > /dev/null 2>&1; then
  echo "FAIL: application.yml missing at classpath root of $SHADED_JAR" >&2
  exit 1
fi
```

Extend with every resource the application reads at root. Common candidates: `application.yml`, `bootstrap.yml`, `logback.xml`, `META-INF/native-image/`.

### Check 4: service files merged correctly

This catches failure #3. Pick the service interface most critical to your framework's bootstrapping. For Micronaut: `io.micronaut.context.env.PropertySourceLoader`. For Jackson modules: `com.fasterxml.jackson.databind.Module`. For JDBC drivers: `java.sql.Driver`.

```bash
SERVICE_FILE="META-INF/services/io.micronaut.context.env.PropertySourceLoader"
SERVICES_CONTENT=$(unzip -p "$SHADED_JAR" "$SERVICE_FILE" 2>/dev/null || true)
if [ -z "$SERVICES_CONTENT" ]; then
  echo "FAIL: $SERVICE_FILE empty or missing in $SHADED_JAR" >&2
  exit 1
fi
# Optionally assert specific implementations are listed
echo "$SERVICES_CONTENT" | grep -q "YamlPropertySourceLoader" || {
  echo "FAIL: YamlPropertySourceLoader not registered in $SERVICE_FILE" >&2
  exit 1
}
```

Pick service files whose absence would cripple the application. One or two is enough; this is a sanity check, not exhaustive coverage.

### Check 5: boot verification

The strongest check: actually launch the jar in a clean JVM and verify it initializes without `NoClassDefFoundError`, `ClassNotFoundException`, or property resolution errors. This catches failure #4 (missing transitive dependency) which the static structural checks cannot.

```bash
# Run with a short timeout; the goal is "does it start up", not "does it run forever"
LOG=$(timeout 30s java -jar "$SHADED_JAR" 2>&1 || true)
if echo "$LOG" | grep -qE "NoClassDefFoundError|ClassNotFoundException|Property doesn't exist"; then
  echo "FAIL: boot verification produced classpath/property errors" >&2
  echo "$LOG" | grep -E "NoClassDefFoundError|ClassNotFoundException|Property doesn't exist" | head -5 >&2
  exit 1
fi
```

For a Lambda entry point that requires an event, run it with a no-op handler invocation or with a flag that exits after context initialization. If the application has no quick-exit mode, add a `--validate-only` flag (or equivalent) that initializes the framework context and returns.

## Maven Shade configuration: required minimum

To prevent failure #3 in the first place, the Shade configuration must include `ServicesResourceTransformer`. Without it, every `META-INF/services/X` from later JARs silently overwrites earlier ones, leaving only the last one in the merged artifact.

The minimum required transformer block, for Maven Shade Plugin 3.6.x:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
  <version>3.6.2</version>
  <executions>
    <execution>
      <phase>package</phase>
      <goals><goal>shade</goal></goals>
      <configuration>
        <shadedArtifactAttached>true</shadedArtifactAttached>
        <shadedClassifierName>shaded</shadedClassifierName>
        <transformers>
          <transformer implementation="org.apache.maven.plugins.shade.resource.ServicesResourceTransformer"/>
          <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
            <manifestEntries>
              <Main-Class>YOUR.MAIN.CLASS</Main-Class>
            </manifestEntries>
          </transformer>
        </transformers>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Key configuration points:

- `ServicesResourceTransformer` is non-negotiable. Without it, failure #3 is guaranteed for any non-trivial framework.
- `<shadedArtifactAttached>true</shadedArtifactAttached>` with `<shadedClassifierName>shaded</shadedClassifierName>` produces `your-artifact-shaded.jar` alongside the original. The CI pipeline must reference the shaded one by name; the check in §1 above enforces this.
- If you use AOP, CDI, Spring, or any other framework with additional metadata files in `META-INF/`, add the corresponding transformer (`AppendingTransformer` for properties-like files, `XmlAppendingTransformer` for XML schemas, etc.). The Shade plugin documentation enumerates them.

If the project requires `application.yml` and other YAML resources at the classpath root (failure #2), confirm that `<resources>` filtering in `pom.xml` does not exclude them. Maven's default resource handling keeps `src/main/resources/**` content; check that no `<excludes>` rule strips YAML.

## Wiring the verification into the build

Two acceptable patterns:

1. **As a CI step after `mvn package`**: simpler, easier to debug. The script runs in CI only, not on developer machines. The downside is that a developer can produce a broken artifact locally and discover it only after pushing.

2. **As a Maven `exec-maven-plugin` step bound to the `verify` phase**: the script runs as part of every full build. Slower locally, but catches the issue before commit. Use this if the team has been bitten more than once.

For Lambda specifically, you may want to add a third check: build the deployment package (zip the jar + any Lambda Layers' content) and verify the package size is within Lambda's limits (50 MB direct upload, 250 MB unzipped including layers). This is environment-specific and lives in the Lambda-deploy companion skill rather than here.

## Anti-patterns

- **Trusting `mvn verify` alone.** Maven's built-in verification does not boot the produced jar. A green `verify` says "the modules built and unit tests passed", not "the deployable artifact works".
- **Globbing `target/*.jar` in CI.** This picks up whichever jar Maven happened to leave, which is not deterministic when shading produces multiple artifacts. Always reference by exact name pattern (e.g. `target/*-shaded.jar`).
- **Adding `mvn verify` as the deploy gate.** Combine it with the artifact verification script; `verify` alone is insufficient.
- **Writing the verification as a JUnit test.** Java test code runs against the IDE/Maven classpath, not against the produced jar. The whole point of this verification is to test the artifact as a black box. Bash is the right level.
- **Skipping `ServicesResourceTransformer` because "tests pass".** Tests run against the unshaded classpath where all `META-INF/services` files are independently visible. The failure only appears post-shade.
- **Ignoring small-jar warnings.** A 500 KB shaded jar is not a small project; it is a broken build.

## Composability with other skills

This skill verifies the artifact at build time only. It does not cover:

- AWS Lambda deploy state (alias, version, code SHA) — see AWS companion skills.
- Framework-specific bean wiring rules — see Micronaut / Spring / Quarkus companion skills.
- The implementation workflow that produced the code — see `incremental-implementation-workflow`.

If a deploy fails for a reason this skill's checks pass (e.g. IAM, region mismatch, environment variable not wired), the artifact is fine and the cause is elsewhere — escalate to the AWS deploy skill.
