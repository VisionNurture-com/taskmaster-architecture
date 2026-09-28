plugins {
    id("org.springframework.boot")
}

dependencies {
    implementation(project(":application"))
    runtimeOnly(project(":infrastructure"))

    implementation("org.springframework.boot:spring-boot-starter-webmvc")
    developmentOnly("org.springframework.boot:spring-boot-docker-compose")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.boot:spring-boot-starter-webmvc-test")
    testImplementation("org.springframework.boot:spring-boot-testcontainers")
    testImplementation("org.testcontainers:testcontainers-junit-jupiter")
    testImplementation("org.testcontainers:testcontainers-postgresql")
    testImplementation("com.tngtech.archunit:archunit-junit5-engine:1.5.1")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
