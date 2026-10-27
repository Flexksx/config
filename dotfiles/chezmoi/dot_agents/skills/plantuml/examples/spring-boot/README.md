# Spring Boot Application to PlantUML Diagrams

This directory contains examples of converting Spring Boot application code into various PlantUML diagrams.

## Overview

Common Spring Boot patterns and their corresponding PlantUML representations:

- **Deployment Diagram**: Shows how Spring Boot apps deploy to cloud infrastructure
- **Component Diagram**: Illustrates the internal architecture with controllers, services, repositories
- **Sequence Diagram**: Documents REST API request flows and authentication
- **Class Diagram**: Maps domain models, DTOs, and entity relationships

## Unicode Symbols for Spring Boot

Use these semantic symbols in your diagrams:

- `🌱` - Spring framework components
- `⚙️` - Configuration/Properties
- `🔒` - Security (Spring Security)
- `📦` - Repository/Data layer
- `🎯` - Controller/REST endpoint
- `💼` - Service layer
- `🔌` - External API integration
- `💾` - Database connection
- `🔑` - Authentication token
- `⚡` - Async processing
- `📊` - Metrics/Actuator

## Example Application Structure

```text
src/main/java/com/example/app/
├── controller/
│   └── UserController.java
├── service/
│   └── UserService.java
├── repository/
│   └── UserRepository.java
├── model/
│   └── User.java
├── dto/
│   └── UserDTO.java
├── config/
│   └── SecurityConfig.java
└── Application.java
```

See the example files in this directory for diagram mappings.
