# Microservices Patterns - module + module-client + module-client-starer

Building microservices in Spring Boot, you can use this pattern for cleaner isolation.

This helps achieve domain isolation by decoupling modules between one another and allowing other services to cleanly plug into one another.

## 1. Module (Implementation)

The module is the implementation that contains the core business logic, the persistence, service and web/controller layers, as well as internal DTOs.

It serves as a single source of truth for a specific domain `order-service`.

It should not be imported by other services directly.
Direct imports create tight coupling, where a change in internal logic breaks downstream consumers.

The module also has the responsibility to map internal entities to Module-Client DTOs.
The mapping logic lives in the Module's Controller or a dedicated Mapper Layer.

The module depends as well on the module-client because it defines the contract of the service.
It must implement the interface declared in the `module-client` to ensure that if the interface changes, the implementation fails to compile until you fix it.

## 2. Module-Client (API Contract)

This contains code that acts as a contract for the `module` you have to implement.
It acts as library code to access `module` service without actually importing it.

It is focused on providing `Feign` clients or `RestClient` definitions.

It contains publicly-facing DTOs, Request/Response POJOs

Its role is to provide a compile-time cotnract.
If the `module` updates an API field, the Client is updated, and consumers catch the breaking change at compile time rather than runtime.

The module should have minimal dependencies, typically `spring-cloud-openfeign-core` or `jackson`.

## 3. Module-Client-Starter (Auto-Configuration)

The `module-client-starter` is a bootstrap module that uses [[Auto-Configuration]] to create the configuration for another consumer to interact with the service.
It follows Spring Boot "Starter" convention to provide a "plug-and-play" capability.

It contains the Auto-Configuration, conditional beans and configuration properties.
Also it has an "imports file" `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` used because otherwise spring does not detect the autoconfiguration classes when the JAR is imported by another service.

Its role is to abstract the boilerplate.
A consumer simply adds the starter as a dependency and the client beans are automatically injected into the context.

## Artifacts Produced

The module produces a fat JAR, an executable JAR that represents a process.

The Client and Starter are usually passive assets stored in an artifact repository to be consumed.
Those produce thin JARs and act mostly as libraries.

## Pitfalls

## 1. Implementation Leakage

Never put domain entities anywhere other than `module`.
This leaks the database and the implementation to the consumer, which violates the primary goal of the pattern - decoupling.

## 2. Dependency Confusion

`module` depends on `module-client`.
`module-client-starter` depends on `module-client`

The consuming service depends on `module-client-starter`.
The `module-client` should not depend on anything other than simple libraries for specifying the API interface.
