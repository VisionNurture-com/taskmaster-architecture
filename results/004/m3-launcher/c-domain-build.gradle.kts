// ドメイン層: Spring依存なし、純粋Java
dependencies {
    testImplementation("org.assertj:assertj-core")
}

testing {
    suites {
        named<JvmTestSuite>("test") {
            useJUnitJupiter()
        }
    }
}
