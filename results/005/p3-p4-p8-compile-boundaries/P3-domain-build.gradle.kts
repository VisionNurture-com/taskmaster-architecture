// ドメイン層: Spring依存なし、純粋Java
dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter")
    testImplementation("org.assertj:assertj-core")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

dependencies {
    implementation("org.springframework:spring-context")
}
